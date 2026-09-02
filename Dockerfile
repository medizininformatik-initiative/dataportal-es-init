FROM curlimages/curl:8.22.0@sha256:58adaa4e8dca9c988bae2aba4ab3434a0bb2da16bbe3f92dec39ec7785166777

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