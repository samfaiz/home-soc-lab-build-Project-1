# On each Windows VM (DC01, WIN10-1):
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile sysmon.zip

Expand-Archive sysmon.zip -DestinationPath C:\Sysmon

# Use the SwiftOnSecurity config — battle-tested, sane defaults
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile C:\Sysmon\sysmonconfig.xml

C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml