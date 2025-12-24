#This powershell script is for sending out udp packet emitted from Blue-VPC
$TargetIP = "10.10.X.10" #10.10.X.10 is IPv4 address of Red-VPC receiveing udp packet
$TargetPort = 8811 #8811 is port number of Red-VPC receiveing udp packet 
$Message = "Test"
$count = 100000000000000000000 #The count of udp packet
$DeplaySec = 1 #The emitted delay time between each udp packet 

$udpClient = New-Object System.Net.Sockets.UdpClient #Create the object for udpclient

$bytes =
[System.Text.Encoding]::ASCII.GetBytes($Message)

for ($i=1; $i -le $count; $i++) {
      $udpClient.Send($bytes, $bytes.Length, $TargetIP, $TargetPort)
      Write-Host "[$i] has been sent to $TargetIP-$TargetPort -> $Message"
}

$udpClient.Close()
