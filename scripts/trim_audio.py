# 사용법:
# 1. (아직 설치하지 않았다면) 터미널에서 pydub 라이브러리와 ffmpeg을 설치합니다.
#    pip install pydub
#    brew install ffmpeg
#
# 2. 이 파이썬 스크립트를 실행합니다.
#    python /Users/river/Downloads/data/trim_audio.py

from pydub import AudioSegment
import os
import math

# 오디오 파일이 있는 디렉토리
directory = "/Users/river/cnu_ML-DL/data/raw_data"

# 나누고 싶은 조각(chunk)의 길이 (밀리초 단위, 예: 5000ms = 5초)
chunk_length_ms = 30000  # 30초

# 결과물을 저장할 새 디렉토리 생성
output_directory = os.path.join(directory, "chunked")
os.makedirs(output_directory, exist_ok=True)

# 디렉토리 내의 파일들을 순회합니다.
for filename in os.listdir(directory):
    if not filename.endswith(".wav"):
        continue

    filepath = os.path.join(directory, filename)
    original_name = os.path.splitext(filename)[0]

    try:
        # 오디오 파일 불러오기
        audio = AudioSegment.from_wav(filepath)
        duration_ms = len(audio)

        # 파일 길이가 설정한 조각 길이보다 길 경우
        if duration_ms > chunk_length_ms:
            # 몇 개의 조각으로 나눌지 계산
            num_chunks = math.ceil(duration_ms / chunk_length_ms)
            print(f"'{filename}' 파일({duration_ms/1000:.1f}초)을 {num_chunks}개의 조각으로 나눕니다...")

            for i in range(num_chunks):
                start_ms = i * chunk_length_ms
                end_ms = start_ms + chunk_length_ms
                chunk = audio[start_ms:end_ms]

                # 마지막 조각이 너무 짧으면 (예: 1초 미만) 저장하지 않음
                if len(chunk) < 1000 and i == num_chunks -1:
                    continue

                # 조각 파일의 새 이름 생성 (예: baby_crying_001_chunk_1.wav)
                chunk_filename = f"{original_name}_chunk_{i+1}.wav"
                chunk_filepath = os.path.join(output_directory, chunk_filename)
                
                # 조각 파일 저장
                chunk.export(chunk_filepath, format="wav")
        
        # 파일 길이가 더 짧거나 같은 경우
        else:
            # 파일을 그대로 새 디렉토리로 복사
            output_filepath = os.path.join(output_directory, filename)
            audio.export(output_filepath, format="wav")
            print(f"'{filename}' 파일({duration_ms/1000:.1f}초)은 길이가 충분하여 그대로 복사합니다.")

    except Exception as e:
        print(f"'{filename}' 파일 처리 중 오류 발생: {e}")

print("\n--- 작업 완료 ---")
print(f"모든 .wav 파일이 처리되어 아래 폴더에 저장되었습니다.")
print(output_directory)