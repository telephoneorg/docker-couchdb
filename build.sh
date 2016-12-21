#!/bin/bash

set -e

readonly APP=couchdb
readonly USER=$APP

function get_apt_version() {
    local app=${1:-$app}
    local vvar=${2:-$app}; vvar=${vvar^^}_VERSION
    local version=${!vvar}
    apt-cache madison $app | awk '{print $3}' | grep $version | sort -rn | head -1
}

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $USER ..."
useradd --system --home-dir ~ --create-home --shell=/bin/false --user-group $USER


echo "Installing erlang repos ..."
apt-key adv --keyserver pgp.mit.edu --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > /etc/apt/sources.list.d/erlang.list
apt-get update


echo "Installing essentials ..."
apt-get install -y curl

echo "Calculating versions ..."
readonly apt_erlang_version=$(get_apt_version erlang)
echo "erlang: $apt_erlang_version"


echo "Installing dependencies ..."
apt-get install -y \
    erlang=$apt_erlang_version \
    build-essential \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-dev \
    pkg-config


echo "Downloading $APP ..."
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
apt-get purge -y --auto-remove \
    build-essential \
    ca-certificates \
    erlang \
    libcurl4-openssl-dev \
    libicu-dev \
    pkg-config

apt-get install -y libicu52


echo "Adding bash profile hook to write erlang cookie ..."
tee /etc/profile.d/80-write-erlang-cookie.sh <<EOF
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump
EOF


echo "Creating directories and files ..."
mkdir -p /volumes/$APP/{data,dumps}
mkdir -p /data
ln -s /volumes/$APP/data /data/$APP


echo "Setting Ownership & Permissions ..."
chown -R $USER:$USER ~ /volumes/$APP/{data,dumps} /data

find ~ -type d -exec chmod 0770 {} \;
chmod 0777 /volumes/$APP/dumps
chmod 0644 ~/etc/*


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
