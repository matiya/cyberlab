Remove-Item -Force C:\Windows\Temp\patch_fw.log
"$(Get-Date) : Starting FW patching" >> C:\Windows\Temp\patch_fw.log

Start-Sleep 2

$dbparm = Get-Content "C:\CyberArk\PrivateArk\Server\Conf\dbparm.ini"
$dbparm_raw = Get-Content -Raw "C:\CyberArk\PrivateArk\Server\Conf\dbparm.ini"


$fw_rules = "AllowNonStandardFWAddresses=[0.0.0.0-255.255.255.255],Yes,3389:inbound/tcp,3389:inbound/udp
AllowNonStandardFWAddresses=[0.0.0.0-255.255.255.255],Yes,22:inbound/tcp,22:inbound/udp"


# If dbparm.ini already contains fw rule, skip it
if( -not ($dbparm -contains $fw_rules)){
    $patched = $dbparm -replace "^\[MAIN\]" ,"[MAIN]`n$fw_rules"
    Set-Content "C:\CyberArk\PrivateArk\Server\Conf\dbparm.ini" $patched
    Restart-Service 'PrivateArk Server' -Force
    Start-Sleep -Seconds 5
    "$(Get-Date) : FW Rule patched successfuly" >> C:\Windows\Temp\patch_fw.log

}
else{
    "$(Get-Date) : FW Rule already in dbparm.ini" >> C:\Windows\Temp\patch_fw.log
}

# Restore remoting capabilities
Invoke-expression -Command "C:\_media\scripts\ConfigureRemotingForAnsible.ps1"

# Ensure that RDP is enabled and NLA disabled
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices  -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

# Enable local users
# The hardening will disable any local user that is not logged
Enable-LocalUser -Name vagrant
Enable-LocalUser -Name CYA_ADM
