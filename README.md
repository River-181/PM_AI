# PM_AI - Sound Classification AI Model

## 프로젝트 개요

이 프로젝트는 머신러닝을 이용한 음향 분류 AI 모델입니다. 다양한 환경음과 사운드를 자동으로 분류하는 시스템을 개발합니다.

## 주요 기능

- 🎵 다양한 음향 데이터 분류
- 🤖 딥러닝 기반 모델 학습
- 📊 실시간 음성 인식 및 분류
- 📱 iOS 앱 통합

## 프로젝트 구조

```
Project_mentoring/
├── app/                    # iOS 애플리케이션
├── notebooks/              # Jupyter 노트북
├── models/                 # 학습된 모델 파일
├── scripts/                # 유틸리티 스크립트
├── raw_data/               # 원본 데이터 (gitignore)
├── train/                  # 학습 데이터 (gitignore)
├── test/                   # 테스트 데이터 (gitignore)
└── README.md               # 프로젝트 문서
```

## 기술 스택

- **머신러닝**: TensorFlow, Keras
- **음성 처리**: librosa, scipy
- **모바일**: Swift, Core ML
- **버전 관리**: Git, GitHub

## 데이터셋

프로젝트에서는 다음의 음향 카테고리를 분류합니다:

- 가전제품 (세탁기, 건조기 등)
- 환경음 (개 짖는 소리, 문 노크 등)
- 안전 알람 (화재 경보, 낙상 감지 등)
- 생활음 (통화, 카톡 알림 등)

## 사용 방법

### 모델 학습

```bash
cd notebooks
jupyter notebook soundlight_mvp.ipynb
```

### iOS 앱 실행

```bash
cd app/RecordingSample
open RecordingSample.xcodeproj
```

## 개발 현황

- [x] 데이터 수집 및 전처리
- [x] 모델 학습
- [ ] 모델 최적화
- [ ] iOS 통합
- [ ] 배포

## 라이센스

이 프로젝트는 MIT 라이센스 하에 있습니다.

## 문의

문제나 제안사항이 있으시면 이슈를 생성해주세요.
