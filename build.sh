#!/bin/bash

set -e

app=couchdb
user=$app


# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $user ..."
useradd --system --home-dir ~ --create-home --shell=/bin/false --user-group $user


echo "Installing erlang and $app repos ..."
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > /etc/apt/sources.list.d/erlang.list


echo "Installing essentials ..."
apt-get update
apt-get install -y curl


echo "Calculating versions ..."
apt_erlang_version=$(apt-cache show erlang-nox | grep ^Version | grep $ERLANG_VERSION | sort -n | head -1 | awk '{print $2}')
echo "erlang: $apt_erlang_version"


echo "Installing dependencies ..."
apt-get -y install \
    build-essential \
    erlang=$apt_erlang_version \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-dev \
    pkg-config


echo "Downloading $app ..."
mkdir -p /tmp/couchdb
cd $_
    curl -sSL \
        http://apache.mesi.com.ar/couchdb/source/${COUCHDB_VERSION}/apache-couchdb-${COUCHDB_VERSION}.tar.gz | \
        tar xzf - --strip-components=1 -C .
        
    echo "Compiling $app ..."
    ./configure --user $user --disable-docs
    make release
    cd rel/couchdb
        find . -type d -exec mkdir -p ~/\{} \;
        find . -type f -exec mv \{} ~/\{} \;
        cd ../..
    cd / && rm -rf $OLDPWD


echo "Purging unneeded ..."
apt-get purge -y --auto-remove \
    build-essential \
    ca-certificates \
    erlang \
    libcurl4-openssl-dev \
    libicu-dev \
    pkg-config

apt-get install -y libicu52


echo "Creating volume directories ..."
mkdir -p /data/$app


echo "Setting Ownership & Permissions ..."
chown -R $user:$user ~ /data/$app
find ~ -type d -exec chmod 0770 {} \;

chmod 0644 ~/etc/*
chmod +x ~/bin/*


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
