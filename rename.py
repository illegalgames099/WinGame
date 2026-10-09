import os

def rename_content(root_dir):
    for subdir, dirs, files in os.walk(root_dir):
        if '.git' in subdir or 'xcuserdata' in subdir or 'rename.py' in subdir:
            continue
        for file in files:
            if file == "rename.py": continue
            file_path = os.path.join(subdir, file)
            # Try predicting text
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                if 'Mythic' in content:
                    content = content.replace('Mythic', 'WinGame')
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
            except UnicodeDecodeError:
                pass # not text

def rename_files_and_dirs(root_dir):
    # Rename from bottom up so parent renaming doesn't affect child paths
    for subdir, dirs, files in os.walk(root_dir, topdown=False):
        if '.git' in subdir or 'xcuserdata' in subdir:
            continue
        
        for name in files:
            if 'Mythic' in name:
                old_path = os.path.join(subdir, name)
                new_path = os.path.join(subdir, name.replace('Mythic', 'WinGame'))
                os.rename(old_path, new_path)
        
        for name in dirs:
            if 'Mythic' in name:
                old_path = os.path.join(subdir, name)
                new_path = os.path.join(subdir, name.replace('Mythic', 'WinGame'))
                os.rename(old_path, new_path)

if __name__ == '__main__':
    rename_content('.')
    rename_files_and_dirs('.')
