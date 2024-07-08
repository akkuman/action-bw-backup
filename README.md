# Bitwarden Backup To WebDAV

## Importance

If you use jianguoyun, your WEBDAV_ENDPOINT should be setted to 'https://dav.jianguoyun.com/dav' instead of 'https://dav.jianguoyun.com/dav/'

The main reason is because opendal will add '/' in front of root, and the endpoint combination will become 'https://dav.jianguoyun.com/dav//rootpath/'
