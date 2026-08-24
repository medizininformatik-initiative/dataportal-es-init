# Elasticsearch Initialization

This project provides a Docker image designed to download and deploy the elastic search files generated in the [FHIR Ontology Generator](https://github.com/medizininformatik-initiative/fhir-ontology-generator).

## Project Purpose

The primary purpose of this project is to automate the setup of the Elasticsearch Service used by the [Dataportal Backend](https://github.com/medizininformatik-initiative/feasibility-backend).

## Requirements

- **Docker**: Ensure Docker is installed and running on your system.
- **Elasticsearch**: A running instance of Elasticsearch to receive the index definitions and documents. The REST api of the elasticsearch instance must be reachable from within this container
- Ontology version v4.0.0 or later. Previous versions don't provide their version number in the indices. If you need to run on older versions, please use version 1.x.x of THIS tool

## Usage

To use this Docker image, follow these steps:

1. **Clone the Project**:
   ```bash
   git clone https://github.com/medizininformatik-initiative/dataportal-es-init
   cd dataportal-es-init
   ```

2. **Build the Docker Image**:
   ```bash
   docker build -t dataportal-es-init:latest .
   ```

3. **Run the Docker Container**:

   Either use the docker-compose file and .env file provided or use the following command to start the container. Customize environment variables as needed.
   ```bash
   docker run -e ES_HOST=<elasticsearch_host> \
              -e ES_PORT=<elasticsearch_port> \
              -e ONTO_GIT_TAG=<onto_git_tag> \
              -e ONTO_REPO=<onto_repo> \
              -e ONTO_RELATIVE_PATH=<onto_relative_path> \
              -e DOWNLOAD_FILENAME=<download_filename> \
              -e FORCE_REINSTALL=false \
              dataportal-es-init:latest
   ```

## Running the script directly (no Docker)

`elastic-init.sh` doesn't actually need the container — it just needs
`bash`, `curl`, `jq` and `unzip` on `PATH`, and the same environment
variables the Docker image sets. Run it from a scratch working directory
(it downloads/extracts into the current directory):

```bash
mkdir -p /tmp/es-init-run && cd /tmp/es-init-run

ES_HOST=http://127.0.0.1 \
ES_PORT=9200 \
ONTO_GIT_TAG=v4.0.0 \
bash /path/to/dataportal-es-init/elastic-init.sh
```

To use a local zip file instead of downloading one, point
`MOUNTED_FILENAME_OVERRIDE` at it (this is what the web UI's upload mode
does under the hood) instead of setting `ONTO_GIT_TAG`:

```bash
ES_HOST=http://127.0.0.1 \
ES_PORT=9200 \
MOUNTED_FILENAME_OVERRIDE=/home/foo/my-ontology.zip \
bash /path/to/dataportal-es-init/elastic-init.sh
```

Add `FORCE_REINSTALL=true` to either command to skip the version check and
always delete/recreate the indices.

## Web UI (alternative to Docker)

For local/manual use, there's also a tiny Flask web UI that runs
`elastic-init.sh` directly — no Docker build required — and lets you either
provide a git tag to download or upload a zip archive directly from the
browser. See [`webapp/README.md`](webapp/README.md) for setup and usage.

## Environment Variables

The Docker image supports several environment variables for configuration. The only variables that **must not** be omitted are `MODE`  and `ONTO_GIT_TAG` if mode is download or `LOCAL_PATH` if mode is local, the others come with default values:

- `ES_HOST`: The hostname or IP address of the Elasticsearch instance (default: `127.0.0.1`). Please note that the host must - for obvious reasons - be reachable from within this container. In case you are just using it for local purposes, set `--network host` in your docker run command or compose file and use 127.0.0.1 . In that case, the elasticsearch port 9200 must be mapped to the host machine as well.
- `ES_PORT`: The port Elasticsearch is running on (default: `9200`).
- `ONTO_GIT_TAG`: The tag of the [FHIR Ontology Generator](https://github.com/medizininformatik-initiative/fhir-ontology-generator) files to use.
- `ONTO_REPO`: Base URL to the ontology generator repository (default: `https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download`). Please do **NOT** enter a trailing slash since it will be inserted in the script.
- `DOWNLOAD_FILENAME`: The filename to get (default: `elastic.zip`)
- `FORCE_REINSTALL`: If set to true, both indices in the elasticsearch container will be deleted and freshly created from the files in the downloaded (or provided) zip file.
- `UPLOAD_PARALLELISM`: How many content files are bulk-uploaded to Elasticsearch concurrently (default: `8`). Benchmarked against a real ontology v5.0.0 dataset (~340 bulk files, ~1.9GB) on a single-node ES instance: sequential uploads took ~270s, 8 concurrent uploads took ~133s (~2x faster), while 16 concurrent uploads was slower than 8 (~192s) due to contention. Tune this to your Elasticsearch instance's capacity.

## Examples

A minimal example to run would be the following. Please see the description of the `ES_HOST` variable in the section above regarding the `--network host` setting. Feel free to remove this if your elasticsearch instance is otherwise reachable from within this container.

### Downloading from GitHub

This is the default setting. Provide the git tag of the ontology you want to download (or override the source url as well)

```bash
docker run --network host \
           -e ONTO_GIT_TAG=v4.0.0 \
           ghcr.io/medizininformatik-initiative/dataportal-es-init:latest
```
which would be equivalent to

```bash
docker run --network host \
           -e ES_HOST=http://127.0.0.1 \
           -e ES_PORT=9200 \
           -e ONTO_GIT_TAG=v4.0.0 \
           -e ONTO_REPO=https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download \
           -e DOWNLOAD_FILENAME=elastic.zip \
           -e FORCE_REINSTALL=false \
           dataportal-es-init:latest
```

### Providing a local archive file via mount

In case you want to use a local file on your machine instead of downloading from GitHub (or elsewhere), you must mount a valid zip file to `/work/mounted_onto.zip` in the container. This filename is fixed.
**Important since v2**: Make sure that your locally provided file also contains the version information in the _meta part of the indices. Or set `FORCE_REINSTALL` to true to always delete and reinstall the indices.

```bash
docker run --network host \
           --mount type=bind,src=/home/foo/my-ontology.zip,dst=/work/mounted_onto.zip,ro \
           ghcr.io/medizininformatik-initiative/dataportal-es-init:latest
```

or add an equivalent section to your `docker-compose.yml` in case you use docker compose.

e.g.

```yaml
    volumes:
      - type: bind
        source: /home/foo/my-ontology.zip
        target: /work/mounted_onto.zip
        read_only: true
```


