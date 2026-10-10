path = 'WinGame.xcodeproj/project.pbxproj'
content = File.read(path)
replaced = content.sub(/repositoryURL = "https:\/\/github\.com\/firebase\/firebase-ios-sdk\.git";\n\t\t\trequirement = \{\n\t\t\t\tkind = upToNextMajorVersion;\n\t\t\t\tminimumVersion = 11\.4\.0;\n\t\t\t\};\n\t\t\};/) do
  <<~REPLACE
  repositoryURL = "https://github.com/firebase/firebase-ios-sdk.git";
  \t\t\trequirement = {
  \t\t\t\tkind = exactVersion;
  \t\t\t\tversion = 11.14.0;
  \t\t\t};
  \t\t};
  REPLACE
end
File.write(path, replaced)
puts "Done"
