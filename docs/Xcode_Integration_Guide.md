# 💻 TensorFlow 모델을 Xcode에서 사용하기 (Core ML 변환 가이드)

---

이 문서는 우리가 학습시킨 TensorFlow/Keras 모델을 macOS 앱에서 활용하기 위해 Core ML 모델로 변환하고, 이를 Xcode 프로젝트에 통합하는 방법을 안내합니다.

## 개요: 전체 흐름

1.  **모델 변환**: Python 스크립트를 사용해 `.keras` 모델을 `.mlmodel` 형식으로 변환합니다.
2.  **Xcode 통합**: 변환된 `.mlmodel` 파일을 Xcode 프로젝트에 추가합니다.
3.  **macOS 앱 구현**: 실시간으로 마이크 입력을 받아 스펙트로그램으로 전처리하고, Core ML 모델을 통해 소리를 분류한 후 결과를 화면에 표시하는 간단한 앱을 만듭니다.

---

## Step 1: Core ML Tools 설치

모델 변환을 위해 Apple에서 제공하는 `coremltools` 라이브러리를 설치해야 합니다. 터미널에서 아래 명령어를 실행하세요.

```bash
pip install coremltools
```

---

## Step 2: Keras 모델을 Core ML로 변환하기

`soundlight_mvp.ipynb` 노트북의 학습이 완료되면 `models/soundlight_efficientnet.keras` 파일이 생성됩니다. 이 모델을 변환하기 위해, 아래 내용으로 `convert_to_coreml.py` 라는 파이썬 스크립트 파일을 하나 생성하고 실행하세요.


```python
# convert_to_coreml.py

import coremltools as ct
import tensorflow as tf

# 1. 학습된 Keras 모델 불러오기
keras_model_path = 'models/soundlight_efficientnet.keras'
model = tf.keras.models.load_model(keras_model_path)

print("Keras 모델을 성공적으로 불러왔습니다.")

# 2. 모델의 입력과 출력 형식 정의
# 우리 모델은 (128, 128, 3) 크기의 이미지를 입력으로 받습니다.
image_input = ct.ImageType(shape=(1, 128, 128, 3), # (Batch, Height, Width, Channel)
                         bias=[-1, -1, -1], # Imagenet 모델들의 일반적인 전처리 방식
                         scale=1/127.5)

# 3. 모델 변환
# classify_images 함수는 이미지 분류 모델에 최적화된 변환을 수행합니다.
coreml_model = ct.convert(
    model,
    inputs=[image_input],
    classifier_config=ct.ClassifierConfig(['fire_alarm', 'door_event', 'phone_alert', 'appliance', 'baby_dog'])
)

print("Core ML 모델로 변환을 완료했습니다.")

# 4. 메타데이터 추가 (선택사항이지만 권장)
coreml_model.author = 'Team Mangsang Gwedo'
coreml_model.license = '...'
coreml_model.short_description = '일상 생활 소리를 5가지 카테고리로 분류하는 모델'
coreml_model.input_description['input_1'] = '128x128 크기의 로그-멜 스펙트로그램 이미지'
coreml_model.output_description['classLabel'] = '가장 확률이 높은 소리의 클래스 라벨'

# 5. 최종 .mlmodel 파일 저장
coreml_model.save("models/SoundLightClassifier.mlmodel")

print("\n✅ 성공! 'models/SoundLightClassifier.mlmodel' 파일이 생성되었습니다.")
```

**실행 방법:**

```bash
python convert_to_coreml.py
```

---

## Step 3: Xcode 프로젝트에 Core ML 모델 추가하기

1.  Xcode에서 새로운 macOS 앱 프로젝트를 생성합니다. (SwiftUI 또는 AppKit 선택)
2.  Finder에서 방금 생성된 `SoundLightClassifier.mlmodel` 파일을 Xcode 프로젝트 네비게이터(왼쪽 패널)로 드래그 앤 드롭합니다.
3.  `Add to targets` 옵션이 체크되어 있는지 확인하고 Finish를 누릅니다.
4.  Xcode가 자동으로 `SoundLightClassifier`라는 Swift 클래스를 생성하여 모델을 쉽게 사용할 수 있도록 준비해 줍니다.

