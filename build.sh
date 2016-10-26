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


# this script handles annoying post-init tasks automatically,
echo "Creating node init script"
tee ~/init-node.sh <<'EOF'
#!/bin/bash

: ${COUCHDB_ADMIN_USER:=admin}
: ${COUCHDB_ADMIN_PASS:=secret}

this="$0"
host=http://localhost:5984
shost=http://$COUCHDB_ADMIN_USER:$COUCHDB_ADMIN_PASS@localhost:5984

function finish
{
    shred -u $this > /dev/null 2>&1
}

function host_up
{
    local host="$1"
    curl -sS $host --connect-timeout 2 --head --fail > /dev/null 2>&1
}

function enable_cluster
{
    local host="${1:-$host}"
    curl -sS -X POST $host/_cluster_setup -H "Content-Type: application/json" -d "{\"action\": \"enable_cluster\", \"username\": \"$COUCHDB_ADMIN_USER\", \"password\": \"$COUCHDB_ADMIN_PASS\"}" > /dev/null 2>&1
}

function finish_cluster
{
    local secure=${1:-false}
    [[ $secure = true ]] && local host=$shost
    curl -sS -X POST $shost/_cluster_setup -H 'Content-Type: application/json' -d '{"action": "finish_cluster"}' > /dev/null 2>&1
}

until host_up $host
do
    sleep 1
done

enable_cluster $host
finish_cluster $shost

rm -f ~/.init-node > /dev/null 2>&1
trap finish EXIT
sleep 1
EOF
chmod +x $_
touch ~/.init-node


# this script handles registering the node with master if REGISTER_NODE=true
# echo "Creating node init script"
# tee ~/register-node.sh <<'EOF'
# #!/bin/bash

# service=couchdb
# volume_path=/volumes/$service/$(env hostname -s)
# log_file=$volume_path/logs/register-service.log

# : ${COUCHDB_ADMIN_USER:=admin}
# : ${COUCHDB_ADMIN_PASS:=secret}

# function log 
# {
#     local msg="$1"
#     local msg="\E[36m[*]\E[0m $(date) : ${msg}"
#     echo -e "register-node: $msg"
#     # echo -e "$msg" >> $log_file
# }

# function errlog
# {
#     local msg="$1"
#     local msg="\E[31m[x]\E[0m $(date) : ${msg}"
#     echo -e "register-node: $msg"
#     # echo -e "$msg" >> $log_file
# }

# function host_up
# {   
#     local host="$1"
#     curl $host --connect-timeout 2 --head --fail $host
# }

# function get_num_nodes_for_service
# {
#     local service="$1"
#     dig +short +search -t srv $service | wc -l
# }

# function get_nodes_for_service
# {
#     local service="$1"
#     local nodes=$(dig +short +search -t srv $service | awk '{print $4}' | sed 's/.$//')
#     echo "$nodes"
# }

# function get_first_node_for_service
# {
#     local service="$1"
#     local node=$(dig +short +search -t srv $service | awk '{print $4}' | sed 's/.$//' | sort | head -n 1)
#     echo "$node"
# }

# function register_couchdb
# {
#     local master_host=http://$COUCHDB_ADMIN_USER:$COUCHDB_ADMIN_PASS@$(get_first_node_for_service $service)
#     local this_host=$(hostname -f)
    
#     until host_up $this_host:5984
#     do
#         sleep 1
#     done

#     sleep 10
    
#     log "Adding $this_host > $master_host using user: $COUCHDB_ADMIN_USER, pass: $COUCHDB_ADMIN_PASS"
#     results=$(curl -sSL -X POST $master_host:5984/_cluster_setup \
#         -H 'Content-Type: application/json' \
#         -d "{\"action\": \"add_node\", \"host\": \"$this_host\", \"username\": \"$COUCHDB_ADMIN_USER\", \"password\": \"$COUCHDB_ADMIN_PASS\"}" 2>&1)
#     if [[ $? ]]
#     then
#         log "$results"
#         sleep 5
#     else
#         errlog "$results"
#     fi
# }

# function clean_exit
# {
#     rm -f ~/.register-node > /dev/null 2>&1
#     trap finish EXIT
# }

# function finish
# {
#     shred -u $this > /dev/null 2>&1
# }

# # If not registering node exit clean now
# [[ $REGISTER_NODE -ne true ]] && clean_exit

# # Make sure dirs and log file exists
# [[ ! -d $volume_path/logs ]] && mkdir -p $volume_path/logs
# [[ ! -f $log_file ]] && touch $log_file

# num_nodes=$(get_num_nodes_for_service $service)
# log "Node $num_nodes for $service"

# if (( $num_nodes > 0 ))
# then
#     log "Not the first node for $service, registering with leader ..."
#     register_couchdb
# else
#     log "First node in cluster. skipping registration"
# fi

# clean_exit
# sleep 1
# EOF

# chmod +x $_
# touch ~/.register-node


echo "Creating volume directories ..."
mkdir -p /volumes/$app /data/$app


echo "Setting Ownership & Permissions ..."
chown -R $user:$user ~ /volumes/$app /data/$app
find ~ -type d -exec chmod 0770 {} \;

chmod 0644 ~/etc/*
chmod +x ~/bin/*


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
