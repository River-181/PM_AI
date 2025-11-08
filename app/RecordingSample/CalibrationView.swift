import SwiftUI

struct CalibrationView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView() // 스피너 (빙글빙글 돌아가는 아이콘)
                .scaleEffect(2.0)
            
            Text("캘리브레이션 진행 중...")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("3초 동안 주변 소음을 측정합니다.\n잠시만 기다려주세요.")
                .multilineTextAlignment(.center)
        }
    }
}
