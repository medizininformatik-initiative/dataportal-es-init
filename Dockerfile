FROM curlimages/curl:8.11.0@sha256:83a505ba2ba62f208ed6e410c268b7b9aa48f0f7b403c8108b9773b44199dbba

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

ENTRYPOINT ["/home/curl_user/elastic-init.sh"]