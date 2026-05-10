#This python script is for setting up listener on OPDS-1000.This listener can receive udp packet.
#!/usr/bin python3
import socket

#Open the local port-7501 for receiving udp packet
UDP_IP = "0.0.0.0"
UDP_PORT = 7501

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR, 1)
sock.bind((UDP_IP,UDP_PORT))

print("Listening on UDP port", UDP_PORT)

while True:
      data, addr = sock.recvfrom(1024)
      #If receives data on the local port-7501,OPDS-1000 will show below string
      print("Received from", addr) 
