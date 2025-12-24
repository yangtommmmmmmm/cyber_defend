#This python script is for sending out udp packet on OPDS-1000.
#!/usr/bin python3
import socket

#Define the received IP,PORT of host
UDP_IP = "10.10.X.93"
UDP_PORT = 12345

MESSAGE = "Test UDP"

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

#Show the successful sending
for i in range(1000):
    sock.sendto(MESSAGE.encode(), (UDP_IP,UDP_PORT))
    print("Sent message to", UDP_IP, UDP_PORT)
