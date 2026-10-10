import re

with open('WinGame.xcodeproj/project.pbxproj', 'r') as f:
    text = f.read()

files_to_remove = [
    'SparkleUpdateController.swift',
    'SparkleUpdaterSheetViewModifier.swift',
    'SparkleUpdaterPreviewView.swift',
    'WhatsNewCollection.swift',
    'SemanticVersion+Codable(PropertyList).swift'
]

# We want to remove any line containing these file names
lines = text.split('\n')
new_lines = []
for line in lines:
    if any(f in line for f in files_to_remove):
        continue
    new_lines.append(line)

with open('WinGame.xcodeproj/project.pbxproj', 'w') as f:
    f.write('\n'.join(new_lines))
