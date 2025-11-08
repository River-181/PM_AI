
import os
import glob
import random
import shutil

RAW_DATA_DIR = '/Users/river/cnu_ML-DL/data/raw_data'
TEST_DIR = '/Users/river/cnu_ML-DL/data/test'
TEST_SPLIT_RATIO = 0.1

def split_test_data():
    class_dirs = [d for d in os.listdir(RAW_DATA_DIR) if os.path.isdir(os.path.join(RAW_DATA_DIR, d))]

    for class_dir in class_dirs:
        # Create class directory in test set
        test_class_dir = os.path.join(TEST_DIR, class_dir)
        os.makedirs(test_class_dir, exist_ok=True)

        # Get list of files
        raw_class_dir = os.path.join(RAW_DATA_DIR, class_dir)
        files = glob.glob(os.path.join(raw_class_dir, '*.wav'))

        # Randomly select files for the test set
        num_test_files = int(len(files) * TEST_SPLIT_RATIO)
        test_files = random.sample(files, num_test_files)

        # Move files
        for f in test_files:
            shutil.move(f, test_class_dir)

if __name__ == '__main__':
    split_test_data()
