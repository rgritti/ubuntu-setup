# ubuntu-setup
scripts to initialize ubuntu with Plex and Home Assistant

## Step 1
Add the nas driver to `/etc/fstab`

Add the following line to fstab:

```
/dev/disk/by-uuid/675B-2137       /mnt/pen      exfat   auto
```
Make sure the the uuid is correct by finding your drive under `sudo blkid`

In `mnt/pen` create a directory `media` for Plex to use as source
