FROM curlimages/curl:8.11.1@sha256:c1fe1679c34d9784c1b0d1e5f62ac0a79fca01fb6377cdd33e90473c6f9f9a69

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

ENTRYPOINT ["/home/curl_user/elastic-init.sh"]