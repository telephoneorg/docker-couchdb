# CouchDB 2.0

CouchDB 2.0 for use in a kubernetes pod.

Now using a register-service init-container for automatic registration with the cluster

## Directions

* Create the necessary secrets listed in `couchdb-petset.yaml`
* Create the PersistentVolumes in `couchdb-pvs.yaml`
* Create the PersistentVolumeClaims in `couchdb-pvcs.yaml`
* Create the Service in `couchdb-service.yaml`
* Create the petset in `couchdb-service.yaml`
