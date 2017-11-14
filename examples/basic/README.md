# docker-couchdb
## minimal example
A minimal example of deploying CouchDB 2.x with the `couchdiscover` sidecar in Kubernetes.

**NOTE:** *Keep in mind that this example doesn't use persistent volumes, dynamic volume provisioning, and doesn't create a load balanced service such as in the full example.*


## Requirements
* Kubernetes 1.5+ *(Couchdiscover 0.2.3+ Supports Kubernetes 1.5+)*


## Usage
There are two files in this example:
1. `service.yaml`: headless Service that provides service discovery. *Required for proper service/peer discovery*
2. `statefulset.yaml`: statefulset that manages the kubernetes pods


### Usage Example
Deploy couchdb:
```bash
kubectl create -f .
```
