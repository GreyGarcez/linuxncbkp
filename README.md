# linuxncbkp
bash scripts to backup a nextcloud server and piwigo server on linux ubuntu

The backup is done dayly with BorgBackup on a local folder on the server.
I use rclose to sync this folder to BackBlaze and have a last resource copy on the cloud.

There is also a manual backup that is done once a week to a USB drive.

---

My scripts are based on these posts:
> - [Building Your Own Encrypted Cloud Backup System for Linux](https://medium.com/@mormesher/building-your-own-linux-cloud-backup-system-75750f47d550)
> - [Kev blog](https://kevq.uk/how-to-backup-nextcloud/)
> - [Documentação Nextcloud](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)

---
