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
              -e FORCE_INDEX_CREATION=false \
              dataportal-es-init
   ```

## Environment Variables

The Docker image supports several environment variables for configuration. The only variable that **must not** be omitted is `ONTO_GIT_TAG`, the others come with default values:

- `ES_HOST`: The hostname or IP address of the Elasticsearch instance (default: `127.0.0.1`). Please note that the host must - for obvious reasons - be reachable from within this container. In case you are just using it for local purposes, set `--network host` in your docker run command or compose file and use 127.0.0.1 . In that case, the elasticsearch port 9200 must be mapped to the host machine as well.
- `ES_PORT`: The port Elasticsearch is running on (default: `9200`).
- `ONTO_GIT_TAG`: The tag of the [FHIR Ontology Generator](https://github.com/medizininformatik-initiative/fhir-ontology-generator) files to use.
- `ONTO_REPO`: Base URL to the ontology generator repository (default: `https://github.com/medizininformatik-initiative/fhir-ontology-generator/raw/`).
- `ONTO_RELATIVE_PATH`: The path to the elastic search files inside the repository (default: `/example/fdpg-ontology/`) 
- `DOWNLOAD_FILENAME`: The filename to get (default: `elastic.zip`)
- `EXIT_ON_EXISTING_INDEX`: If set to true, the container will shut down without doing anything if at least one of both indices (`ontology` and `codeable_concept`) exists (default: true)
- `FORCE_INDEX_CREATION`: If set to true, both indices are deleted in the beginning (if they exist). Will be ignored if `EXIT_ON_EXISTING_INDICES` is set to true and at least one of the indices is existing (default: false)

## Examples

A minimal example to run would be the following. Please see the description of the `ES_HOST` variable in the section above regarding the `--network host` setting. Feel free to remove this if your elasticsearch instance is otherwise reachable from within this container.

```bash
docker run --network host \
           -e ONTO_GIT_TAG=v3.0.0-alpha \
           ghcr.io/medizininformatik-initiative/dataportal-es-init:feature-1-create-es-init-container
```

which would be equivalent to

```bash
docker run --network host \
           -e ES_HOST=http://127.0.0.1 \
           -e ES_PORT=9200 \
           -e ONTO_GIT_TAG=v3.0.0-alpha \
           -e ONTO_REPO=https://github.com/medizininformatik-initiative/fhir-ontology-generator/raw/ \
           -e ONTO_RELATIVE_PATH=/example/fdpg-ontology/ \
           -e DOWNLOAD_FILENAME=elastic.zip \
           -e EXIT_ON_EXISTING_INDICES=false \
           -e FORCE_INDEX_CREATION=false \
           dataportal-es-init
```