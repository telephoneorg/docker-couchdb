FROM telephoneorg/debian:stretch

MAINTAINER Joe Black <me@joeblack.nyc>

ARG     COUCHDB_VERSION
ARG     COUCHDB_RC
ARG     COUCHDB_CHECK_RELEASE

ENV     COUCHDB_VERSION=${COUCHDB_VERSION:-2.1.0}
ENV     COUCHDB_RC=${COUCHDB_RC:-}
ENV     COUCHDB_CHECK_RELEASE=${COUCHDB_CHECK_RELEASE:-false}

LABEL   app.couchdb.version=$COUCHDB_VERSION
LABEL   app.couchdb.rc=${COUCHDB_RC:-false}

ENV     APP couchdb
ENV     USER $APP
ENV     HOME /opt/$APP

COPY    build.sh /tmp/
RUN     /tmp/build.sh

COPY    50-couchdb-functions.sh /etc/profile.d/
COPY    couchdb-dev /usr/local/bin/

COPY    entrypoint /
COPY    goss /goss

ENV     ERL_MAX_PORTS 65536
ENV     COUCHDB_LOG_LEVEL info

ENV     COUCHDB_DEV_INIT=true

EXPOSE  5984 5986

VOLUME  ["/volumes/couchdb/data", "/config"]

WORKDIR $HOME

SHELL       ["/bin/bash", "-lc"]
HEALTHCHECK --interval=15s --timeout=5s CMD goss -g /goss/goss.yaml validate

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
