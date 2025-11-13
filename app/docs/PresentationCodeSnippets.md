# 핵심 코드 스니펫 (발표 자료용)

이 문서는 '소리-빛 번역 AI' 앱의 핵심 기능과 로직을 담고 있는 코드 스니펫을 정리한 것입니다.

---

## 1. `SoundLabel`: 소리 데이터 정의 및 UI 매핑

`SoundLabel` 열거형(enum)은 앱이 인식할 수 있는 모든 소리 종류를 정의합니다. 각 소리 라벨은 단순히 종류를 구분하는 것을 넘어, 화면에 표시될 **색상(Color)**, **이름(displayName)**, **이미지(imageName)** 와 직접 연결됩니다. 이 구조 덕분에 새로운 소리를 추가하거나 기존 소리의 UI를 변경하는 작업이 매우 간편해집니다.

```swift
/// 앱에서 사용하는 소리 레이블을 정의하고, 각 레이블에 맞는 색상과 화면에 표시될 이름을 제공합니다.
enum SoundLabel: String, CaseIterable {
    // 23개로 라벨 확장
    case applianceDone = "가전제품_종료"
    case dog = "개"
    case doorKnock = "문_노크"
    // ... (기타 라벨)
    case fire = "안전_화재_경보"
    case silence = "정적"
    case unknown = "알 수 없음"

    /// 각 소리 레이블에 대응하는 SwiftUI 색상입니다.
    var color: Color {
        switch self {
        // 빨간색: 안전 관련
        case .fall, .fire:
            return .red
        // 주황색: 문 관련
        case .doorKnock, .doorLock, .doorBell:
            return .orange
        // ... (기타 색상 매핑)
        // 회색: 배경 또는 알 수 없음
        case .background, .silence, .unknown, .conversation:
            return .gray
        }
    }

    /// 화면에 표시될 레이블 이름입니다.
    var displayName: String {
        // ... (이름 매핑)
    }
    
    /// 각 소리 레이블에 대응하는 이미지 이름입니다. (색상 그룹 기준)
    var imageName: String {
        // ... (이미지 매핑)
    }
}
```

---

## 2. `SoundClassifier`: 실시간 소리 분석의 두뇌

`SoundClassifier` 클래스는 앱의 핵심 로직을 담당하는 `ObservableObject`입니다. 이 클래스는 다음 기능을 수행합니다.

-   **오디오 입력 처리**: `AVFoundation`을 사용하여 실시간으로 마이크 입력을 받습니다.
-   **소리 분석**: `SoundAnalysis` 프레임워크와 Core ML 모델(`Koongdeok-soundAI_4`)을 연결하여 소리를 분류합니다.
-   **상태 관리**: 분류된 소리 라벨(`currentLabel`), 신뢰도(`currentConfidence`), 녹음 상태(`isRecording`) 등 UI에 필요한 모든 상태를 `@Published` 프로퍼티로 관리하여 SwiftUI 뷰가 실시간으로 반응하도록 합니다.

```swift
/// 실시간 오디오를 분석하여 소리를 분류하는 ObservableObject 클래스입니다.
class SoundClassifier: NSObject, ObservableObject {
    
    // MARK: - Published 속성 (UI 업데이트용)
    @Published var appState: AppState = .onboarding
    @Published var currentLabel: SoundLabel = .unknown
    @Published var currentConfidence: Double = 0.0
    @Published var isRecording = false
    @Published var currentPowerLevel: Float = -160.0
    @Published var baselineDecibel: Float?
    @Published var triggerPulse: Bool = false
    
    @Published var confidenceThresholds: [String: Double] = [:] {
        didSet {
            saveThresholds()
        }
    }

    // MARK: - 오디오 및 상태 처리 관련 속성
    private var audioEngine: AVAudioEngine?
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private let analysisQueue = DispatchQueue(label: "com.example.SoundAnalysisQueue")
    private var stateResetTimer: Timer?
    
    // ... (기타 속성)
}
```

---

## 3. `loadSettings`: 사용자 맞춤형 민감도 설정

앱이 시작될 때 `loadSettings()` 함수는 `UserDefaults`에 저장된 사용자 정의 민감도(신뢰도 임계값)를 불러옵니다. 만약 저장된 설정이 없으면, 각 소리 라벨에 대한 **기본 임계값**을 설정합니다. 이 기능을 통해 각 소리 환경에 맞춰 앱의 반응성을 유연하게 조절할 수 있습니다.

```swift
private func loadSettings() {
    // 민감도 설정 로드
    if let savedThresholds = UserDefaults.standard.dictionary(forKey: confidenceThresholdsKey) as? [String: Double], !savedThresholds.isEmpty {
        self.confidenceThresholds = savedThresholds
    }
    else {
        // 민감도 기본값 설정
        self.confidenceThresholds = [
            SoundLabel.fire.rawValue: 0.70,
            SoundLabel.fall.rawValue: 0.70,
            SoundLabel.babyCry.rawValue: 0.99,
            SoundLabel.dog.rawValue: 0.75,
            // ... (기타 라벨 임계값)
        ]
    }
    
    // 기준 데시벨 로드
    if UserDefaults.standard.value(forKey: baselineDecibelKey) != nil {
        self.baselineDecibel = UserDefaults.standard.float(forKey: baselineDecibelKey)
    }
}
```

---

## 4. `start`: 소리 분석 파이프라인 구축

`start()` 함수는 소리 분석을 위한 전체 파이프라인을 설정하고 시작합니다.

