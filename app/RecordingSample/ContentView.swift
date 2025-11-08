import SwiftUI

struct ContentView: View {
    @StateObject private var classifier = SoundClassifier()

    var body: some View {
        switch classifier.appState {
        case .onboarding:
            OnboardingView(classifier: classifier)
        case .calibrating:
            CalibrationView()
        case .running:
            // 기존 KoongdeokView를 MainAppView로 변경하여 사용
            MainAppView(classifier: classifier)
        }
    }
}
