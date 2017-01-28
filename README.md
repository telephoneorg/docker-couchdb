# CouchDB 2.0 (stable) for Kubernetes w/ manifests

[![Build Status](https://travis-ci.org/sip-li/docker-couchdb.svg?branch=master)](https://travis-ci.org/sip-li/docker-couchdb) [![Docker Pulls](https://img.shields.io/docker/pulls/callforamerica/couchdb.svg)](https://store.docker.com/community/images/callforamerica/couchdb)

## Maintainer

Joe Black <joeblack949@gmail.com>

## Description

Minimal image with a sidecar container that performs automatic cluster initialization.  This image uses a custom version of Debian Linux (Jessie) that I designed weighing in at ~22MB compressed.

## Build Environment

Build environment variables are often used in the build script to bump version numbers and set other options during the docker build phase.  Their values can be overridden using a build argument of the same name.

* `ERLANG_VERSION`
* `COUCHDB_VERSION`

The following variables are standard in most of our dockerfiles to reduce duplication and make scripts reusable among different projects:

* `APP`: couchdb
* `USER`: couchdb
* `HOME` /opt/couchdb


## Run Environment

Run environment variables are used in the entrypoint script to render configuration templates, perform flow control, etc.  These values can be overridden when inheriting from the base dockerfile, specified during `docker run`, or in kubernetes manifests in the `env` array.

### `couchdb` container:

* `ERLANG_THREADS`: used as the value for the `+A` argument in `vm.args`.  Defaults to `25`.
* `COUCHDB_LOG_LEVEL`: lowercased and used as the value for the level in the `log` section of `local.ini`.  Defaults to `info`.
* `COUCHDB_DATA_PATH`: used as the value for 'database_dir` and `view_index_dir` in the `couchdb` section of `local.ini`.  Defaults to `/data/$APP`.
* `COUCHDB_BIND_ADDR`: used as the value for `bind_address` in the `chttpd` and `httpd` sections of `local.ini`.  Defaults to ``.
* `COUCHDB_REQUIRE_VALID_USER`: used as the value for `require_valid_user` in the `chttpd` and `httpd` sections of `local.ini`.  Defaults to `false`.
* `COUCHDB_SHARDS`: used as the value for `q` in the `cluster` section of `local.ini`.  Defaults to `4`.
* `COUCHDB_READ_QUORUM`: used as the value for `r` in the `cluster` section of `local.ini`.  Defaults to `1`.
* `COUCHDB_WRITE_QUORUM`: used as the value for `w` in the `cluster` section of `local.ini`.  Defaults to `1`.
* `COUCHDB_REPLICAS`: used as the value for `n` in the `cluster` section of `local.ini`.  Defaults to `1`.
* `LOCAL_DEV_CLUSTER`: when value is `true`, will trigger the couch-helper in the entrypoint script before starting couchdb.  Inject as true into the environment when running a simple single node dev cluster that should immediately auto-initialize.  Defaults to `false`.
* `COUCHDB_ADMIN_USER`,`COUCHDB_ADMIN_PASS`: when set this will be available to the sidecar container `couchdiscover` and the script `couch-helper`. Your cluster will be auto initialized using these credentials. `couch-helper` is meant to be used for local single node clusters for development.
* `ERLANG_COOKIE`: when set this value will be written to ~/.erlang.cookie and proper permissions applied prior to starting couchdb.
* `COUCHDB_CLUSTER_SIZE`: when set this value override the value of the replica's field on the kubernetes statefulset manifest. Do not use unless you really need to override the default behavior for some reason.

### `couchdiscover` container:
* `LOG_LEVEL`: logging level to output container logs for.  Defaults to `INFO`, most logs are either INFO or WARNING level.

## Usage

### Under docker (manual-build)

If building and running locally, feel free to use the convenience targets in the included `Makefile`.

* `make build`: rebuilds the docker image.
* `make launch`: launch for testing.
* `make logs`: tail the logs of the container.
* `make shell`: exec's into the docker container interactively with tty and bash shell.
* `make test`: test's the launched container.
* *and many others...*


### Under docker (pre-built)

All of our docker-* repos in github have CI pipelines that push to docker cloud/hub.  

This image is available at:
* [https://store.docker.com/community/images/callforamerica/couchdb](https://store.docker.com/community/images/callforamerica/couchdb)
*  [https://hub.docker.com/r/callforamerica/couchdb](https://hub.docker.com/r/callforamerica/couchdb).

and through docker itself: `docker pull callforamerica/couchdb`

To run:

```bash
docker run -d \
    --name couchdb \
    -h couchdb.local \
    callforamerica/couchdb
```

**NOTE:** Please reference the Run Environment section for the list of available environment variables.


### Under Kubernetes

Edit the manifests under `kubernetes/` to reflect your specific environment and configuration.

Create a secret for the erlang cookie:
```bash
kubectl create secret generic erlang-cookie --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

Create a secret for the couchdb credentials:
```bash
kubectl create secret generic couchdb-creds --from-literal=couchdb.user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=couchdb.pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

Deploy couchdb:
```bash
kubectl create -f kubernetes
```

## `couchdiscover`

For the kubernetes manifests, there is a sidecar container called couchdiscover that handles initializing the cluster.

In order to best use something that is essentially "zero configuration," it helps to understand how the necessary information is obtained from the environment and api's.

### How `couchdiscover` discovers information

1. Initially a great deal of information is obtained by grabbing the hostname of the container that's part of a StatefulSet and parsing it.  This is how the namespace is determined, how hostnames are calculated later, the name of the StatefulSet to look for in the api, the name of the headless service, the node name, the index, whether a node is master or not, etc.

2. The kubernetes api is used to grab the StatefulSet and Endpoint objects. The Endpoint object is parsed to obtain the `hosts` list.  Then the StatefulSet is parsed for the ports, then the environment is resolved, fetching any externally referenced ConfigMaps or Secrets that are necessary.  Credentials are resolved by looking through the environment of the `couchdb` container for the keys: `COUCHDB_ADMIN_USER`, `COUCHDB_ADMIN_PASS`.  Finally the expected cluster size is set to the number of replicas in the fetched StatefulSet.  You can override this by setting this environment variable manually, but should be completely unnecessary for most cases.

### Main logic

The main logic is performed in the `manage` module's `ClusterManager` object's `run` method.  I think most of it is relatively straighforward.

```python
# couchdiscover.manage.ClusterManager
def run(self):
    """Main logic here, this is where we begin once all environment
    information has been retrieved."""
    log.info('Starting couchdiscover: %s', self.couch)
    if self.couch.disabled:
        log.info('Cluster disabled, enabling')
        self.couch.enable()
    elif self.couch.finished:
        log.info('Cluster already finished')
        self.sleep_forever()

    if self.env.first_node:
        log.info("Looks like I'm the first node")
        if self.env.single_node_cluster:
            log.info('Single node cluster detected')
            self.couch.finish()
    else:
        log.info("Looks like I'm not the first node")
        self.couch.add_to_master()
        if self.env.last_node:
            log.info("Looks like I'm the last node")
            self.couch.finish()
        else:
            log.info("Looks like I'm not the last node")
    self.sleep_forever()
```


## Issues

**ref:**  [https://github.com/sip-li/docker-couchdb/issues](https://github.com/sip-li/docker-couchdb/issues)
