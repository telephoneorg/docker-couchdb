# docker-couchdb
## minimal example
A minimal example of deploying CouchDB 2.x with the `couchdiscover` sidecar in Kubernetes.

Keep in mind that this example doesn't use persistent volumes, dynamic volume provisioning, and doesn't create a load balanced service such as in the full example.


## Requirements
* Kubernetes 1.5+ *(Couchdiscover 0.2.3+ Supports Kubernetes 1.5+)*


## Usage
There are two parts to this example:
1. `couchdb-headless-service.yaml`
    * The headless Service that provides service discovery.
    * *Required for proper dns resolution*
2. `couchdb-statefulset.yaml`
    * The StatefulSet that manages the Kubernetes pods.


### Usage Example
```bash
kubectl create -f examples/basic
```
