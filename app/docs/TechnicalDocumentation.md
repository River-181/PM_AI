# RecordingSample App: 기술 문서

## 1. 프로젝트 개요

### 1.1. 핵심 목표
이 프로젝트는 '가정 내 다양한 소리를 빛으로 변환하는 하드웨어'의 **소프트웨어 프로토타입**입니다. iOS 앱의 형태로 하드웨어의 핵심 로직과 작동 방식을 시뮬레이션하고, 최종 제품의 사용자 경험을 미리 검증하는 것을 목표로 합니다.

가장 중요한 원칙은 **'상태의 시각화'**입니다. 중요한 소리(이벤트)는 물론, '정적'이나 '대화' 같은 일상적인 배경음까지 모두 적절한 색상(빛)으로 표현하여, 사용자가 현재 시스템의 상태를 항상 직관적으로 인지할 수 있도록 합니다.

### 1.2. 사용된 핵심 기술
- **UI:** Swift, SwiftUI
- **Audio:** `AVFoundation` (실시간 오디오 캡처)
- **AI/ML:**
    - `CoreML` (온디바이스 머신러닝 모델 실행)
    - `SoundAnalysis` (오디오 스트림 분석 및 분류)
- **Model:** `Koongdeok-soundAI 4.mlmodel`

---

## 2. 핵심 기능

- **실시간 소리 분류**: 마이크를 통해 입력되는 소리를 실시간으로 분석하고, 사전 정의된 23개의 라벨 중 하나로 분류합니다.
- **동적 UI**: 분류된 소리의 종류에 따라 화면 전체의 배경색이 해당 소리를 상징하는 색으로 부드럽게 전환됩니다.
- **데시벨 시각화**: 현재 소리 크기를 데시벨(dB) 단위로 환산하여 화면에 숫자로 표시합니다.
- **하드웨어 스타일 토글**: 앱의 분석 기능을 켜고 끄는 ON/OFF 스위치를 구현하여, 실제 하드웨어를 조작하는 듯한 경험을 제공합니다.

---

## 3. 아키텍처 및 로직

### 3.1. `SoundLabel` Enum
`sound_color_ai_app.swift` 파일에 정의되어 있으며, 앱의 모든 상태를 관리합니다.
- **역할**: 모델이 출력하는 문자열(`String`) 라벨을 Swift 코드에서 사용하기 쉬운 열거형(enum) 타입으로 매핑합니다.
- **주요 속성**:
    - `color`: 각 소리 라벨에 대응하는 `Color` 값. UI의 배경색을 결정합니다.
    - `displayName`: 각 라벨이 화면에 표시될 이름 (예: "아기 울음").

### 3.2. `SoundClassifier` Class
앱의 핵심 두뇌 역할을 하는 `ObservableObject` 클래스입니다.
- **역할**: `AVAudioEngine`을 설정하고, 마이크 입력을 받아 `SNAudioStreamAnalyzer`를 통해 CoreML 모델로 전달하며, 그 결과를 받아 UI를 업데이트합니다.
- **주요 `@Published` 속성**:
    - `currentLabel`: 현재 감지된 소리의 `SoundLabel`. UI의 색상과 텍스트를 결정합니다.
    - `currentPowerLevel`: 실시간으로 측정된 소리 크기(dB).
    - `isRecording`: ON/OFF 스위치와 바인딩되어 오디오 분석 상태를 제어합니다.
    - `confidenceThresholds`: 각 라벨의 탐지 민감도(신뢰도) 설정값.

### 3.3. 분류 처리 로직
`SoundClassifier`의 `request(_:didProduce:)` 메서드에 구현되어 있습니다.
1.  **'중요 소리' 처리**: '화재', '초인종' 등 사용자가 즉시 알아야 하는 소리가 **각자에게 설정된 신뢰도 임계값** 이상으로 감지되면, 즉시 해당 색상으로 화면을 변경하고 3초 타이머를 작동시킵니다. 3초 후에는 다시 중립 상태(회색)로 돌아갑니다.
2.  **'배경 소리' 처리**: '정적', '배경소음', '대화' 등 중요하지 않은 소리가 **공통 임계값(75%)** 이상으로 감지되면, 화면을 회색으로 표시하여 시스템이 유휴 또는 대기 상태임을 알립니다.
3.  **그 외**: 신뢰도가 낮은 모든 예측은 무시하여, 화면이 불필요하게 번쩍이는 것을 방지합니다.

---

## 4. 설정 및 커스터마이징

### 라벨별 민감도 조절 방법
앱 UI에는 별도의 설정 화면이 없으며, 개발자가 코드 내에서 직접 각 소리의 탐지 민감도(신뢰도 임계값)를 조절할 수 있습니다.

- **파일 위치**: `sound_color_ai_app.swift`
- **수정 위치**: `SoundClassifier` 클래스 내의 `loadThresholds()` 함수

```swift
private func loadThresholds() {
    if let savedThresholds = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Double], !savedThresholds.isEmpty {
        self.confidenceThresholds = savedThresholds
    } else {
        // 기본값 설정: 이 부분을 수정하여 민감도를 조절합니다.
        // 값의 범위는 0.0 (매우 민감) 부터 1.0 (매우 둔감) 까지입니다.
        self.confidenceThresholds = [
            SoundLabel.fire.rawValue: 0.70,
            SoundLabel.babyCry.rawValue: 0.99,
            SoundLabel.kakaotalk.rawValue: 0.85,
            // ... 다른 라벨들
        ]
    }
}
```
값을 수정한 후 앱을 다시 실행하면 새로운 민감도 설정이 적용됩니다. 설정값은 `UserDefaults`에 저장되어 앱을 재시작해도 유지됩니다.

---

## 5. 빌드 및 테스트

### 개인 iPhone에 앱 설치 방법
1.  **연결**: Mac에 iPhone을 USB 케이블로 연결합니다.
2.  **프로젝트 열기**: `RecordingSample.xcodeproj` 파일을 Xcode에서 엽니다.
3.  **기기 선택**: Xcode 상단 툴바에서 실행 대상을 본인의 iPhone으로 선택합니다.
4.  **서명 설정**:
    - 프로젝트 설정 > `Signing & Capabilities` 탭으로 이동합니다.
    - `Team` 항목에 본인의 Apple ID를 선택합니다.
5.  **실행**: Xcode의 재생(▶️) 버튼을 눌러 빌드 및 설치를 진행합니다.
6.  **개발자 신뢰 (최초 1회)**:
    - iPhone에서 `설정 > 일반 > VPN 및 기기 관리`로 이동합니다.
    - 본인의 Apple ID를 선택하고 '신뢰' 버튼을 누릅니다.
7.  **앱 실행**: 홈 화면에 생성된 앱 아이콘을 눌러 실행합니다.

---

## 6. 변경 이력

코드의 주요 변경 사항은 `SwiftChangeLog.md` 파일에 체계적으로 기록되고 있습니다. 기능 수정이나 로직 변경 시 해당 파일을 함께 업데이트하여 추적성을 유지합니다.
