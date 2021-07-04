# Nextcloud and Piwigo backup on linux

bash scripts to backup a nextcloud server and piwigo server on linux ubuntu.

For the nextcloud backup the folders config, themes and data are copied and I also dump a copy of the database.
For piwigo, I only save the dump of the database, since all files are already in the data folder of nextcloud.

The backup is done daily with BorgBackup on a local folder on the server. The automation is done by a simple cron task that calls the bash script.

I use rclone to sync the borg repo folder to BackBlaze and have a last resource copy on the cloud. This is also another cron task.

I will also leave here the script for a manual backup that I try to do once a week to a USB drive. The script is almost the same as the previous one.

---

My scripts are based on these posts:

> - [Building Your Own Encrypted Cloud Backup System for Linux](https://medium.com/@mormesher/building-your-own-linux-cloud-backup-system-75750f47d550)
> - [Kev blog](https://kevq.uk/how-to-backup-nextcloud/)
> - [Documentação Nextcloud](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)

---
