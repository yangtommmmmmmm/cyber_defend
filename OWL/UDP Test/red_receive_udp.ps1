#This powershell script is for receiving udp packet emitted from Blue-VPC on Red-VPC.
$udpPort = 12345 #Open the received port

$udpClient = New-Object System.Net.SOckets.UdpClient($udpPort)#Create the object for receiving udp packet
Write-Host "Listening on UDP port $udpPort..."

try {
    while(true){
            #Create a sender object
            $remoteEndPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
            
            #Create a received parameter for receiving the test message
            $receivedBytes = $udpClient.Receive([ref]$remoteEndPoint)
            $message = [System.Text.Encoding]::UTF8.GetString($receivedBytes)

            #If reveives the test message,Red-VPC will show the below string.If not,go to 'catch case.
            Write-Host "Received from $($remoteEndPoint.Address):$($remoteEndPoint.Port) - $message"
    }
}catch {
    Write-Error $_
}finally {
    $udpClient.Close()
}


            
