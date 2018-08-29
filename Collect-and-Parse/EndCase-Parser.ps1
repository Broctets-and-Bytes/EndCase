####Last updated on 08/29/2018; Designed with Powershell version 5.1.17134.165; Created by Brock Bell; Git @Broctets-and-Bytes
Write-Host 'This script is designed to be executed against a mounted forensic image.' -ForegroundColor Yellow
Write-Host 'This must be executed as an administrator.' -ForegroundColor Yellow
Write-Host 'Requires: Python 2 or higher installed & set in environment path; .Net4.6; Powershell V3+' -ForegroundColor Yellow
Write-Host "MFT parsing is configured, but commented out because it takes significant time. It's the last parsing option of the script if you wish to enable." -ForegroundColor Yellow
Write-Host 'The processing actions are all pre-configured. These can, and should, be changed to meet your specific desires by modifying this script.' -ForegroundColor Green
$ToolsDir = Read-Host 'Directory of tools instalation for Tools script?'
#Create variable to store the root of the evidence partition.
$EDRoot = Read-Host "Please specify the drive letter for windows system partition. E.g. 'c' "
#Create variable to store the extracted content.
$DataRepo = Read-Host "Please specify the destination directory for extracted evidence items for processing"
$ReportsRepo = Read-Host "Please specify the directory to place all reports"
#Change to the tools directory.
cd $ToolsDir
#For Vista -> current; Copy Software, Sam, Security, and System registry hives for windows system.
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SAM /OutputPath:${DataRepo}
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SOFTWARE /OutputPath:${DataRepo}
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SOFTWARE.LOG /OutputPath:${DataRepo}
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SYSTEM /OutputPath:${DataRepo}
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SYSTEM.LOG /OutputPath:${DataRepo}
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SECURITY /OutputPath:${DataRepo}
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\system32\config\SECURITY.LOG /OutputPath:${DataRepo}
#Copy the AmCache.hve file.
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Windows\AppCompat\Programs\Amcache.hve /OutputPath:${DataRepo}
#Extract the Master File Table (MFT) using index number.
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:0 /OutputPath:${DataRepo}
#Extract the Master File Table Mirrort (MFTMirr) using index number.
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:1 /OutputPath:${DataRepo}
#Extract LogFile (NTFS loggin) using index number.
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:2 /OutputPath:${DataRepo} 
#Extract the UsnJournal from evidence partition.
.\ExtractUsnJrnl-master\ExtractUsnJrnl64.exe /DevicePath:${EDRoot}: /OutputPath:${DataRepo}
#Create variable for list of system users.
$DriveUsers = (gci ${EDRoot}:\Users)
###Create directory in data repo for neatly storing users.
mkdir ${DataRepo}\DriveUsers
#Loop through each user folder and collect the NTUser hives and logs.
ForEach ($u in $DriveUsers) {
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Users\$u\NTUSER.DAT /OutputPath:${DataRepo}\DriveUsers /OutputName:${u}_NTUSER.DAT
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Users\$u\NTUSER.DAT.LOG1 /OutputPath:${DataRepo}\DriveUsers /OutputName:${u}_NTUSER.DAT.LOG1
.\RawCopy-master\RawCopy64.exe /FileNamePath:${EDRoot}:\Users\$u\NTUSER.DAT.LOG2 /OutputPath:${DataRepo}\DriveUsers /OutputName:${u}_NTUSER.DAT.LOG2
}
#Create report folder for registry reports.
mkdir ${ReportsRepo}\RegistryReports
#Make Directory for user registry reports.
mkdir ${ReportsRepo}\RegistryReports\Users
#Make directory for Shellbag reports.
mkdir ${ReportsRepo}\RegistryReports\Users\Shellbags
#Make storage directory for UsnJrnl
mkdir ${DataRepo}\UsnJrnl
#Parse UsnJrnl with UTC output time.
.\UsnJrnl2Csv-master\UsnJrnl2Csv64.exe /UsnJrnlFile:${DataRepo}\'$UsnJrnl_$J.bin' /OutputPath:${ReportsRepo}\UsnJrnl /TimeZone:0.00
#This will create a set of automated reports for initital review. It's advisable to use the gui explorer to better examine the shellbags of key users. Timestamp UTC.  
.\SBECmd.exe -d ${DataRepo}\DriveUsers --csv ${ReportsRepo}\RegistryReports\Users\Shellbags
#$Will create three out files. Can be loaded into SQL but excel can handle data for most default configured subjects.
#Parse AmCache data.
mkdir ${ReportsRepo}\AmCache 
.\AmcacheParser.exe -f ${DataRepo}\AmCache.hve -i --csv ${ReportsRepo}\AmCache
#Change to the reg-ripper directory; rip.exe calls for plugins diretory this is an adjustment instead of moving plugins up a directory. 
cd .\RegRipper2.8-master
#Execute against Software, Security, and Sam hive. 
.\rip.exe -r ${DataRepo}\Software -f software -c >>${ReportsRepo}\RegistryReports\Software.csv
.\rip.exe -r ${DataRepo}\Security -f security -c >>${ReportsRepo}\RegistryReports\Security.csv
.\rip.exe -r ${DataRepo}\Software -f sam -c >>${ReportsRepo}\RegistryReports\sam.csv
#Prep for parsing of user hives by creating a variable containing the ntuser.dat files.
$UserHives = (gci ${DataRepo}\DriveUsers *.DAT)
#Run a loop against each NTUser.dat file and export an accordingly named report. All plugin defaults are left.
ForEach ($uh in $UserHives) {
.\rip.exe -r ${DataRepo}\DriveUsers\$uh -f ntuser -c >>${ReportsRepo}\RegistryReports\Users\${uh}-rr.csv
}
#Change back to tools root.
cd ..
.\AppCompatCacheParser.exe -t -f ${DataRepo}\System --csv ${ReportsRepo}\
#Parse MFT Data; This option is time intensive.If you do not need MFT data, consider commenting this option out.
###.\Mft2Csv-master\Mft2Csv64.exe /MFTFile:${DataRepo}\'$MFT' /TimeZone:0.00 /OutputPath:${ReportsRep