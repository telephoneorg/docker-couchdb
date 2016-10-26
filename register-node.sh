#!/bin/bash

service=couchdb
volume_path=/volumes/$service/$(env hostname -s)
log_file=$volume_path/logs/register-service.log

: ${COUCHDB_ADMIN_USER:=admin}
: ${COUCHDB_ADMIN_PASS:=secret}

function log 
{
    local msg="$1"
    local msg="\E[36m[*]\E[0m $(date) : ${msg}"
    echo -e "register-node: $msg"
    # echo -e "$msg" >> $log_file
}

function errlog
{
    local msg="$1"
    local msg="\E[31m[x]\E[0m $(date) : ${msg}"
    echo -e "register-node: $msg"
    # echo -e "$msg" >> $log_file
}

function host_up
{   
    local host="$1"
    curl $host --connect-timeout 2 --head --fail $host
}

function get_num_nodes_for_service
{
    local service="$1"
    dig +short +search -t srv $service | wc -l
}

function get_nodes_for_service
{
    local service="$1"
    local nodes=$(dig +short +search -t srv $service | awk '{print $4}' | sed 's/.$//')
    echo "$nodes"
}

function get_first_node_for_service
{
    local service="$1"
    local node=$(dig +short +search -t srv $service | awk '{print $4}' | sed 's/.$//' | sort | head -n 1)
    echo "$node"
}

function register_couchdb
{
    local master_host=http://$COUCHDB_ADMIN_USER:$COUCHDB_ADMIN_PASS@$(get_first_node_for_service $service)
    local this_host=$(hostname -f)
    
    until host_up $this_host:5984
    do
        sleep 1
    done
    
    log "Adding $this_host > $master_host using user: $COUCHDB_ADMIN_USER, pass: $COUCHDB_ADMIN_PASS"
    results=$(curl -sSL -X POST $master_host:5984/_cluster_setup \
        -H 'Content-Type: application/json' \
        -d "{\"action\": \"add_node\", \"host\": \"$this_host\", \"username\": \"$COUCHDB_ADMIN_USER\", \"password\": \"$COUCHDB_ADMIN_PASS\"}" 2>&1)
    if [[ $? ]]
    then
        log "$results"
        sleep 5
    else
        errlog "$results"
    fi
}

function clean_exit
{
    rm -f ~/.register-node > /dev/null 2>&1
    trap finish EXIT
}

function finish
{
    shred -u $this > /dev/null 2>&1
}

# If not registering node exit clean now
[[ $REGISTER_NODE -ne true ]] && clean_exit

# Make sure dirs and log file exists
[[ ! -d $volume_path/logs ]] && mkdir -p $volume_path/logs
[[ ! -f $log_file ]] && touch $log_file

num_nodes=$(get_num_nodes_for_service $service)
log "Node $num_nodes for $service"

if (( $num_nodes > 0 ))
then
    log "Not the first node for $service, registering with leader ..."
    register_couchdb
else
    log "First node in cluster. skipping registration"
fi

clean_exit
sleep 1