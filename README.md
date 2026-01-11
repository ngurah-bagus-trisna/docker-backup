# 🐳 Docker Label-Based Backup (Restic Edition)

> by nb.trisna + gemini :)

This is a modular Bash-based backup solution designed for Docker environments. It uses **Docker Labels** for service discovery, **Rsync** for staging local configurations/volumes, and **Restic** for secure, deduplicated offsite storage (e.g., Google Drive via Rclone).

## ✨ Key Features

* **Label-Driven Discovery**: No manual lists. Just add a label to your `compose.yml`, and the script finds it.
* **Smart Project Syncing**: Specifically designed for services like **Traefik**. It automatically syncs the entire project directory (YAMLs, `.env`, `.json` certs, dynamic configs).
* **Database Awareness**: Native support for atomic `mysqldump` and `pg_dumpall`.
* **Deduplication & Encryption**: Powered by Restic to save space and secure your data.
* **DR Ready**: Backs up `docker inspect` metadata to help rebuild containers from scratch on a fresh OS.

## 📁 Directory Structure

```text
docker-backup/
├── backup.sh          # Entrypoint script
├── restore.sh         # Restoration & DR script
├── config.sh          # Path & Repository configurations
├── README.md          # Documentation
└── lib/
    ├── utils.sh       # Logging and dependency checks
    ├── docker.sh      # Logic for discovery, DB dumps, and project sync
    └── restic.sh      # Restic repository management

```

## 🛠️ Prerequisites

Ensure the following tools are installed on your host:

* `docker` & `jq`
* `rsync`
* `restic`
* `rclone` (configured with a remote, e.g., `gdrive:`)

## 🚀 Initial Setup

1. **Restic Password**:
Create a password file to allow non-interactive backups:

```bash
echo "your_secure_password" > /etc/restic.pass
chmod 600 /etc/restic.pass

```

2. **Configure Paths**:
Open `config.sh` and set your `BACKUP_ROOT`. If you are using Rclone, ensure your GDrive is mounted at this path or modify `restic.sh` to use the `rclone:remote:path` syntax.
3. **Initialize Repository**:
The script will automatically run `restic init` if the repository doesn't exist.

## 🏷️ Usage (Labeling Strategy)

To include a container in the backup, add labels to your `docker-compose.yml`:

| Label | Value | Description |
| --- | --- | --- |
| `backup.enable` | `true` | **Required**. Enables backup for this container. |
| `backup.type` | `volume` | Default. Backs up Named Volumes and Project Dir. |
| `backup.type` | `mysql` | Executes `mysqldump` inside the container. |
| `backup.type` | `postgres` | Executes `pg_dumpall` inside the container. |

---

## 🏃 Running the Backup

**Manual Run:**

```bash
sudo ./backup.sh

```

**Automated (Cron):**
Run every day at 2 AM:

```bash
0 2 * * * /opt/docker-backup/backup.sh >> /var/log/docker-backup.log 2>&1

```

---

## 🔄 Restoration & Recovery

### Add `r-check` to manage restic

```sh
export REPO="rclone:<your-config>:backup-docker"
export PW="/etc/restic.pass"

# Alias untuk mempermudah
alias r-check="restic -r $REPO -p $PW"
```

### 1. Using the Automated Script

The `restore.sh` script is designed for quick recovery. It will list all snapshots and let you choose which one to restore.

```bash
sudo ./restore.sh

```

### 2. Manual Recovery (The "Swiss Army Knife")

If you need to restore specific files without the script:

* **List all snapshots:** `restic snapshots`
* **Browse files in a snapshot:** `restic ls <SNAPSHOT_ID>`
* **Restore a specific folder:** 

```bash
restic restore <SNAPSHOT_ID> --target /tmp/recovery --include "/projects/my-app"
```


### 3. Disaster Recovery (Fresh Machine)

If your server is gone and you are starting on a new one:

1. **Install dependencies**: Docker, Restic, and Rclone.
2. **Mount your Storage**: Mount your Google Drive via Rclone to the path defined in `config.sh`.
3. **Run Restore**: Execute `./restore.sh` to pull all files to a temporary directory.
4. **Re-deploy**:
* Move the restored project folders to their original locations.
* Start the database container.
* Import the SQL dump: `docker exec -i <db_container> mysql -u root -p < restored_dump.sql`.
* Run `docker-compose up -d`.



---

## 🛡️ Disaster Recovery (DR) Layout

When you browse your Restic snapshots, the data is organized as follows:

* `/projects/<project_name>/`: Your `compose.yml`, `.env`, and all local config files.
* `/db/<container_name>/`: SQL dump files.
* `/volumes/<volume_name>/`: Raw data from named volumes.
* `/metadata/<container_name>/`: The `inspect.json` file containing environment variables, network settings, and labels.

---

### Pro-Tip for your Traefik setup:

Since you are using `rclone` to GDrive, I highly recommend using the **Restic Rclone Integration** directly in `config.sh` instead of a FUSE mount if you notice stability issues:

```bash
export RESTIC_REPOSITORY="rclone:gdrive:backups/my-server"

```
