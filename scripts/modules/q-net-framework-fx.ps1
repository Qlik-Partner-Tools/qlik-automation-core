Write-log -Message "Installing .net Framework 4.8"
cinst dotnetfx --no-progress

# Write-log -Message "Installing vcredist2017"
# cinst vcredist2017

Write-log -Message "Installing vcredist140"
choco install vcredist140