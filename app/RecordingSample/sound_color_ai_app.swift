import SwiftUI
import AVFoundation
import CoreML
import SoundAnalysis

// MARK: - 소리 분류 및 색상/UI 매핑

/// 앱에서 사용하는 소리 레이블을 정의하고, 각 레이블에 맞는 색상과 화면에 표시될 이름을 제공합니다.
enum SoundLabel: String, CaseIterable {
    // 23개로 라벨 확장
    case applianceDone = "가전제품_종료"
    case dog = "개"
    case doorKnock = "문_노크"
    case doorLock = "문_도어락"
    case doorBell = "문_초인종"
    case background = "배경소음"
    case conversation = "대화"
    case kakaotalk = "카톡"
    case noiseFurniture = "소음_가구"
    case noiseDrum = "소음_드럼"
    case noiseDoor = "소음_문소리"
    case noiseChildFootsteps = "소음_아이발소리"
    case noiseAdultFootsteps = "소음_어른발소리"
    case noiseVacuum = "소음_청소기"
    case noiseWashingMachine = "소음_통돌이"
    case babyCry = "아기_울음"
    case fall = "안전_낙상"
    case fire = "안전_화재_경보"
    case silence = "정적"
    case timer = "타이머_알람"
    case phoneRing = "폰_링톤"
    case phoneAlert = "폰_알림"
    case phoneCall = "폰_전화"
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
            
        // 노란색: 알림 관련
        case .phoneRing, .phoneAlert, .phoneCall, .timer, .kakaotalk:
            return .yellow
            
        // 초록색: 가전
        case .applianceDone:
            return .green
            
        // 파란색: 사람 및 동물
        case .babyCry, .dog:
            return .blue
            
        // 보라색: 각종 소음
        case .noiseFurniture, .noiseDrum, .noiseDoor, .noiseChildFootsteps, .noiseAdultFootsteps, .noiseVacuum, .noiseWashingMachine:
            return .purple
            
        // 회색: 배경 또는 알 수 없음
        case .background, .silence, .unknown, .conversation:
            return .gray
        }
    }

    /// 화면에 표시될 레이블 이름입니다.
    var displayName: String {
        switch self {
        case .applianceDone: return "가전 종료"
        case .dog: return "개 짖는 소리"
        case .doorKnock: return "노크"
        case .doorLock: return "도어락"
        case .doorBell: return "초인종"
        case .background: return "배경 소음"
        case .conversation: return "대화 소리"
        case .kakaotalk: return "카톡"
        case .noiseFurniture: return "가구 소음"
        case .noiseDrum: return "드럼 소리"
        case .noiseDoor: return "문 소리"
        case .noiseChildFootsteps: return "아이 발소리"
        case .noiseAdultFootsteps: return "어른 발소리"
        case .noiseVacuum: return "청소기 소리"
        case .noiseWashingMachine: return "세탁기 소리"
        case .babyCry: return "아기 울음"
        case .fall: return "낙상 감지"
        case .fire: return "화재 경보"
        case .silence: return "정적"
        case .timer: return "알람"
        case .phoneRing: return "전화벨"
        case .phoneAlert: return "알림"
        case .phoneCall: return "통화"
        case .unknown: return "분석 대기 중..."
        }
    }
    
    /// 각 소리 레이블에 대응하는 이미지 이름입니다. (색상 그룹 기준)
    var imageName: String {
        switch self {
        case .fall, .fire:
            return "red"
        case .doorKnock, .doorLock, .doorBell:
            return "orange"
        case .phoneRing, .phoneAlert, .phoneCall, .timer, .kakaotalk:
            return "yellow"
        case .applianceDone:
            return "green"
        case .babyCry, .dog:
            return "blue"
        case .noiseFurniture, .noiseDrum, .noiseDoor, .noiseChildFootsteps, .noiseAdultFootsteps, .noiseVacuum, .noiseWashingMachine:
            return "purple"
        case .background, .silence, .unknown, .conversation:
            return "background" // 기본(회색) 상태 이미지
        }
    }
    
    /// Core ML 모델의 출력(String)을 SoundLabel enum으로 변환합니다.
    static func fromIdentifier(_ identifier: String) -> SoundLabel {
        return SoundLabel(rawValue: identifier) ?? .unknown
    }
    
    /// 민감도 설정에 노출할 라벨 목록
    static var adjustableLabels: [SoundLabel] {
        return SoundLabel.allCases.filter {
            $0 != .background && $0 != .silence && $0 != .unknown && $0 != .conversation
        }
    }
}

