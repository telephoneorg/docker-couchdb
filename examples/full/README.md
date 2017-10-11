# docker-couchdb
## full example
A full example of deploying CouchDB 2.0 with the `couchdiscover` sidecar in Kubernetes.


## Requirements
* Kubernetes 1.5+ *(Couchdiscover 0.2.3+ Supports Kubernetes 1.5+, use 0.2.2 for older compatibility)*


## Usage
There are four parts to this example:

1. Generating credentials such as erlang cookie and couchdb creds.
2.  `couchdb-config.yaml`
    * Provides the configuration for the couchdb StatefulSet.
3. `couchdb-headless-service.yaml`
    * The headless Service that provides service discovery.
    * *Required for proper dns resolution*
4. `couchdb-balanced-service.yaml`
    * Provides a load balanced ClusterIP for the couchdb service.
5. `couchdb-statefulset.yaml`
    * The StatefulSet that manages the kubernetes pods.
6. `couchdb-statefulset.yaml`
    * The StatefulSet that manages the kubernetes pods.


### Usage Example
erlang cookie:
```bash
kubectl create secret generic erlang --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

couchdb credentials:
```bash
kubectl create secret generic couchdb --from-literal=couchdb.user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=couchdb.pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

Deploy couchdb:

```bash
kubectl create -f kubernetes
```
