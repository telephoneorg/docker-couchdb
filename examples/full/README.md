# docker-couchdb
## full example
A full example of deploying CouchDB 2.x with the `couchdiscover` sidecar in Kubernetes.


## Requirements
* Kubernetes 1.5+ *(Couchdiscover 0.2.3+ Supports Kubernetes 1.5+, use 0.2.2 for older compatibility)*


## Usage
There are several parts to this example:
1. Generating the secrets for erlang cookie and couchdb.
2. `config.yaml`: configuration for the couchdb statefulset.
3. `service.yaml`: headless Service that provides service discovery. *Required for proper service/peer discovery*
4. `service-lb.yaml`: load-balanced service for couchdb
5. `statefulset.yaml`: statefulset that manages the kubernetes pods
6. `templates.yaml`: runtime configuration templates for couchdb.


### Usage Example
Generate the secrets:
```bash
kubectl create secret generic erlang --from-literal=cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
kubectl create secret generic couchdb --from-literal=user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

Deploy couchdb:
```bash
kubectl create -f .
```