// MARK: - 소리 분류기 (핵심 로직)

/// 앱의 전체 상태를 관리하는 열거형
enum AppState {
    case onboarding // 온보딩 (캘리브레이션 안내)
    case calibrating // 캘리브레이션 진행 중
    case running // 메인 앱 실행 중
}

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
    
    var isEngineRunning: Bool {
        return audioEngine?.isRunning ?? false
    }
    
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
    
    // UserDefaults 키
    private let confidenceThresholdsKey = "confidenceThresholds"
    private let baselineDecibelKey = "baselineDecibel"
    
    // 스무딩을 위한 속성
    private var smoothedPowerLevel: Float = -160.0
    private let smoothingFactor: Float = 0.2 // 값이 작을수록 더 부드러워짐

    // MARK: - 초기화
    override init() {
        super.init()
        setupAudioEngine()
        loadSettings()
        
        // 저장된 기준값이 있으면 바로 running 상태로, 없으면 onboarding 부터 시작
        if self.baselineDecibel != nil {
            self.appState = .running
        } else {
            self.appState = .onboarding
        }
    }
    
    // MARK: - 설정 저장 및 로드
    private func saveThresholds() {
        UserDefaults.standard.set(confidenceThresholds, forKey: confidenceThresholdsKey)
    }
    
    private func saveBaselineDecibel() {
        UserDefaults.standard.set(baselineDecibel, forKey: baselineDecibelKey)
    }

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
                SoundLabel.kakaotalk.rawValue: 0.60,
                SoundLabel.phoneRing.rawValue: 0.40,
                SoundLabel.phoneAlert.rawValue: 0.60,
                SoundLabel.phoneCall.rawValue: 0.60,
                SoundLabel.timer.rawValue: 0.80,
                SoundLabel.doorBell.rawValue: 0.99,
                SoundLabel.doorLock.rawValue: 0.98,
                SoundLabel.doorKnock.rawValue: 0.90,
                SoundLabel.applianceDone.rawValue: 0.90,
                SoundLabel.noiseFurniture.rawValue: 0.95,
                SoundLabel.noiseDrum.rawValue: 0.97,
                SoundLabel.noiseDoor.rawValue: 0.99,
                SoundLabel.noiseChildFootsteps.rawValue: 0.90,
                SoundLabel.noiseAdultFootsteps.rawValue: 0.90,
                SoundLabel.noiseVacuum.rawValue: 0.95,
                SoundLabel.noiseWashingMachine.rawValue: 0.98,
                SoundLabel.conversation.rawValue: 0.97,
                SoundLabel.silence.rawValue: 0.30
            ]
        }
        
        // 기준 데시벨 로드
        if UserDefaults.standard.value(forKey: baselineDecibelKey) != nil {
            self.baselineDecibel = UserDefaults.standard.float(forKey: baselineDecibelKey)
        }
    }
    
    // MARK: - 캘리브레이션
    
    /// 캘리브레이션을 시작하고 기준 데시벨을 측정합니다.
    func startCalibration() {
        guard let audioEngine = audioEngine, !audioEngine.isRunning else { return }
        
        DispatchQueue.main.async {
            self.appState = .calibrating
        }
        
        setupAudioSession()
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        var measurements: [Float] = []
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, time in
            let power = self.calculatePower(from: buffer)
            measurements.append(power)
        }
        
        do {
            try audioEngine.start()
            
            // 3초 동안 측정 후 평균 계산
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                // -160 (무음) 값은 평균 계산에서 제외
                let validMeasurements = measurements.filter { $0 > -150 }
                let average = validMeasurements.isEmpty ? -60.0 : validMeasurements.reduce(0, +) / Float(validMeasurements.count)
                
                self.baselineDecibel = average
                self.saveBaselineDecibel()
                
                print("캘리브레이션 완료. 기준 데시벨: \(average)")
                
                self.appState = .running
            }
        } catch {
            print("캘리브레이션 중 오디오 엔진 시작 실패: \(error.localizedDescription)")
            self.appState = .onboarding
        }
    }
    /// 캘리브레이션을 포함한 모든 상태를 초기화하고 온보딩부터 다시 시작합니다.
    func resetAndRecalibrate() {
        if isEngineRunning {
            stop()
        }
        
        // UserDefaults에서 기준점 삭제
        UserDefaults.standard.removeObject(forKey: baselineDecibelKey)
        self.baselineDecibel = nil
        
        DispatchQueue.main.async {
            self.appState = .onboarding
        }
    }
    
    // MARK: - 오디오 처리
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("오디오 세션 설정에 실패했습니다: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
    }
    
    /// 오디오 버퍼에서 데시벨 값을 계산하는 헬퍼 함수
    private func calculatePower(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return -160.0 }
        let channelDataValue = channelData.pointee
        let channelDataValueArray = UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength))
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        return rms > 0.0 ? 20 * log10(rms) : -160.0
    }

    /// 메인 소리 분석을 시작합니다.
    func start() {
        guard let audioEngine = audioEngine, !audioEngine.isRunning, baselineDecibel != nil else { return }
        
        setupAudioSession()
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly
            let model = try Koongdeok_soundAI_4(configuration: config).model
            let request = try SNClassifySoundRequest(mlModel: model)
            
            try streamAnalyzer?.add(request, withObserver: self)
        } catch {
            print("소리 분류 요청 생성에 실패했습니다: \(error.localizedDescription)")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            // 데시벨 계산 및 스무딩
            let rawPower = self.calculatePower(from: buffer)
            self.smoothedPowerLevel = (self.smoothingFactor * rawPower) + (1.0 - self.smoothingFactor) * self.smoothedPowerLevel
            
            DispatchQueue.main.async {
                // UI에는 기준점 대비 상대 데시벨 표시 (옵션) 또는 스무딩된 값 표시
                // 여기서는 스무딩된 절대값을 그대로 발행하고, UI에서 상대값으로 변환
                self.currentPowerLevel = self.smoothedPowerLevel
            }
            
            self.analysisQueue.async {
                self.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
                self.currentLabel = .silence
            }
        } catch {
            print("오디오 엔진 시작에 실패했습니다: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard let audioEngine = audioEngine, audioEngine.isRunning else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        streamAnalyzer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("오디오 세션 비활성화에 실패했습니다: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.currentLabel = .unknown
            self.currentPowerLevel = -160.0
        }
    }
    
    private func resetStateAfterDelay() {
        stateResetTimer?.invalidate()
        stateResetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentLabel = .silence
                self?.currentConfidence = 0.0
            }
        }
    }
}

