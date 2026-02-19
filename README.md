# ubuntu-setup
scripts to initialize ubuntu with Plex and Home Assistant

## Step 1
Add the nas driver to `/etc/fstab`

Add the following line to fstab:

```
/dev/disk/by-uuid/675B-2137 /mnt/pen auto nosuid,nodev,nofail,x-gvfs-show,uid=1000,gid=1000 0 0
```
Make sure the the uuid is correct by finding your drive under `sudo blkid`
Make sure your gid and uid are correct by looking for your user under `cat /etc/passwd`

In `mnt/pen` create a directory `media` for Plex to use as source
