#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER

log::m-info "Installing erlang repo ..."
build::apt::add-key 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > \
    /etc/apt/sources.list.d/erlang.list
apt-get -q update


log::m-info "Installing essentials ..."
apt-get install -qq -y curl


log::m-info "Installing $APP ..."
apt_erlang_vsn=$(build::apt::get-version erlang)

log::m-info "apt versions: erlang: $apt_erlang_vsn"
apt-get install -qq -y \
    erlang=$apt_erlang_vsn \
    build-essential \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-dev \
    pkg-config


log::m-info "Downloading $APP ..."
mkdir -p /tmp/couchdb
pushd $_
    curl -sSL \
        http://apache.mesi.com.ar/couchdb/source/${COUCHDB_VERSION}/apache-couchdb-${COUCHDB_VERSION}.tar.gz \
            | tar xzf - --strip-components=1 -C .

    echo "Compiling $APP ..."
    ./configure --user $USER --disable-docs
    make release
    pushd rel/couchdb
        find . -type d -exec mkdir -p ~/\{} \;
        find . -type f -exec mv \{} ~/\{} \;
        popd
    popd && rm -rf $OLDPWD


echo "Purging unneeded ..."
apt-get purge -qq -y --auto-remove \
    build-essential \
    ca-certificates \
    erlang \
    libcurl4-openssl-dev \
    libicu-dev \
    pkg-config

apt-get install -qq -y libicu52


log::m-info "Adding $APP environment to bash profile ..."
echo /path >> /etc/paths.d/20-${APP}


log::m-info "Adding app init to bash profile ..."
tee /etc/entrypoint.d/50-${APP}-init <<'EOF'
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump
EOF


log::m-info "Cleaning up unnecessary files ..."
mkdir -p /volumes/$APP/{data,dumps}
mkdir -p /data
ln -s /volumes/$APP/data /data/$APP


log::m-info "Setting Ownership & Permissions ..."
chown -R $USER:$USER ~ /volumes/$APP/{data,dumps} /data

find ~ -type d -exec chmod 0770 {} \;
chmod 0777 /volumes/$APP/dumps
chmod 0644 ~/etc/*


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
