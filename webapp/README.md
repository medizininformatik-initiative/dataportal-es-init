# Web UI (no Docker required)

A tiny Flask app that runs `../elastic-init.sh` directly as a subprocess and
streams its output to the browser. It supports the same "download from repo"
mode as the Docker image, plus a "upload zip file" mode for providing a local
archive without mounting a fixed path into a container.

## Requirements

- Python 3.9+
- `bash`, `curl`, `jq`, `unzip` available on `PATH` (same tools the script
  already needs inside the Docker image)
- Network access to the target Elasticsearch instance

## Run

```bash
cd webapp
pip install -r requirements.txt
python app.py
```

Then open http://127.0.0.1:5000.

Form defaults are pre-filled from the same `ELASTIC_INIT_*` environment
variables used by `docker-compose.yml` / `.env` (see the main README).

## Optional access control

This tool deletes and recreates Elasticsearch indices, so if it's reachable
beyond localhost, set a password to gate it behind HTTP Basic Auth:

```bash
WEBAPP_PASSWORD=changeme python app.py
```

## Notes

- "Upload zip file" mode saves the upload to a temporary working directory
  and passes it to the script via `MOUNTED_FILENAME_OVERRIDE`, which
  `elastic-init.sh` falls back to `/work/mounted_onto.zip` when unset — so
  the Docker image's behavior is unchanged.
- Each run gets its own temp working directory, cleaned up afterwards.
