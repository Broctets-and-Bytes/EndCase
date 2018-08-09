###Tool for collecting and unzipping several popular (free) forensics tools. These will be utilized in the EndCase analysis and reporting script.
###Last updated on 08/09/2018; Designed with Powershell version 5.1.17134.112; Created by Brock Bell; Git @Broctets-and-Bytes
#Create a variable with the user desired location for tools; Move the shell there.
$ToolLocation = Read-Host "Directory to place tools for collection and analysis"
cd $ToolLocation
#Establish that web requests in this script will utilize TLS1.2. Powershell default is not high enough.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Begin collecting the tools from their various locations. 
Invoke-WebRequest -Uri "https://github.com/jschicht/RawCopy/archive/master.zip" -OutFile .\Rawcopy.zip         
Invoke-WebRequest -Uri "https://github.com/jschicht/UsnJrnl2Csv/archive/master.zip" -OutFile .\UsnJrnl2Csv.zip 
Invoke-WebRequest -Uri "https://github.com/jschicht/Mft2Csv/archive/master.zip" -OutFile .\Mft2Csv.zip
Invoke-WebRequest -Uri "https://github.com/jschicht/LogFileParser/archive/master.zip" -OutFile .\LogFileParser.zip
Invoke-WebRequest -Uri "https://github.com/ANSSI-FR/bmc-tools/archive/master.zip" -OutFile .\bmc-tools.zip
Invoke-WebRequest -Uri "https://ericzimmerman.github.io/Software/ShellBagsExplorer.zip" -OutFile .\ShellBagsExplorer.zip
Invoke-WebRequest -Uri "https://ericzimmerman.github.io/Software/AppCompatCacheParser.zip" -OutFile .\AppCompatCacheParser.zip
Invoke-WebRequest -Uri "https://ericzimmerman.github.io/Software/AmcacheParser.zip" -OutFile .\AmcacheParser.zip
Invoke-WebRequest -Uri "https://ericzimmerman.github.io/Software/JumpListExplorer.zip" -OutFile .\JumpListExplorer.zip
Invoke-WebRequest -Uri "https://ericzimmerman.github.io/Software/RecentFileCacheParser.zip" -OutFile .\RecentFileCacheParser.zip
Invoke-WebRequest -Uri "https://github.com/keydet89/RegRipper2.8/archive/master.zip" -OutFile .\regripper2.8.zip
Invoke-WebRequest -Uri "https://github.com/log2timeline/plaso/releases/download/20180630/plaso-20180630-amd64.zip" -OutFile .\plaso-20180630-amd64.zip
mkdir Archive
#Create an archive of the tools just downloaded in their zip format.
$ArchiveFiles = (gci .\* -Filter *.zip) 
ForEach ($Zip in $ArchiveFiles) {

Copy-Item $zip ./Archive}
#Unzip all the local tools and delete the original zip containers from current directory.
Get-ChildItem .\* -Filter *.zip | Expand-Archive -DestinationPath .\ -Force
del -Force .\*.zip


###Optional cleanup section that can be uncommented.This will break SQL import functionality for some tools. Also requires changes to parsing and analysis script. Best left commented. 
<#
Copy-Item LogFileParser-master\* .\


del LogFileParser-master -Force -Recurse

Copy-Item Mft2Csv-master\* .\
del Mft2Csv-master -Force -Recurse

Copy-Item RawCopy-master\* .\
del RawCopy-master -Force -Recurse

Copy-Item UsnJrnl2Csv-master\* .\
del UsnJrnl2Csv-master -Force -Recurse

Copy-Item RegRipper2.8-master\* .\
del RegRipper2.8-master -Force -Recurse

Copy-Item bmc-tools-master\* .\
del bmc-tools-master -Force -Recurse
#>