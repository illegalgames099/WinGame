with open('WinGame.xcodeproj/project.pbxproj', 'r') as f:
    text = f.read()
text = text.replace('"\\"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run\\"\\n";', '"true";')
with open('WinGame.xcodeproj/project.pbxproj', 'w') as f:
    f.write(text)
