#!/bin/bash

IP_FILE="/home/tomyang/scripts/aca_linux/linux_ip_list.txt"
LOCAL_FILE="/home/tomyang/scripts/aca_linux/local.txt"
REMOTE_FILE="/home/tomyang/scripts/aca_linux/remote.txt"
SSH_USER="tomyang"

#Generate the key pair
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_PUBKEY="$SSH_KEY.pub"

if [[ ! -f "$SSH_PUBKEY" ]];then
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"
	ssh-keygen -t ed25519 -f $SSH_KEY" -N "" || {
		echo -e "ssh public key generates failure."
		exit 1
	}
	echo -e "ssh public key generates success."
else
	echo -e "ssh public key has been generated."
fi

LOCAL_IPS=$(ip -4 addr show | awk '{print $2}' | cut -d/ -f1)

:> "$LOCAL_FILE"
:> "$REMOTE_FILE"

found_remote=0

while IFS= read -r ip; do
	if ! ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
		echo -e "$ip can't be connected."
		continue
	fi
	
	if echo "$LOCAL_IPS" | grep -qw "$ip";then
		echo "$ip" >> "$LOCAL_FILE"
		continue
	fi
	
	found_remote=1
	
	if ssh-copy-id "$SSH_USER@$ip";then
		echo "$ip" >> "$REMOTE_FILE"
	else
		echo -e "key distribution failure."
	fi
done < "$IP_FILE"
