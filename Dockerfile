FROM curlimages/curl:8.13.0@sha256:d43bdb28bae0be0998f3be83199bfb2b81e0a30b034b6d7586ce7e05de34c3fd

WORKDIR /home/curl_user
COPY ./elastic-init.sh elastic-init.sh

ENTRYPOINT ["/home/curl_user/elastic-init.sh"]