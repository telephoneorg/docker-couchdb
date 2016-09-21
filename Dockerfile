FROM debian:jessie

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="debian" \
        os.version="jessie"

LABEL   lang.name="erlang" \
        lang.version="17.3"

LABEL   app.name="couchdb" \
        app.version="2.0.0"

ENV     ERLANG_VERSION=17.3 \
        COUCHDB_VERSION=2.0.0 \
        GOSU_VERSION=1.9

ENV     HOME=/opt/couchdb
ENV     PATH=$HOME/bin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     COUCHDB_LOG_LEVEL=info

VOLUME  ["/opt/couchdb/data"]

EXPOSE  4369 5984 5986 11500-11999

# USER    couchdb

WORKDIR /opt/couchdb

CMD     ["/usr/bin/entrypoint"]
