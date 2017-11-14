#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER


log::m-info "Installing dependencies ..."
apt_packages=(
    build-essential
    ca-certificates
    erlang
    libcurl4-openssl-dev
    libicu-dev
    libmozjs185-dev
    pkg-config
)

apt-get update -qq
apt-get install -qqy ${apt_packages[@]} curl


# Add the following keys
gpg --recv-key 118F1A7C 43ECCEE1 DF3CEBA3 04F4EE9B 30380381 7852AEE4


log::m-info "Installing $APP $COUCHDB_VERSION $COUCHDB_RC ..."
if [ ! -z $COUCHDB_RC ]; then
    COUCHDB_DOWNLOAD_URL=https://dist.apache.org/repos/dist/dev/couchdb/source/${COUCHDB_VERSION}/rc.${COUCHDB_RC}/apache-couchdb-${COUCHDB_VERSION}-RC${COUCHDB_RC}.tar.gz
else
    COUCHDB_DOWNLOAD_URL=https://dist.apache.org/repos/dist/release/couchdb/source/${COUCHDB_VERSION}/apache-couchdb-${COUCHDB_VERSION}.tar.gz
fi

mkdir -p /tmp/couchdb
pushd $_
    curl -SL -O \
        $COUCHDB_DOWNLOAD_URL && \
        gpg --no-tty --verify <(curl -s ${COUCHDB_DOWNLOAD_URL}.asc) apache-couchdb-*.tar.gz && \
        sha256sum --check <(curl -s ${COUCHDB_DOWNLOAD_URL}.sha256 | sed 's/SHA-256/SHA256/' | sed 's/\.2/-2/' | tr -d '\r') --status
        tar xzvf apache-couchdb-*.tar.gz --strip-components=1

        log::m-info "Compiling $APP ..."
        ls -la
        pwd
        ./configure --user $USER --disable-docs

    # ref https://cwiki.apache.org/confluence/display/COUCHDB/Testing+a+Source+Release
    if [[ $COUCHDB_CHECK_RELEASE == true ]]; then
        DISTCHECK_CONFIGURE_FLAGS="--user $USER --disable-docs" make check
    fi

    make release
    pushd rel/couchdb
        find . -type d -exec mkdir -p ~/\{} \;
        find . -type f -exec mv \{} ~/\{} \;
        popd
    popd && rm -rf $OLDPWD


log::m-info "Installing couchdb-admin ..."
pushd /tmp
    curl -LO https://github.com/cabify/couchdb-admin/releases/download/$COUCHDB_ADMIN_VERSION/couchdb-admin
    chmod +x couchdb-admin
    mv couchdb-admin /usr/bin


log::m-info "Purging unneeded packages ..."
apt-get purge -qqy --auto-remove ${apt_packages[@]}
apt-get install -qq -y libicu57 libmozjs185-dev


log::m-info "Adding app init to bash profile ..."
tee /etc/entrypoint.d/50-${APP}-init <<'EOF'
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump

if linux::cap::is-enabled 'sys_resource'; then
    echo "setting ulimits ..."
    set-limits couchdb
else
    linux::cap::show-warning 'sys_resource'
fi

if linux::cap::is-disabled 'sys_nice'; then
    linux::cap::show-warning 'sys_nice'
fi
EOF


log::m-info "Creating data directories ..."
mkdir -p /volumes/$APP/{data,backups} /data /config
ln -s /volumes/$APP/data /data/$APP


log::m-info "Adding /etc/kazoo to fixattrs.d ..."
tee /etc/fixattrs.d/20-${APP}-perms <<EOF
~/etc/ true $USER:$USER 0644 0755
/volumes/couchdb/data true $USER:$USER 0755 0755
/volumes/couchdb/backups true $USER:$USER 0755 0755
/config true $USER:$USER 0755 0755
EOF


log::m-info "Setting Ownership & Permissions ..."
chown -R $USER:$USER ~ /volumes/$APP/{data,backups} /data /config

find ~ -type d -exec chmod 0770 {} \;
chmod 0777 /volumes/$APP/{data,backups} /data /config
chmod 0644 ~/etc/*


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
