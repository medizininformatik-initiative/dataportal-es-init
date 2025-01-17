# FHIR Ontology Generator Docker Image

This project provides a Docker image designed to download and deploy the elastic search files generated in the [FHIR Ontology Generator](https://github.com/medizininformatik-initiative/fhir-ontology-generator).

## Project Purpose

The primary purpose of this project is to automate the setup of the Elasticsearch Service used by the [Dataportal Backend](https://github.com/medizininformatik-initiative/feasibility-backend).

## Requirements

- **Docker**: Ensure Docker is installed and running on your system.
- **Elasticsearch**: A running instance of Elasticsearch to receive the index definitions and documents. The REST api of the elasticsearch instance must be reachable from within this container

## Usage

To use this Docker image, follow these steps:

1. **Clone the Project**:
   ```bash
   git clone https://github.com/medizininformatik-initiative/dataportal-es-init
   cd dataportal-es-init
   ```

2. **Build the Docker Image**:
   ```bash
   docker build -t dataportal-es-init .
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
              -e EXIT_ON_EXISTING_INDICES=false \
              dataportal-es-init
   ```

## Environment Variables

The Docker image supports several environment variables for configuration. The only variables that **must not** be omitted are `MODE`  and `ONTO_GIT_TAG` if mode is download or `LOCAL_PATH` if mode is local, the others come with default values:

- `MODE`: Can either be `mount` or `download`. When set to mount, `LOCAL_PATH` **must** be set, when set to download, `ONTO_GIT_TAG` **must** be set.
- `LOCAL_PATH`: Path on the local filesystem where the needed archive can be found.
- `ES_HOST`: The hostname or IP address of the Elasticsearch instance (default: `127.0.0.1`). Please note that the host must - for obvious reasons - be reachable from within this container. In case you are just using it for local purposes, set `--network host` in your docker run command or compose file and use 127.0.0.1 . In that case, the elasticsearch port 9200 must be mapped to the host machine as well.
- `ES_PORT`: The port Elasticsearch is running on (default: `9200`).
- `ONTO_GIT_TAG`: The tag of the [FHIR Ontology Generator](https://github.com/medizininformatik-initiative/fhir-ontology-generator) files to use.
- `ONTO_REPO`: Base URL to the ontology generator repository (default: `https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download`). Please do **NOT** enter a trailing slash since it will be inserted in the script.
- `DOWNLOAD_FILENAME`: The filename to get (default: `elastic.zip`)
- `EXIT_ON_EXISTING_INDEX`: If set to true, the container will shut down without doing anything if at least one of both indices (`ontology` and `codeable_concept`) exists (default: false)

## Examples

A minimal example to run would be the following. Please see the description of the `ES_HOST` variable in the section above regarding the `--network host` setting. Feel free to remove this if your elasticsearch instance is otherwise reachable from within this container.

### Downloading from GitHub

```bash
docker run --network host \
           -e MODE=download \
           -e ONTO_GIT_TAG=v3.0.1 \
           ghcr.io/medizininformatik-initiative/dataportal-es-init:latest
```
which would be equivalent to

```bash
docker run --network host \
           -e MODE=download \
           -e ES_HOST=http://127.0.0.1 \
           -e ES_PORT=9200 \
           -e ONTO_GIT_TAG=v3.0.1 \
           -e ONTO_REPO=https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download \
           -e DOWNLOAD_FILENAME=elastic.zip \
           -e EXIT_ON_EXISTING_INDICES=false \
           dataportal-es-init
```

### Providing a local archive file via mount

```bash
docker run --network host \
           -e MODE=mount \
           -e LOCAL_PATH=/home/foobar/myarchive.zip \
           ghcr.io/medizininformatik-initiative/dataportal-es-init:latest
```



