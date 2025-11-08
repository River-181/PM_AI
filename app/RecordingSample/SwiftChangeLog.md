# Swift 코드 변경 로그

이 파일은 `sound_color_ai_app.swift` 파일의 주요 변경 이력을 기록합니다.

## 2025-11-08

### 요구사항
1.  새로운 라벨 '대화', '카톡' 추가.
2.  '대화'는 '배경소음'과 동일하게 취급.
3.  '정적', '배경소음', '대화' 등의 소리가 감지될 때, 이를 무시하지 않고 UI에 회색으로 명확히 표시하도록 로직 변경.
4.  '카톡' 알림 색상을 다른 알림과 동일한 노란색으로 변경.
5.  실제 기기 테스트 결과, 배경 소음에서 '세탁기', '도어락' 오탐지가 확인되어 민감도 재조정 필요.
6.  앱이 꺼진 상태에서 '소리 기준점'을 다시 캘리브레이션 할 수 있는 기능 추가.
7.  감지된 소리의 '색상 그룹'에 따라 중앙 피규어 이미지도 함께 변경되도록 기능 추가.

### 변경 내역
- **`SoundLabel` enum:**
    - `conversation`(`대화`), `kakaotalk`(`카톡`) case 추가.
    - `kakaotalk`에 `.cyan` 색상 및 "카톡" `displayName` 할당. (이후 `.yellow`로 변경)
    - `conversation`은 `.gray` 색상 및 "대화" `displayName` 할당.
    - `kakaotalk`의 색상을 `.cyan`에서 `.yellow`(알림 그룹)으로 변경.
    - `imageName` 프로퍼티의 로직을 수정하여, 각 라벨의 색상 그룹(red, orange 등)에 해당하는 이미지 이름을 반환하도록 변경.
- **`SoundClassifier.loadThresholds()`:**
    - 새로운 `kakaotalk` 라벨의 기본 신뢰도 임계값 추가.
    - 'doorLock' 및 'noiseWashingMachine'의 신뢰도 임계값을 `0.98`로 상향하여 민감도 하향 조정.
- **`SoundClassifier.request(_:didProduce:)` (분류 로직):**
    - `insignificantSounds` 배열에 `conversation` 추가.
    - 기존 로직을 수정하여, `insignificantSounds`에 포함된 라벨이 일정 신뢰도 이상으로 감지되면 UI를 회색으로 업데이트하도록 변경. '중요 소리'만 고유의 색상으로 표시.
- **`SoundClassifier` 클래스:**
    - `resetAndRecalibrate()` 함수 추가: `UserDefaults`에 저장된 기준점을 삭제하고 앱 상태를 `.onboarding`으로 되돌려 캘리브레이션을 다시 시작하게 함.
- **`MainAppView` (UI):**
    - 소리 분석이 `OFF` 상태일 때, `resetAndRecalibrate()` 함수를 호출하는 '소리 기준점 재설정' 버튼을 표시하도록 UI 수정.
    - 고정된 `Image("background")` 대신, `Image(classifier.currentLabel.imageName)`을 사용하여 이미지가 동적으로 변경되도록 수정하고 애니메이션 효과 추가.
