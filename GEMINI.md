# Gemini Added Memories

## 사용자 정보
- 나는 대학생. 심리학과, 소프트웨어 복수전공, 철학 사회 생산성 등에 관심이 많음.
- 팀 '망상궤도'의 6개월 뒤 최종 목표는 '쿵덕이' 하드웨어 제품과 애플리케이션을 스토어에 출시하는 것입니다.

## 현재 프로젝트 맥락
- **과제**: '소리-빛 번역 AI' 모델 개발 관련 공모전 발표 준비.

## 완료된 작업 요약

1.  **데이터 표준화**: 사운드 데이터 파일명 및 폴더 구조를 일관된 형식으로 정리했습니다. (예: `baby_crying_001.wav`, `door_event_001.wav`)
2.  **데이터 증강/전처리**: 긴 오디오 파일을 5초 단위의 짧은 조각으로 나누는 Python 스크립트 (`trim_audio.py`)를 생성했습니다.
3.  **파일 시스템 재구성**: 모델 학습에 적합하도록 모든 데이터를 `train`/`val` 폴더로 80/20 분할하고, 클래스별 하위 폴더로 재배치했습니다. (예: `data/train/fire_alarm/`, `data/val/door_event/`)
4.  **EDA 및 모델 선정**: 탐색적 데이터 분석(EDA) 및 여러 모델(Custom CNN, MobileNetV2, EfficientNetB0)의 성능을 비교하는 Jupyter Notebook (`eda_and_model_selection_v2.ipynb`)을 생성했습니다.
5.  **MVP 모델 노트북 수정**: 기존 `soundlight_mvp.ipynb`를 새로운 데이터 구조 및 클래스 정의에 맞게 수정했습니다.
6.  **발표 스토리라인**: 공모전 발표 흐름을 담은 Markdown 파일 (`presentation_storyline.md`)을 생성했습니다.
7.  **Xcode 연동 가이드**: 학습된 모델을 Xcode에서 활용하기 위한 Core ML 변환 및 macOS 앱 구현 가이드 (`Xcode_Integration_Guide.md`)를 생성했습니다.

## 다음 단계
- `eda_and_model_selection_v2.ipynb` 노트북을 실행하여 데이터 분석 및 모델 성능 비교 결과를 확인합니다.
- `soundlight_mvp.ipynb` 노트북을 실행하여 최종 모델을 학습하고 저장합니다.
- `presentation_storyline.md`를 바탕으로 발표 자료를 준비합니다.
- `Xcode_Integration_Guide.md`를 참고하여 macOS 앱 개발을 진행합니다.
