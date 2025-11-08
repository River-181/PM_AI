
import os
import glob
import random
import shutil

RAW_DATA_DIR = '/Users/river/cnu_ML-DL/data/raw_data'
TRAIN_DIR = '/Users/river/cnu_ML-DL/data/train'
TEST_DIR = '/Users/river/cnu_ML-DL/data/test'
TRAIN_SPLIT_RATIO = 0.8

def split_train_test_data():
    class_dirs = [d for d in os.listdir(RAW_DATA_DIR) if os.path.isdir(os.path.join(RAW_DATA_DIR, d))]

    for class_dir in class_dirs:
        # Create class directories in train and test sets
        train_class_dir = os.path.join(TRAIN_DIR, class_dir)
        test_class_dir = os.path.join(TEST_DIR, class_dir)
        os.makedirs(train_class_dir, exist_ok=True)
        os.makedirs(test_class_dir, exist_ok=True)

        # Get list of files
        raw_class_dir = os.path.join(RAW_DATA_DIR, class_dir)
        files = glob.glob(os.path.join(raw_class_dir, '*.wav'))
        random.shuffle(files)

        # Split files for train and test
        num_train_files = int(len(files) * TRAIN_SPLIT_RATIO)
        train_files = files[:num_train_files]
        test_files = files[num_train_files:]

        # Move files to train directory
        for f in train_files:
            shutil.move(f, train_class_dir)
        
        # Move files to test directory
        for f in test_files:
            shutil.move(f, test_class_dir)

if __name__ == '__main__':
    split_train_test_data()
