#!/bin/bash

sudo apt update
sudo apt install samba -y

echo -e "\n[plex share]" | sudo tee -a /etc/samba/smb.conf
echo -e "    comment = Plex share" | sudo tee -a /etc/samba/smb.conf
echo -e "    path = /mnt/pen/media" | sudo tee -a /etc/samba/smb.conf
echo -e "    read only = no" | sudo tee -a /etc/samba/smb.conf
echo -e "    browsable = yes\n" | sudo tee -a /etc/samba/smb.conf

sudo service smbd restart
sudo ufw allow samba