// MARK: - 소리 분류 결과 처리 (SNResultsObserving)

extension SoundClassifier: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }

        let identifiedLabel = SoundLabel.fromIdentifier(classification.identifier)
        let confidence = classification.confidence

        // 1. 소리 카테고리 정의
        let insignificantSounds: [SoundLabel] = [.background, .silence, .conversation]
        
        // 2. 신뢰도 임계값 가져오기
        let specificThreshold = self.confidenceThresholds[identifiedLabel.rawValue] ?? 0.90 // 기본값을 90%로 상향
        let insignificantThreshold = 0.75 // 배경/정적 소리를 위한 일반 임계값

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
                // 현재 '중요 소리'가 표시되고 있다면, 타이머가 상태를 리셋하도록 둔다 (화면 깜빡임 방지)
                if self.stateResetTimer == nil || !(self.stateResetTimer?.isValid ?? false) {
                    self.currentLabel = identifiedLabel // '정적', '배경소음', '대화' 등을 회색으로 표시
                    self.currentConfidence = confidence
                }
            }
            // 규칙 C: 그 외 모든 경우 (신뢰도 낮은 소리)는 무시.
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("소리 분류 요청이 실패했습니다: \(error.localizedDescription)")
        stateResetTimer?.invalidate()
        DispatchQueue.main.async {
            self.currentLabel = .unknown
            self.currentConfidence = 0.0
        }
    }
}
// MARK: - SwiftUI 뷰

