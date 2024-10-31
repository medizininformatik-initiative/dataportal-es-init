FROM curlimages/curl:8.10.1@sha256:d9b4541e214bcd85196d6e92e2753ac6d0ea699f0af5741f8c6cccbfcf00ef4b

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

ENTRYPOINT ["/home/curl_user/elastic-init.sh"]