FROM curlimages/curl:8.20.0@sha256:b3f1fb2a51d923260350d21b8654bbc607164a987e2f7c84a0ac199a67df812a

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