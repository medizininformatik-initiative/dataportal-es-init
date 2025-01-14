#!/bin/sh

HOST="${ES_HOST:-http://127.0.0.1}:${ES_PORT:-9200}"
REPO="${ONTO_REPO:-https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download}"
FILENAME="${DOWNLOAD_FILENAME:-elastic.zip}"
MOUNTED_FILENAME=/tmp/mounted_onto.zip

if [ -z "$MODE" ]; then
  echo "Mode MUST be specified. Set to either local or download. There is no default value to be assumed here."
  exit 1
fi

if [ "$MODE" = "mount" ]; then
  if [ ! -f $MOUNTED_FILENAME ]; then
    echo "In local mode, LOCAL_PATH MUST be provided and actually contain a zip file"
    exit 1
  fi
elif [ "$MODE" = "download" ]; then
    if [ -z "$ONTO_GIT_TAG" ]; then
      echo "In download mode, ONTO_GIT_TAG MUST be provided"
      exit 1
    fi
else
    echo "Unknown mode. Must be either mount or download"
    exit 1
fi

# Wait for Elasticsearch to start up before doing anything
until curl -X GET "$HOST/_cluster/health" | grep -q '"status":"green"\|"status":"yellow"'; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

if [ "$EXIT_ON_EXISTING_INDICES" = "true" ]; then
  echo "Checking if ontology or codeable_concept index is existing"
  status_code_ontology=$(curl -o /dev/null -s -w "%{http_code}" "$HOST/ontology")
  status_code_cc=$(curl -o /dev/null -s -w "%{http_code}" "$HOST/codeable_concept")
  if [ "$status_code_ontology" -ne 404 ] || [ "$status_code_cc" -ne 404 ]; then
    echo "At least one index is existing, and the script is configured to quit in this case. See EXIT_ON_EXISTING_INDEX and FORCE_INDEX_CREATION if you want to override this."
    exit 0
  else
    echo "Neither ontology nor codeable_concept index exists. Download zip file and create indices."
  fi
fi

if [ "$MODE" = "download" ]; then
  ABSOLUTE_FILEPATH="${REPO}/${ONTO_GIT_TAG}/${FILENAME}"
  echo "Downloading $ABSOLUTE_FILEPATH"
  response_onto_dl=$(curl --write-out "%{http_code}" -sLO "$ABSOLUTE_FILEPATH")

  if [ "$response_onto_dl" -ne 200 ]; then
    echo "Could not download ontology file. Maybe the tag $ONTO_GIT_TAG does not exist? Error code was $response_onto_dl"
    exit 1
  fi

  unzip -o "$FILENAME"
else
  unzip -o "$MOUNTED_FILENAME"
fi


echo "(Trying to) delete existing indices"
curl --request DELETE "$HOST/ontology"
curl --request DELETE "$HOST/codeable_concept"

echo "Creating ontology index..."
response_onto=$(curl --write-out "%{http_code}" -s --output /dev/null -XPUT -H 'Content-Type: application/json' "$HOST/ontology" -d @elastic/ontology_index.json)
echo "${response_onto}"
echo "Creating codeable concept index..."
response_cc=$(curl --write-out "%{http_code}" -s --output /dev/null -XPUT -H 'Content-Type: application/json' "$HOST/codeable_concept" -d @elastic/codeable_concept_index.json)
echo "${response_cc}"
echo "Done"

for FILE in elastic/*; do
  if [ -f "$FILE" ]; then
    BASENAME=$(basename "$FILE")
    if [[ $BASENAME == onto_es__ontology* && $BASENAME == *.json ]]; then
      echo "Uploading $BASENAME"
      response_upload=$(curl --write-out "%{http_code}" -s --output /dev/null -XPOST -H 'Content-Type: application/json' --data-binary @"$FILE" "$HOST/ontology/_bulk")
      echo "${response_upload}"
    fi
    if [[ $BASENAME == onto_es__codeable_concept* && $BASENAME == *.json ]]; then
      echo "Uploading $BASENAME"
      response_upload=$(curl --write-out "%{http_code}" -s --output /dev/null -XPOST -H 'Content-Type: application/json' --data-binary @"$FILE" "$HOST/codeable_concept/_bulk")
      echo "${response_upload}"
    fi
  fi
done

echo "All done"
exit 0
