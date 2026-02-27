FROM curlimages/curl:8.18.0@sha256:d94d07ba9e7d6de898b6d96c1a072f6f8266c687af78a74f380087a0addf5d17

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

ENTRYPOINT ["/home/curl_user/elastic-init.sh"]