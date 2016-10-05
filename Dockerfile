FROM callforamerica/debian

MAINTAINER joe <joe@valuphone.com>

LABEL   lang.name="erlang" \
        lang.version="19.1"

LABEL   app.name="couchdb" \
        app.version="2.0.0"

ENV     ERLANG_VERSION=19.1 \
        COUCHDB_VERSION=2.0.0

ENV     HOME=/opt/couchdb

COPY    build.sh /tmp/build.sh
RUN     /tmp/build.sh

COPY    entrypoint /entrypoint
COPY    post-init.sh /tmp/post-init.sh

ENV     COUCHDB_LOG_LEVEL=info

VOLUME  ["/volumes/couchdb"]

EXPOSE  4369 5984 5986 11500-11999

# USER    couchdb

WORKDIR /opt/couchdb

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
