path = '/Users/jackalope/Documents/WinGame/WinGame/Utilities/GameManager/Legendary/LegendaryInterface.swift'
content = File.read(path)
replaced = content.sub(/await transformProcess\(process\) do \{[\s\S]*?catch \{[\s\S]*?\n \}/) do
  <<~REPLACE
  await transformProcess(process)
              
              do {
                  try process.run()
                  process.waitUntilExit()
              } catch {
                  log.error("Failed to update metadata: \\(error)")
              }
  REPLACE
end

if content == replaced
    puts 'No replacement made.'
else
    File.write(path, replaced)
    puts 'Fixed with Ruby script!'
end
