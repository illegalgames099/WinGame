import re

with open('WinGame.xcodeproj/project.pbxproj', 'r') as f:
    text = f.read()

# empty PBXFrameworksBuildPhase files
text = re.sub(r'(isa = PBXFrameworksBuildPhase;\n\s+buildActionMask = [0-9]+;\n\s+files = \()[^\)]*(\);)', r'\1\n\t\t\t\2', text)

# empty packageProductDependencies
text = re.sub(r'(packageProductDependencies = \()[^\)]*(\);)', r'\1\n\t\t\t\2', text)

# empty packageReferences
text = re.sub(r'(packageReferences = \()[^\)]*(\);)', r'\1\n\t\t\t\2', text)

with open('WinGame.xcodeproj/project.pbxproj', 'w') as f:
    f.write(text)