1.  `AVAudioEngine`을 설정하고 마이크 입력을 받을 준비를 합니다.
2.  `SNAudioStreamAnalyzer`를 생성하여 오디오 스트림을 분석할 준비를 합니다.
3.  Core ML 모델(`Koongdeok_soundAI_4`)을 로드하여 `SNClassifySoundRequest`를 생성합니다. 이 요청(request)이 실제 소리 분류 작업을 수행합니다.
4.  분석기와 요청을 연결(`add(request, withObserver: self)`)하여, 분석 결과가 나올 때마다 `SoundClassifier`가 통지받도록 합니다.
5.  오디오 엔진을 시작하여 실시간 분석을 개시합니다.

```swift
/// 메인 소리 분석을 시작합니다.
func start() {
    guard let audioEngine = audioEngine, !audioEngine.isRunning, baselineDecibel != nil else { return }
    
    setupAudioSession()
    
    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    
    streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
    
    do {
        let config = MLModelConfiguration()
        let model = try Koongdeok_soundAI_4(configuration: config).model
        let request = try SNClassifySoundRequest(mlModel: model)
        
        try streamAnalyzer?.add(request, withObserver: self)
    } catch {
        print("소리 분류 요청 생성에 실패했습니다: \(error.localizedDescription)")
        return
    }
    
    inputNode.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { /* ... */ }
    
    do {
        try audioEngine.start()
        // ...
    } catch {
        // ...
    }
}
```

---

## 5. `request:didProduce`: 모델 예측 결과 처리 및 상태 업데이트

`SoundAnalysis` 프레임워크가 소리 분류 결과를 반환하면 이 함수가 호출됩니다. 여기가 바로 **AI의 예측을 실제 앱의 상태로 변환**하는 핵심 지점입니다.

1.  결과(`SNClassificationResult`)에서 가장 신뢰도 높은 분류(`classification`)를 가져옵니다.
2.  분류된 라벨(`identifiedLabel`)과 신뢰도(`confidence`)를 확인합니다.
3.  **미리 정의된 분류 규칙**에 따라 현재 상태를 업데이트할지 결정합니다.
    -   **규칙 A**: '중요 소리'가 설정된 임계값을 넘으면, `currentLabel`을 업데이트하고 3초 후 '정적' 상태로 돌아가는 타이머를 설정합니다.
    -   **규칙 B**: '중요하지 않은 소리'(배경소음, 대화 등)가 임계값을 넘으면, 현재 '중요 소리'가 표시되고 있지 않을 때만 화면을 회색으로 업데이트합니다.
    -   **규칙 C**: 그 외 모든 경우(신뢰도 낮은 소리)는 무시하여 화면의 불필요한 깜빡임을 방지합니다.

```swift
extension SoundClassifier: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }

        let identifiedLabel = SoundLabel.fromIdentifier(classification.identifier)
        let confidence = classification.confidence

        // 1. 소리 카테고리 정의
        let insignificantSounds: [SoundLabel] = [.background, .silence, .conversation]
        
        // 2. 신뢰도 임계값 가져오기
        let specificThreshold = self.confidenceThresholds[identifiedLabel.rawValue] ?? 0.90
        let insignificantThreshold = 0.75

        // 3. 새로운 분류 규칙 적용
        DispatchQueue.main.async {
            // 규칙 A: '중요 소리'가 임계값을 넘었는가?
            if !insignificantSounds.contains(identifiedLabel) && confidence >= specificThreshold {
                self.currentLabel = identifiedLabel
                self.currentConfidence = confidence
                self.resetStateAfterDelay() // 타이머 설정 후 '정적'으로 복귀
            }
            // 규칙 B: '중요하지 않은 소리'가 일반 임계값을 넘었는가?
            else if insignificantSounds.contains(identifiedLabel) && confidence >= insignificantThreshold {
                if self.stateResetTimer == nil || !(self.stateResetTimer?.isValid ?? false) {
                    self.currentLabel = identifiedLabel // '정적', '배경소음', '대화' 등을 회색으로 표시
                    self.currentConfidence = confidence
                }
            }
            // 규칙 C: 그 외 모든 경우 (신뢰도 낮은 소리)는 무시.
        }
    }
}
```

---

## 6. `MainAppView`: 데이터와 UI의 만남

`MainAppView`는 `SoundClassifier`가 발행(`@Published`)하는 데이터를 관찰(`@ObservedObject`)하여 UI를 그리는 SwiftUI 뷰입니다.

-   `classifier.currentLabel.color`가 변경되면, `.animation` 효과와 함께 배경색이 부드럽게 전환됩니다.
-   `classifier.currentLabel.displayName`과 `classifier.currentLabel.imageName`을 사용하여 화면 중앙의 텍스트와 이미지를 업데이트합니다.
-   `classifier.isRecording` 상태에 따라 신뢰도, 데시벨 정보, 재설정 버튼 등의 표시 여부를 결정합니다.

이처럼 **데이터와 뷰의 분리**는 SwiftUI의 핵심 원칙이며, 우리 앱은 이 원칙을 충실히 따르고 있습니다.

```swift
struct MainAppView: View {
    @ObservedObject var classifier: SoundClassifier

    var body: some View {
        ZStack {
            // 동적으로 변경되는 배경색
            classifier.currentLabel.color
                .animation(.easeInOut(duration: 0.5), value: classifier.currentLabel)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // ...

                // "쿵덕이" 캐릭터 이미지와 상태 표시
                VStack {
                    Image(classifier.currentLabel.imageName)
                        // ...
                    Text(classifier.currentLabel.displayName)
                        // ...
                }

                // 신뢰도 및 데시벨 표시
                if classifier.isRecording {
                    // ...
                }

                // ...
            }
        }
        .onReceive(classifier.$isRecording) { isRecording in
            if isRecording && !classifier.isEngineRunning {
                classifier.start()
            } else if !isRecording && classifier.isEngineRunning {
                classifier.stop()
            }
        }
    }
}
```
