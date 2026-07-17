FROM curlimages/curl:8.21.0@sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13

USER root
RUN apk add --no-cache bash jq

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

RUN chmod +x elastic-init.sh

# Dedicated, explicitly-owned working directory for downloading/extracting the
# ontology archive. Using /tmp for this is unreliable: on some Docker Desktop
# for Windows setups, bind-mounting a single file into /tmp (see
# docker-compose.yml) resets that directory's permissions and breaks writes
# for the non-root container user.
RUN mkdir -p /work && chown 10001:0 /work && chmod 0770 /work
WORKDIR /work


USER 10001

ENTRYPOINT ["bash", "/home/curl_user/elastic-init.sh"]