# private helpers

function couch::_get-ports {
    if cat ~/etc/local.ini | grep -q ^port; then
        cat ~/etc/local.ini | grep ^port | awk '{print $3}' | head -2 | xargs
    elif cat ~/etc/default.ini | grep -q ^port; then
        cat ~/etc/default.ini | grep ^port | awk '{print $3}' | head -2 | xargs
    else:
        echo '5984 5986'
    fi
}

function couch::_get-port {
    couch::_get-ports | xargs -n1 | sort -n | head -1
}

function couch::_get-host {
    echo 'localhost'
}

function couch::_get-hostname {
    echo "$(couch::_get-host):$(couch::_get-port)"
}

function couch::_create_http_url {
    local hostname="$1"
    echo "http://$hostname"
}

function couch::_unauth_curl {
    local url=$(couch::get-uri)
    if [[ -n $uri ]]; then
        url+="$uri"
    fi
    if [[ -z $method ]]; then
        local method=GET
    fi
    curl -s $args -H 'Content-Type: application/json' -X "$method" "$url" --data "$payload"
}

function couch::_curl {
    if couch::creds-in-env && couch::_early-is-enabled; then
        local url=$(couch::get-auth-uri)
    else
        local url=$(couch::get-uri)
    fi
    if [[ -n $uri ]]; then
        url+="$uri"
    fi
    if [[ -z $method ]]; then
        local method=GET
    fi
    curl -s $args -H 'Content-Type: application/json' -X "$method" "$url" --data "$payload"
}

function couch::_parse-state {
    while read -r line; do
        if [[ $line =~ unauthorized ]]; then
            echo 'unauthorized'
        else
            echo "$line" | sed 's/{"state":"\(.*\)"}/\1/' | awk -F_ '{print $NF}'
        fi
    done
}

function couch::_parse-cluster-setup-resp {
    while read -r line; do
        if [[ $line =~ ok ]]; then
            echo "$line" | sed 's/{"ok":"\(.*\)"}/\1/'
        elif [[ $line =~ bad_request ]]; then
            if [[ $line =~ 'Cluster is already finished' || $line =~ 'Cluster is already enabled' ]]; then
                sleep 2
                echo 'true'
            else
                echo "unknown response: $line"
            fi
        fi
    done
}

function couch::_return-silent {
    while read -r line; do
        if [[ $line =~ true ]]; then
            return 0
        elif [[ $line =~ false ]]; then
            return 1
        else
            echo "unknown response: $line"
            return 1
        fi
    done
}

function couch::_parse_db_test {
    while read -r line; do
        if [[ $line =~ not_found ]]; then
            echo 'false'
        elif [[ $line =~ db_name ]]; then
            echo 'true'
        else
            echo "unknown response: $line"
        fi
    done
}

# public helpers

function couch::get-creds {
    if couch::creds-in-env; then
        echo "${COUCHDB_ADMIN_USER}:${COUCHDB_ADMIN_PASS}"
    fi
}

function couch::get-uri {
    couch::_create_http_url $(couch::_get-hostname)
}

function couch::get-auth-uri {
    local hostname=$(couch::_get-hostname)
    local uri=
    if couch::creds-in-env; then
        uri+="$(couch::get-creds)@"
    fi
    uri+=$hostname
    couch::_create_http_url "$uri"
}

function couch::get-status {
    local uri='/_cluster_setup'
    couch::_curl | couch::_parse-state
}

# tests
function couch::is-local-dev-cluster {
    [[ $COUCHDB_DEV_INIT = true ]]
}

function couch::creds-in-env {
    [[ ! -z ${COUCHDB_ADMIN_USER} && ! -z ${COUCHDB_ADMIN_PASS} ]]
}

function couch::_early-is-enabled {
    local uri='/_cluster_setup'
    local status=$(couch::_unauth_curl | couch::_parse-state)
    [[ $status = enabled || $status = finished || $status = unauthorized ]]
}

function couch::is-enabled {
    [[ $(couch::get-status) = enabled || $(couch::get-status) = finished ]]
}

function couch::is-disabled {
    [[ $(couch::get-status) = disabled ]]
}

function couch::is-finished {
    [[ $(couch::get-status) = finished ]]
}

function couch::is-not-finished {
    ! couch::is-finished
}

function couch::is-unauthorized {
    [[ $(couch::get-status) = unauthorized ]]
}

function couch::is-authorized {
    ! couch::is-unauthorized
}

function couch::is-up {
    local args='--connect-timeout 2'
    couch::_curl > /dev/null 2>&1  --fail
}

function couch::health-check {
    local uri='/_up'
    couch::_curl
}

function couch::system-dbs-exist {
    local uri='/_users'
    couch::_curl | couch::_parse_db_test | couch::_return-silent
}

function couch::is-missing-system-dbs {
    ! couch::system-dbs-exist
}

# actions

function couch::finish-cluster {
    local method='POST'
    local uri='/_cluster_setup'
    local payload='{"action": "finish_cluster"}'
    couch::_curl | couch::_parse-cluster-setup-resp | couch::_return-silent
}

function couch::enable-cluster {
    local payload="{\"action\": \"enable_single_node\", \"username\": \"$COUCHDB_ADMIN_USER\", \"password\": \"$COUCHDB_ADMIN_PASS\", \"singlenode\": true}"
    local uri='/_cluster_setup'
    local method='POST'
    couch::_curl | couch::_parse-cluster-setup-resp | couch::_return-silent
}
