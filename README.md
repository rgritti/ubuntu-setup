# ubuntu-setup
scripts to initialize ubuntu with Plex and Home Assistant

## Step 1
Install samba

## Step 1
Add the nas driver to `/etc/fstab`

Add the following line to fstab:

```
/dev/sda1       /mnt/pen        exfat    defaults,uid=1000,gid=984,umask=0002    0       0
```
where 984 is the samba group
Make sure the the uuid is correct by finding your drive under `sudo blkid`

In `mnt/pen` create a directory `media` for Plex to use as source

## Step 2
Add the samba share

run
```
sudo ./setup_samba_share.sh /mnt/pen/plexmedia plexmedia
```
The default user used is `rob`. change it in the script if needed
