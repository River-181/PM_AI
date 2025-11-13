# 핵심 코드 요약 (발표 자료용)

이 문서는 '소리-빛 번역 AI' 앱의 핵심적인 기술 구현을 설명하기 위한 코드 스니펫과 요약을 담고 있습니다. 우리 앱은 **실시간 소리 분석**을 통해 주변 환경의 소리 이벤트를 감지하고, 이를 시각적인 '빛'의 형태로 변환하여 사용자에게 전달합니다.

주요 키워드 및 기술 스택:

*   **Core ML & SoundAnalysis**: Apple의 강력한 머신러닝 프레임워크를 활용하여 학습된 AI 모델(`Koongdeok-soundAI_4`)을 기반으로 실시간 오디오 스트림을 분류합니다.
*   **AVFoundation**: 마이크 입력을 효율적으로 처리하고 오디오 데이터를 분석 파이프라인으로 전달합니다.
*   **SwiftUI & 반응형 UI**: `SoundClassifier` 클래스에서 발행(`@Published`)하는 소리 분류 결과(`currentLabel`, `currentConfidence`)에 따라 `MainAppView`의 배경색, 텍스트, 이미지 등이 즉각적으로 업데이트되는 **반응형 UI**를 구현했습니다. 이는 **데이터-UI 연결**의 모범 사례를 보여줍니다.
*   **민감도 조절**: 각 소리 라벨에 대한 **신뢰도 임계값**을 설정하고 `UserDefaults`를 통해 관리함으로써, 사용 환경에 최적화된 **민감도 조절**이 가능합니다.
*   **하드웨어 시뮬레이션**: 단순한 색상 변화를 넘어, 소리의 종류와 중요도에 따라 배경색이 동적으로 변화하고, 특정 이벤트 발생 시 시각적 피드백을 제공하는 등 실제 하드웨어의 '빛' 표현 방식을 **시뮬레이션**합니다.

아래에서는 이러한 핵심 기능들을 구현하는 데 사용된 가장 중요한 코드 스니펫 3가지를 자세히 설명합니다.

---

앱의 가장 핵심적인 코드 3가지를 꼽는다면 다음과 같습니다. 이 세 부분은 **(1) 소리 입력 및 분석 시작 → (2) AI 모델의 예측 처리 → (3) 시각적 UI 업데이트** 라는 앱의 전체 데이터 흐름을 완벽하게 보여줍니다.

---

### 1. `start()`: 실시간 소리 분석 파이프라인 구축

**설명:** 이 코드는 `AVFoundation`으로 마이크 입력을 받아 `SoundAnalysis` 프레임워크와 `Core ML` 모델을 연결하여 실시간 소리 분석을 시작하는 전체 파이프라인을 구성합니다.

**선정 이유:** 이 함수는 앱의 '엔진'을 켜는 역할을 합니다. 마이크 입력을 받아 Core ML 모델에 전달하기까지의 모든 과정을 설정하고 시작하는, 앱의 심장과도 같은 부분입니다. 이 코드가 없다면 앱은 아무것도 들을 수 없습니다.

```swift
/// 메인 소리 분석을 시작합니다.
func start() {
    // ... 오디오 엔진 및 분석기 설정 ...
    
    streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
    
    do {
        // 1. Core ML 모델 로드
        let model = try Koongdeok_soundAI_4(configuration: config).model
        // 2. 모델을 사용해 소리 분류 요청 생성
        let request = try SNClassifySoundRequest(mlModel: model)
        
        // 3. 분석 결과가 나오면 self(SoundClassifier)에게 알리도록 설정
        try streamAnalyzer?.add(request, withObserver: self)
    } catch {
        // ...
    }
    
    // ... 오디오 엔진 시작 ...
}
```

---

### 2. `request:didProduce:`: AI의 예측을 앱의 상태로 변환

**설명:** 이 코드는 `Core ML` 모델의 예측 결과를 받아, 사전에 정의된 `신뢰도 임계값`과 비교하여 앱의 현재 상태(`currentLabel`)를 업데이트할지 결정하는 핵심 AI 로직입니다.

**선정 이유:** 이 함수는 앱의 '두뇌'입니다. Core ML 모델이 "이건 '개' 소리 같아"라고 예측한 결과를 받아서, "신뢰도가 75%를 넘었으니 '개 짖는 소리'로 확정하고, 3초 뒤에 다시 대기 상태로 돌아가자" 와 같이 실제 앱의 행동을 결정하는 가장 지능적인 부분입니다.

```swift
// SoundClassifier가 SNResultsObserving 프로토콜을 따르도록 하는 확장
extension SoundClassifier: SNResultsObserving {
    // 소리 분석 결과가 나왔을 때 호출되는 함수
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }

        let identifiedLabel = SoundLabel.fromIdentifier(classification.identifier)
        let confidence = classification.confidence

        // 미리 정의된 신뢰도 임계값 가져오기
        let specificThreshold = self.confidenceThresholds[identifiedLabel.rawValue] ?? 0.90

        // 메인 스레드에서 UI 업데이트
        DispatchQueue.main.async {
            // '중요 소리'가 임계값을 넘었는지 확인
            if !insignificantSounds.contains(identifiedLabel) && confidence >= specificThreshold {
                self.currentLabel = identifiedLabel      // UI를 업데이트할 라벨 변경
                self.currentConfidence = confidence    // 신뢰도 업데이트
                self.resetStateAfterDelay()            // 3초 후 원래 상태로 복귀
            }
            // ... (기타 규칙) ...
        }
    }
}
```

---

### 3. `MainAppView`: 데이터와 UI의 만남 (소리를 빛으로)

**설명:** 이 코드는 `SwiftUI`의 `@ObservedObject`를 사용하여 `SoundClassifier`의 상태 변화를 감지하고, `currentLabel`에 연결된 색상, 이미지, 텍스트를 화면에 렌더링하여 반응형 UI를 구현합니다.

**선정 이유:** 이 코드는 '소리'가 '빛'으로 번역되는 최종 단계이자, 사용자 경험의 핵심입니다. `SoundClassifier`가 변경한 `currentLabel` 데이터에 따라, 배경색(`classifier.currentLabel.color`)이 마법처럼 바뀌는 모습을 보여줍니다. 데이터와 UI가 어떻게 유기적으로 연결되는지를 가장 잘 보여주는 부분입니다.

```swift
struct MainAppView: View {
    // SoundClassifier의 변경 사항을 실시간으로 관찰
    @ObservedObject var classifier: SoundClassifier

    var body: some View {
        ZStack {
            // 1. SoundClassifier가 발행한 'currentLabel'의 색상으로 배경을 채움
            classifier.currentLabel.color
                .animation(.easeInOut(duration: 0.5), value: classifier.currentLabel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // 2. 'currentLabel'에 맞는 이미지와 표시 이름으로 UI 업데이트
                Image(classifier.currentLabel.imageName)
                Text(classifier.currentLabel.displayName)
            }
        }
        // ...
    }
}
```
