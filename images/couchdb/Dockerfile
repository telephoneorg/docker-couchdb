FROM telephoneorg/debian:stretch

MAINTAINER Joe Black <me@joeblack.nyc>

ARG     COUCHDB_VERSION
ARG     COUCHDB_RC
ARG     COUCHDB_CHECK_RELEASE
ARG     COUCHDB_ADMIN_VERSION

ENV     COUCHDB_VERSION=${COUCHDB_VERSION:-2.1.1}
ENV     COUCHDB_RC=${COUCHDB_RC:-}
ENV     COUCHDB_CHECK_RELEASE=${COUCHDB_CHECK_RELEASE:-false}
ENV     COUCHDB_ADMIN_VERSION=${COUCHDB_ADMIN_VERSION:-0.1.0}

LABEL   app.couchdb.version=$COUCHDB_VERSION
LABEL   app.couchdb.rc=${COUCHDB_RC:-false}
LABEL   app.couchdb-admin.version=$COUCHDB_ADMIN_VERSION

ENV     APP couchdb
ENV     USER $APP
ENV     HOME /opt/$APP

WORKDIR $HOME
SHELL   ["/bin/bash", "-lc"]

COPY    build.sh /tmp/
RUN     /tmp/build.sh

COPY    50-couchdb-functions.sh /etc/profile.d/
COPY    couchdb-dev /usr/local/bin/

COPY    couchdb.limits.conf /etc/security/limits.d/
COPY    entrypoint /
COPY    goss /goss

ENV     COUCHDB_LOG_LEVEL info
ENV     COUCHDB_DEV_INIT=false

EXPOSE  5984 5986

VOLUME  ["/volumes/couchdb/data", \
         "/volumes/couchdb/data/indexes", \
         "/volumes/couchdb/backups", \
         "/config"]

HEALTHCHECK --interval=15s --timeout=5s CMD goss -g /goss/goss.yaml validate

ENTRYPOINT  ["/dumb-init", "--"]
CMD     ["/entrypoint"]
