Since you're managing professional IT infrastructure and looking for a 
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

### Example Implementations

#### 1. Traefik (Configs & Bind Mounts)

Traefik usually relies on local files. Because the script detects the `working_dir`, it will grab everything in the folder.

```yaml
services:
  traefik:
    image: traefik:v2.10
    volumes:
      - ./certs:/certs
      - ./provider.yaml:/etc/traefik/provider.yaml
    labels:
      - "backup.enable=true"

```

#### 2. Database (Logical Dump)

```yaml
services:
  db:
    image: mariadb:10.11
    environment:
      - MYSQL_ROOT_PASSWORD=my-secret
    labels:
      - "backup.enable=true"
      - "backup.type=mysql"

```

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