struct MainAppView: View {
    @ObservedObject var classifier: SoundClassifier

    /// 상대 데시벨 값을 계산하고 포맷팅하는 연산 프로퍼티
    private var relativeDecibelString: String {
        guard let baseline = classifier.baselineDecibel else { return "N/A" }
        let relativeDb = classifier.currentPowerLevel - baseline
        
        // 상대 데시벨이 0 이상일 때만 +를 붙여줌
        let plusSign = relativeDb > 0 ? "+" : ""
        return String(format: "\(plusSign)%.0f dB", relativeDb)
    }

    var body: some View {
        ZStack {
            // 동적으로 변경되는 배경색
            classifier.currentLabel.color
                .animation(.easeInOut(duration: 0.5), value: classifier.currentLabel)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                // "쿵덕이" 캐릭터 이미지와 상태 표시
                VStack {
                    Image(classifier.currentLabel.imageName)                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding(.bottom, 10)

                    Text(classifier.currentLabel.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                // 신뢰도 및 데시벨 표시
                if classifier.isRecording {
                    VStack(spacing: 8) {
                        if classifier.currentLabel != .unknown && classifier.currentLabel != .silence {
                            Text("신뢰도: \(Int(classifier.currentConfidence * 100))%")
                                .font(.headline)
                        }
                        
                        Text("상대 소음: \(relativeDecibelString)")
                            .font(.headline)
                        
                        Text("현재 소음 크기는 주변 환경에 따라 보정되었습니다.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }

                Spacer()

                // 분석이 꺼져있을 때만 재설정 버튼 표시
                if !classifier.isRecording {
                    Button(action: {
                        classifier.resetAndRecalibrate()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("소리 기준점 재설정")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }

                // 커스텀 토글 스위치
                ToggleSwitch(isOn: $classifier.isRecording)
                    .padding(.bottom, 30)
            }
        }
        .onReceive(classifier.$isRecording) { isRecording in
            if isRecording && !classifier.isEngineRunning {
                classifier.start()
            } else if !isRecording && classifier.isEngineRunning {
                classifier.stop()
            }
        }
        .onDisappear {
            classifier.stop()
        }
    }
}

// MARK: - 커스텀 토글 스위치 뷰
struct ToggleSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 0) {
            // OFF 부분
            ZStack {
                Rectangle()
                    .fill(isOn ? Color.gray.opacity(0.5) : Color.white)
                Text("OFF")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isOn ? .white : .black)
            }
            .frame(width: 100, height: 50)
            .onTapGesture {
                withAnimation { isOn = false }
            }

            // ON 부분
            ZStack {
                Rectangle()
                    .fill(isOn ? Color.green : Color.gray.opacity(0.5))
                Text("ON")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 100, height: 50)
            .onTapGesture {
                withAnimation { isOn = true }
            }
        }
        .frame(width: 200, height: 50)
        .clipShape(Capsule())
        .shadow(radius: 5)
    }
}


// MARK: - 앱 진입점
@main
struct SoundClassificationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
