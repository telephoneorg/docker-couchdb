FROM callforamerica/debian

MAINTAINER joe <joe@valuphone.com>

ARG     ERLANG_VERSION
ARG     COUCHDB_VERSION

ENV     ERLANG_VERSION=${ERLANG_VERSION:-19.2} \
        COUCHDB_VERSION=${COUCHDB_VERSION:-2.0.0}

LABEL   lang.erlang.version=$ERLANG_VERSION
LABEL   app.rabbitmq.version=$RABBITMQ_VERSION

ENV     HOME=/opt/couchdb

COPY    build.sh /tmp/build.sh
RUN     /tmp/build.sh

COPY    50-couch-functions.sh /etc/profile.d/
COPY    couch-helper /usr/local/bin/

COPY    entrypoint /entrypoint

ENV     COUCHDB_LOG_LEVEL=info

VOLUME  ["/volumes/couchdb/data"]

EXPOSE  4369 5984 5986

# USER    couchdb

WORKDIR /opt/couchdb

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
