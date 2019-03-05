#!/bin/bash

disconnect_and_clean () {
	sudo docker kill vpn > /dev/null 2&>1
	sudo docker rm vpn > /dev/null 2&>1

	sudo cp ~/vpn_backup/local/resolv.conf /etc/
	rm -f ~/vpn_backup/local/* ~/vpn_backup/container/* > /dev/null 2&>1
	echo "Globalprotect is disconnected"
}

if [ $1 = "connect" ]; then
	echo "Enter login details:"

	read -p 'Server: ' server
	read -p 'Username: ' name
	read -sp 'Password: ' pass
	echo

	case $(sudo docker run -e SERVER=server -e USER=$name -e PASSWORD=$pass --privileged --name=vpn avanttic/vpn-globalprotect 2>&1) in
		*"Invalid username or password."*)
			disconnect_and_clean
			echo "Incorrect credentials please try again"
			exit 0
			;;
	esac

	echo "happening"

	mkdir -p ~/vpn_backup/local
	mkdir -p ~/vpn_backup/container
	mkdir -p ~/vpn_backup/ORIGINAL

	sudo docker cp vpn:/etc/resolv.conf ~/vpn_backup/container
	sudo docker kill vpn > /dev/null 2&>1
	sudo docker rm vpn > /dev/null 2&>1

	sudo docker run -dt -e SERVER=globalprotect.soton.ac.uk -e USER=$name -e PASSWORD=$pass --privileged --net=host --name=vpn avanttic/vpn-globalprotect > /dev/null

	[ -f ~/vpn_backup/ORIGINAL/resolv.conf ] || sudo cp /etc/resolv.conf ~/vpn_backup/ORIGINAL > /dev/null 2>&1
	sudo cp /etc/resolv.conf ~/vpn_backup/local > /dev/null 2>&1
	sudo cp ~/vpn_backup/container/resolv.conf /etc/ > /dev/null 2>&1
	echo "Globalprotect is connected!"
elif [ $1 = "exit" ]; then
	disconnect_and_clean
else
	echo "Unrecognised command"
fi
