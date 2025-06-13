<#
The below script allows us to gather some parameters from NiceDCV and the OS
Then we execute a shutdown of the system based on the following criteria:

    - There are no Active NiceDCV Connections (NiceDCV Timeout Disconnect == 60 mins in DCV Config)
    - CPU Utilisation is below 20% (I.e there are no batch processing tasks running)

This is designed to run every 60mnins (or more frequently if you prefer) via a Scheduled Task.

#>

#Get Some Sesstion Status Parameters
$Active_connections = & 'C:\Program Files\NICE\DCV\Server\bin\dcv' describe-session console -j | ConvertFrom-Json | Select-Object -ExpandProperty num-of-connections
$CPUAveragePerformance = (GET-COUNTER -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2 -MaxSamples 5 |Select-Object -ExpandProperty countersamples | Select-Object -ExpandProperty cookedvalue | Measure-Object -Average).average

#If the Active Connection Count or CPU Utilisation is over our thresholds do nothing and exit.

if ($Active_connections -ge 1) {

    #We have Active Connections and the Machine is in use
    exit 0
}
    elseif ($Active_connections -eq 0 -And $CPUAveragePerformance -lt 20) {

    #If we have no active connections and the CPU is less than 20% utilised then we assume it can be shutdown.
    Stop-Computer -Force
    #Start-Process 'C:\windows\system32\notepad.exe'

}
    else {

    # We have no connected users but the CPU is being used (probably for batch processes) so we quietly exit.
    exit 0
}
