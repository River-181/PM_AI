# 🎧🔆 소리→빛 번역 AI 프로젝트 현황

**작성일**: 2025년 11월 5일  
**프로젝트**: 가정 내 생활 소리 분류 시스템 (EfficientNetB0 전이학습)

---

## 📁 프로젝트 구조

```
/Users/river/cnu_ML-DL/data/
├── notebooks/
│   └── soundlight_mvp.ipynb        # 메인 작업 노트북
├── cache/                           # 전처리된 데이터 캐시
│   ├── X_train.npy                 # 원본 학습 데이터
│   ├── y_train.npy
│   ├── X_val.npy                   # 원본 검증 데이터
│   ├── y_val.npy
│   ├── X_train_balanced.npy        # ✅ 균형 조정된 학습 데이터
│   ├── y_train_balanced.npy
│   ├── X_val_balanced.npy          # ✅ 균형 조정된 검증 데이터
│   ├── y_val_balanced.npy
│   └── classes.json                # 클래스 정보
├── models/
│   ├── soundlight_efficientnet.keras  # 기존 학습 모델 (불균형 데이터)
│   ├── best.keras                     # 베스트 체크포인트
│   └── classes.json
├── train/                          # 원본 학습 데이터
│   ├── fire_alarm/
│   ├── door_event/
│   ├── phone_alert/
│   ├── appliance/
│   └── baby_dog/
└── val/                            # 원본 검증 데이터
    ├── fire_alarm/
    ├── door_event/
    ├── phone_alert/
    ├── appliance/
    └── baby_dog/
```

---

## 🎯 분류 대상 클래스

| 클래스 ID | 클래스 이름 | 설명 | 색상 매핑 |
|----------|------------|------|----------|
| 0 | fire_alarm | 화재 경보 | 🔴 RED |
| 1 | door_event | 초인종/노크/도어락 | 🟠 ORANGE |
| 2 | phone_alert | 전화벨/알림 | 🟡 YELLOW |
| 3 | appliance | 가전제품 완료음 | 🟢 GREEN |
| 4 | baby_dog | 아이 울음/강아지 짖음 | 🔵 BLUE |

---

## ⚙️ 기술 스택 & 하이퍼파라미터

### 환경
- **Python**: 3.12.11 (conda 환경: abc-bootcamp-FP-2025)
- **TensorFlow**: 2.19.0
- **주요 라이브러리**: librosa 0.11.0, sounddevice, numpy, scipy

### 오디오 전처리
```python
SR = 16000               # 샘플레이트 (Hz)
WIN_SEC = 1.0            # 윈도우 길이 (초)
HOP_SEC = 0.5            # 슬라이딩 스텝 (초)
N_MELS = 64              # 멜 밴드 수
FMIN, FMAX = 50, 8000    # 주파수 대역 (Hz)
SPEC_SHAPE = (128, 128)  # 스펙트로그램 크기
```

### 모델 아키텍처
- **베이스 모델**: EfficientNetB0 (weights=None, 1채널→3채널 변환)
- **분류 헤드**: GlobalAveragePooling2D → Dropout(0.2) → Dense(5, softmax)
- **학습 전략**: 2단계 학습
  1. Feature Extraction: 전체 레이어 동결, 분류 헤드만 학습 (20 epochs, LR=1e-3)
  2. Fine-tuning: 상위 200개 레이어 해제 (10 epochs, LR=1e-4)

### 학습 설정
```python
NUM_EPOCHS = 20
BATCH_SIZE = 32
LR = 1e-3              # Initial learning rate
FINETUNE_LR = 1e-4     # Fine-tuning learning rate
FINETUNE_AT = 200      # 미세조정할 레이어 수
```

---

## 🐛 문제 진단 및 해결 과정

### 발견된 문제
**증상**: 실시간 추론 시 모델이 "baby_dog" 클래스만 지속적으로 예측
- 다양한 소리(초인종, 전화벨 등)를 입력해도 baby_dog만 출력
- 확률 분포를 확인한 결과, baby_dog 클래스에 극단적으로 편향됨

### 원인 분석
**데이터 불균형** 문제 확인
- baby_dog 클래스가 다른 클래스에 비해 압도적으로 많은 샘플 보유
- 모델이 다수 클래스(baby_dog)에 과적합(overfitting)되어 학습
- 결과적으로 모든 입력에 대해 baby_dog를 예측하는 경향 발생

### 해결 방안
**언더샘플링(Undersampling) 기법 적용**
- 각 클래스의 샘플 수를 가장 적은 클래스에 맞춰 조정
- `balance_dataset()` 함수 구현 및 적용
- 균형 조정된 데이터를 별도 파일로 저장 (*_balanced.npy)

---

## 📊 노트북 구조 (soundlight_mvp.ipynb)

### 셀 실행 순서

| 셀 번호 | 섹션 | 설명 | 상태 |
|--------|------|------|------|
| 1 | 제목 | 프로젝트 개요 | ✅ |
| 2 | 의존성 설치 | pip install 명령어 (필요시) | ✅ |
| 3 | 임포트 & 설정 | 라이브러리 임포트, 하이퍼파라미터 정의 | ✅ |
| 4 | 유틸리티 함수 | wav_to_windows(), frames_to_logmels() | ✅ |
| 5 | 전처리 | build_split() - WAV → NPY 변환 | ✅ |
| 6 | 📊 데이터 분석 | 클래스별 분포 확인 | ⏳ **실행 대기** |
| 7 | ⚖️ 데이터 균형 조정 | balance_dataset() 실행 | ⏳ **실행 대기** |
| 8 | 🧠 모델 학습 | EfficientNetB0 학습 (use_balanced=True) | ⏳ **실행 대기** |
| 9 | 🔍 파일 추론 | specs_from_wav(), infer_file() | ✅ |
| 10 | 🎙 실시간 추론 | infer_realtime() - 마이크 입력 처리 | ✅ |

