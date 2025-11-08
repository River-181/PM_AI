
import os

def standardize_filenames(root_dir):
    for dirpath, _, filenames in os.walk(root_dir):
        # Skip the root directory itself
        if dirpath == root_dir:
            continue

        # Get the class name from the directory name
        class_name = os.path.basename(dirpath)
        
        # Counter for file numbering
        file_counter = 1
        
        for filename in sorted(filenames):
            # Ignore hidden files like .DS_Store
            if filename.startswith('.'):
                continue

            # Get the file extension
            try:
                extension = filename.split('.')[-1]
            except IndexError:
                extension = ''

            # Create the new filename
            new_filename = f"{class_name}_{str(file_counter).zfill(3)}.{extension}"
            
            # Get the full old and new file paths
            old_filepath = os.path.join(dirpath, filename)
            new_filepath = os.path.join(dirpath, new_filename)

            # Rename the file
            if old_filepath != new_filepath:
                print(f"Renaming: {old_filepath} -> {new_filepath}")
                os.rename(old_filepath, new_filepath)
            
            file_counter += 1

if __name__ == "__main__":
    raw_data_dir = os.path.abspath("../raw_data")
    standardize_filenames(raw_data_dir)
