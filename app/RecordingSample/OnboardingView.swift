import SwiftUI

struct OnboardingView: View {
    @ObservedObject var classifier: SoundClassifier

    var body: some View {
        VStack(spacing: 30) {
            Text("소리 번역기 시작하기")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("정확한 소리 감지를 위해, 현재 공간의 기본 소음도를 측정하는 '캘리브레이션' 과정이 필요합니다.\n\n조용한 환경을 만드신 후 아래 버튼을 눌러주세요.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: {
                classifier.startCalibration()
            }) {
                Text("캘리브레이션 시작")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
            }
            .padding(.horizontal, 40)
        }
    }
}
