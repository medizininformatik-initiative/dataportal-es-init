FROM curlimages/curl:8.21.0@sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13

USER root
RUN apk add --no-cache bash jq

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

RUN chmod +x elastic-init.sh

USER 10001

ENTRYPOINT ["bash", "/home/curl_user/elastic-init.sh"]