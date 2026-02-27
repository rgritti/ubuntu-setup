# ubuntu-setup
scripts to initialize ubuntu with Plex and Home Assistant

## Step 1
Install samba

## Step 2
Add the nas driver to `/etc/fstab`

Add the following line to fstab:

```
/dev/sda1       /mnt/pen        exfat    defaults,uid=1000,gid=984,umask=0002    0       0
```
where 984 is the samba group
Make sure the the uuid is correct by finding your drive under `sudo blkid`

In `mnt/pen` create a directory `media` for Plex to use as source

## Step 3
Add the samba share

run
```
sudo ./setup_samba_share.sh /mnt/pen/plexmedia plexmedia
```
The default user used is `rob`. change it in the script if needed

## Step 4

Config:
```
MOVIES=/mnt/pen/plexmedia/movies
SERIES=/mnt/pen/plexmedia/series
CONFIG=/home/rob/plex/conf
```

```
docker run -d \
    --name=plex \
    --net=host \
    --restart=unless-stopped \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Europe/Berlin \
    -e VERSION=docker \
    -v $CONFIG:/config \
    -v $MOVIES:/movies \
    -v $SERIES:/series \
    plexinc/pms-docker:latest
```

  Replace these paths:
  - TZ=Europe/Rome - Your timezone (use timedatectl to check yours)

  To get your user/group ID (if not 1000):
  id -u  # Get PUID
  id -g  # Get PGID

  Complete setup steps:

  1. Create the config directory:
  sudo mkdir -p /path/to/plex/config

  2. Run the Docker command above
  3. Access Plex at: http://localhost:32400/web

  To manage the container:
  docker stop plex       # Stop the server
  docker start plex      # Start the server
  docker restart plex    # Restart the server
  docker logs plex       # View logs

  The --restart=unless-stopped ensures Plex starts automatically when your machine reboots.
