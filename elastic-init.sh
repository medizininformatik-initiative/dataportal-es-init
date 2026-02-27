#!/bin/bash

# Compare function from https://stackoverflow.com/a/44660519

# Compares two dot-delimited decimal-element version numbers a and b that may
# also have arbitrary string suffixes. Compatible with semantic versioning, but
# not as strict: comparisons of non-semver strings may have unexpected
# behavior.
#
# Returns:
# 1 if a<b
# 2 if equal
# 3 if a>b
compare_versions() {
    local LC_ALL=C

    # Optimization
    if [[ $1 == "$2" ]]; then
        return 2
    fi

    # Compare numeric release versions. Supports an arbitrary number of numeric
    # elements (i.e., not just X.Y.Z) in which unspecified indices are regarded
    # as 0.
    local aver=${1%%[^0-9.]*} bver=${2%%[^0-9.]*}
    local arem=${1#$aver} brem=${2#$bver}
    local IFS=.
    local i a=($aver) b=($bver)
    for ((i=0; i<${#a[@]} || i<${#b[@]}; i++)); do
        if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
            return 1
        elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
            return 3
        fi
    done

    # Remove build metadata before remaining comparison
    arem=${arem%%+*}
    brem=${brem%%+*}

    # Prelease (w/remainder) always older than release (no remainder)
    if [ -n "$arem" -a -z "$brem" ]; then
        return 1
    elif [ -z "$arem" -a -n "$brem" ]; then
        return 3
    fi

    # Otherwise, split by periods and compare individual elements either
    # numerically or lexicographically
    local a=(${arem#-}) b=(${brem#-})
    for ((i=0; i<${#a[@]} && i<${#b[@]}; i++)); do
        local anns=${a[i]#${a[i]%%[^0-9]*}} bnns=${b[i]#${b[i]%%[^0-9]*}}
        if [ -z "$anns$bnns" ]; then
            # Both numeric
            if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
                return 1
            elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
                return 3
            fi
        elif [ -z "$anns" ]; then
            # Numeric comes before non-numeric
            return 1
        elif [ -z "$bnns" ]; then
            # Numeric comes before non-numeric
            return 3
        else
            # Compare lexicographically
            if [[ ${a[i]} < ${b[i]} ]]; then
                return 1
            elif [[ ${a[i]} > ${b[i]} ]]; then
                return 3
            fi
        fi
    done

    # Fewer elements is earlier
    if (( ${#a[@]} < ${#b[@]} )); then
        return 1
    elif (( ${#a[@]} > ${#b[@]} )); then
        return 3
    fi

    # Must be equal!
    return 2
}

normalize_version() {
  echo "$1" | sed 's/^v//'
}

HOST="${ES_HOST:-http://127.0.0.1}:${ES_PORT:-9200}"
REPO="${ONTO_REPO:-https://github.com/medizininformatik-initiative/fhir-ontology-generator/releases/download}"
FILENAME="${DOWNLOAD_FILENAME:-elastic.zip}"
MOUNTED_FILENAME=/tmp/mounted_onto.zip
MODE=download

echo "Init container for elastic search - v 1.2.1"

if [ -f $MOUNTED_FILENAME ]; then
  echo "Mounted file found. Not downloading anything but using the mounted file. If you want to download instead, remove the mounted volume and/or file."
  MODE=mount
elif [ -z "$ONTO_GIT_TAG" ]; then
    echo "No mounted file found and no ONTO_GIT_TAG provided. Exiting..."
    exit 1
else
  echo "Downloading ${ONTO_GIT_TAG}"
fi

# Wait for Elasticsearch to start up before doing anything
until curl -X GET "$HOST/_cluster/health" | grep -q '"status":"green"\|"status":"yellow"'; do
    echo "Waiting for Elasticsearch..."
    sleep 5
done

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

if [[ -z "$FORCE_REINSTALL" || "${FORCE_REINSTALL,,}" != "true" ]]; then
  # Compare the version of the installed ontology with the downloaded or provided one.
  # If the installed one is newer, exit here unless FORCE_REINSTALL is set to true. In that case ignore everything
  # version-related
  # There should never be a case where the version of ontology and codeable_concept indices differ. So only ontology is
  # checked here. Maybe there will be an edge case some day that is not covered here.
  CURRENT_VERSION=$(curl -s "$HOST/ontology" | jq -r '.ontology.mappings._meta.version')
  PROVIDED_VERSION=$(< elastic/ontology_index.json jq -r '.mappings._meta.version')
  V1=$(normalize_version "$CURRENT_VERSION")
  V2=$(normalize_version "$PROVIDED_VERSION")

  compare_versions "$V1" "$V2"
  comparison_result=$?
  case $comparison_result in
      1) op='<';;
      2) op='=';;
      3) op='>';;
  esac
  echo "$CURRENT_VERSION $op $PROVIDED_VERSION"
  if [[ $comparison_result -gt 1 ]]; then
    echo "The installed version is newer than the one you are trying to install. If you want to force a reinstall, set FORCE_REINSTALL to true. Exiting."
    exit 0
  fi
else
  echo "FORCE_REINSTALL is set to true. Not comparing versions, just deleting and reinstalling."
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
