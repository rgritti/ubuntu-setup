#!/bin/bash

sudo apt-get -y install podman samba

mkdir /media/ext
echo -e "\n/dev/sda1       /media/ext      exfat   auto" >> /etc/fstab
mount -a
mkdir /media/ext/media/movies
mkdir /media/ext/media/series

echo -e "\n[plexmedia]" >> /etc/samba/smb.conf
echo -e "\n    comment = Plex media folder"
echo -e "\n    path = /media/ext/media"
echo -e "\n    read only = no"
echo -e "\n    browsable = yes\n"
sudo service smbd restart
sudo ufw allow samba
sudo update-rc.d samba defaults