---

## 🔄 다음 작업 단계

### ⏳ 즉시 실행 필요

#### **1단계: 데이터 분포 확인** (셀 6)
```python
# 현재 데이터 불균형 상태 확인
# 각 클래스별 샘플 수와 비율 출력
```
**예상 출력**:
- Train/Val 세트별 클래스 분포
- 불균형 경고 메시지

#### **2단계: 데이터 균형 조정** (셀 7)
```python
# balance_dataset() 함수로 언더샘플링 수행
# *_balanced.npy 파일 생성 (이미 존재함)
```
**예상 결과**:
- 각 클래스가 동일한 샘플 수로 조정
- 균형 데이터 저장 완료 메시지

#### **3단계: 모델 재학습** (셀 8)
```python
# use_balanced=True로 균형 데이터 사용
# 약 20-30분 소요 예상
```
**중요**: 이전 모델은 불균형 데이터로 학습되었으므로 재학습 필수!

#### **4단계: 실시간 추론 테스트** (셀 10)
```python
# 재학습된 모델로 마이크 입력 테스트
# Ctrl+C로 종료
```
**기대 결과**:
- 다양한 소리에 대해 올바른 클래스 예측
- baby_dog 외 다른 클래스도 정상 인식

---

## 📝 코드 주요 변경사항

### 1. 데이터 로딩 함수 수정
```python
def load_cached(use_balanced=True):
    """균형 조정 데이터 사용 옵션 추가"""
    if use_balanced:
        # *_balanced.npy 파일 로드
    else:
        # 원본 파일 로드
```

### 2. 데이터 균형 조정 함수 추가
```python
def balance_dataset(X, y, target_samples_per_class=None):
    """
    언더샘플링으로 클래스 균형 조정
    - 최소 클래스 샘플 수에 맞춰 다른 클래스 샘플 감소
    - 랜덤 샘플링 + 셔플
    """
```

### 3. 실시간 추론 디버깅 강화
```python
# 오디오 레벨 모니터링
audio_level = np.abs(chunk).mean()

# 10프레임마다 상세 확률 분포 출력
if frame_count % 10 == 0:
    print(f"확률 분포: {dict(zip(classes, ema))}")
```

---

## 🎓 학습 내용 정리

### 데이터 불균형 문제
- **증상**: 한 클래스만 지속 예측
- **원인**: 다수 클래스에 학습 편향
- **해결**: 언더샘플링 (다수 클래스 샘플 감소)

### 전이학습 전략
- ImageNet 가중치 사용 불가 (1채널 입력 때문)
- 2단계 학습: Feature Extraction → Fine-tuning
- BatchNormalization 레이어는 동결 유지

### 실시간 추론 최적화
- 슬라이딩 윈도우: 1초 윈도우, 0.5초 홉
- 지수이동평균(EMA) 스무딩으로 예측 안정화
- 오디오 버퍼 관리로 연속 처리

---

## 🔗 참고 정보

### 파일 경로
- **메인 노트북**: `/Users/river/cnu_ML-DL/data/notebooks/soundlight_mvp.ipynb`
- **캐시 디렉토리**: `/Users/river/cnu_ML-DL/data/cache/`
- **모델 디렉토리**: `/Users/river/cnu_ML-DL/data/models/`

### 의존성 설치 (완료)
```bash
pip install sounddevice --upgrade  # Exit Code: 0 ✅
```

### 예상 학습 시간
- Feature Extraction (20 epochs): ~15분
- Fine-tuning (10 epochs): ~10분
- **총 예상 시간**: 약 25-30분

---

## ✅ 체크리스트

### 완료된 작업
- [x] 데이터 전처리 (원본 → NPY)
- [x] 데이터 불균형 진단
- [x] 균형 조정 함수 구현
- [x] 균형 데이터 생성 (*_balanced.npy)
- [x] 모델 학습 코드 수정 (use_balanced=True)
- [x] 실시간 추론 디버깅 코드 추가
- [x] sounddevice 패키지 설치

### 대기 중인 작업
- [ ] 셀 6 실행: 데이터 분포 확인
- [ ] 셀 7 실행: 데이터 균형 조정 (파일은 이미 존재)
- [ ] 셀 8 실행: 균형 데이터로 모델 재학습
- [ ] 셀 10 실행: 재학습된 모델로 실시간 추론 테스트
- [ ] 성능 평가 및 최종 검증

---

## 💡 다음 세션 시작 시 할 일

1. **노트북 열기**: `soundlight_mvp.ipynb`
2. **셀 3 실행**: 임포트 & 공통 설정 (변수 초기화)
3. **셀 6-8 순차 실행**: 데이터 분석 → 균형 조정 → 모델 학습
4. **학습 완료 후**: 실시간 추론으로 성능 검증

### 중요 사항
⚠️ **반드시 순서대로 실행**: 셀 3 → 6 → 7 → 8 → 10  
⚠️ **use_balanced=True** 설정 확인 (셀 8에 이미 적용됨)  
⚠️ **학습 시간 충분히 확보** (약 30분)

---

**현재 상태**: 균형 데이터 준비 완료, 재학습 대기 중 ⏳  
**다음 목표**: 균형 데이터로 모델 재학습 → 실시간 추론 성능 검증 🎯
