echo::header "Installing deps for test in container $NAME ..."
docker exec $NAME bash -l -c "apt-get update -qqy && apt-get install -qqy jq > /dev/null"


echo::header "Application Tests for $NAME ..."

echo::test "couchdb is running"
docker exec $NAME bash -l -c "ps aux | grep -v grep | grep -q beam.smp"
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "epmd is running"
docker exec $NAME bash -l -c "ps aux | grep -v grep | grep -q epmd"
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

for db in _global_changes _metadata _replicator _users; do
    echo::test "couchdb database: $db exists"
    docker exec $NAME bash -l -c "curl -s -u admin:secret http://localhost:5984/$db | jq -r '.db_name' | grep $db"
    if (($? == 0)); then
        echo::success "ok"
    else
        echo::fail "not ok"
        exit 1
    fi
done

for db in _dbs _nodes _replicator _users; do
    echo::test "couchdb database: $db exists"
    docker exec $NAME bash -l -c "curl -s -u admin:secret http://localhost:5986/$db | jq -r '.db_name' | grep $db"
    if (($? == 0)); then
        echo::success "ok"
    else
        echo::fail "not ok"
        exit 1
    fi
done

echo::test "couchdb is version 2.0"
docker exec $NAME bash -l -c 'curl -s http://localhost:5984 | jq -r ".version" | grep -q ^2.0'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "couchdb 'demo' db does not exist"
docker exec $NAME bash -l -c 'curl -s -u admin:secret http://localhost:5984/demo | jq -r ".reason" | grep -q "Database does not exist."'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "couchdb 'demo' db was successfully created"
docker exec $NAME bash -l -c 'curl -s -u admin:secret -X PUT http://localhost:5984/demo | jq -r ".ok" | grep -q true'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "couchdb 'demo' db was successfully exists"
docker exec $NAME bash -l -c 'curl -s -u admin:secret http://localhost:5984/demo | jq -r ".db_name" | grep -q demo'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "couchdb 'demo' db document 'test' does not exist"
docker exec $NAME bash -l -c 'curl -s -u admin:secret http://localhost:5984/demo/test | jq -r ".error" | grep -q not_found'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "couchdb 'demo' db document 'test' was successfully created"
docker exec $NAME bash -l -c 'curl -s -u admin:secret -X POST -H "Content-Type: application/json" --data "{\"_id\": \"test\", \"test\": true}" http://localhost:5984/demo | jq -r ".ok" | grep -q true'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo::test "couchdb 'demo' db document 'test' has test: true"
docker exec $NAME bash -l -c 'curl -s -u admin:secret http://localhost:5984/demo/test | jq -r ".test" | grep -q true'
if (($? == 0)); then
    echo::success "ok"
else
    echo::fail "not ok"
    exit 1
fi

echo >&2