---

## Step 4: 간단한 macOS 분류 앱 구현하기 (개념)

노트북에서 소리를 분류하는 프로그램을 만들기 위한 핵심 로직입니다.

### 핵심 로직

1.  **오디오 입력 받기 (`AVFoundation` 프레임워크)**
    -   `AVAudioEngine`을 사용하여 마이크로부터 실시간 오디오 데이터를 버퍼 형태로 계속 받아옵니다.

2.  **전처리: 오디오 버퍼 → 스펙트로그램 이미지 (`Accelerate` 프레임워크)**
    -   **가장 중요한 단계입니다.** Python의 `librosa`가 수행했던 로그-멜 스펙트로그램 변환 과정을 Swift로 동일하게 구현해야 합니다.
    -   오디오 버퍼(Float 배열)에 FFT(고속 푸리에 변환)를 적용하고, 멜 필터뱅크를 곱한 후, 로그 스케일로 변환하여 `CVPixelBuffer` 형식의 이미지 데이터를 만듭니다.
    -   이 과정은 복잡하며, Apple의 `Accelerate` 프레임워크나 서드파티 라이브러리를 사용하여 구현할 수 있습니다.

3.  **추론 (`CoreML` 프레임워크)**
    -   전처리된 `CVPixelBuffer` 이미지를 `SoundLightClassifier` 모델에 입력으로 제공합니다.
    -   `model.prediction(input: ...)` 메소드를 호출하여 예측 결과를 받습니다.

4.  **결과 표시 (`SwiftUI` 또는 `AppKit`)**
    -   모델의 예측 결과(가장 확률이 높은 클래스 라벨)를 화면의 텍스트 레이블에 표시합니다.

### 예시 코드 (개념적인 Swift 코드)

```swift
import SwiftUI
import AVFoundation
import CoreML

struct ContentView: View {
    @State private var detectedSound = "듣는 중..."
    private var audioManager = AudioManager()

    var body: some View {
        Text(detectedSound)
            .font(.largeTitle)
            .onAppear {
                audioManager.startListening {
                    soundLabel in
                    // 모델로부터 예측 결과를 받으면 UI를 업데이트합니다.
                    self.detectedSound = soundLabel
                }
            }
    }
}

class AudioManager {
    private var audioEngine = AVAudioEngine()
    private var coremlModel: SoundLightClassifier?

    init() {
        do {
            self.coremlModel = try SoundLightClassifier(configuration: MLModelConfiguration())
        } catch {
            print("모델 로딩 실패: \(error)")
        }
    }

    func startListening(completion: @escaping (String) -> Void) {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 16000, format: recordingFormat) { buffer, time in
            // 1. 오디오 버퍼(buffer)를 받습니다.
            
            // 2. **[핵심]** 이 버퍼를 CVPixelBuffer 형식의 스펙트로그램 이미지로 변환합니다.
            //    (이 부분은 별도의 SpectrogramConverter 클래스/함수로 구현해야 합니다.)
            guard let spectrogramImage = self.createSpectrogram(from: buffer) else { return }

            // 3. Core ML 모델로 추론합니다.
            do {
                let prediction = try self.coremlModel?.prediction(input_1: spectrogramImage)
                if let label = prediction?.classLabel {
                    DispatchQueue.main.async {
                        completion(label)
                    }
                }
            } catch {
                print("추론 실패: \(error)")
            }
        }

        // 오디오 엔진 시작
        do {
            try audioEngine.start()
        } catch {
            print("오디오 엔진 시작 실패: \(error)")
        }
    }
    
    private func createSpectrogram(from buffer: AVAudioPCMBuffer) -> CVPixelBuffer? {
        // TODO: Librosa의 스펙트로그램 생성 로직을 여기에 Swift로 구현해야 합니다.
        // 이 부분이 가장 복잡하고 중요한 파트입니다.
        return nil // 임시
    }
}
```

