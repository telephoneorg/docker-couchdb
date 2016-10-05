#!/bin/bash

set -e 

: ${COUCHDB_ADMIN_USER:=admin}
: ${COUCHDB_ADMIN_PASS:=secret}

host=http://localhost:5984
shost=http://$COUCHDB_ADMIN_USER:$COUCHDB_ADMIN_PASS@localhost:5984
# silent_opts="--output /dev/null --silent"

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

touch ~/.cluster-initialized

exit 0