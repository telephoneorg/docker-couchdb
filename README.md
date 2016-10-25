# CouchDB 2.0

![docker automated build](https://img.shields.io/docker/automated/callforamerica/couchdb.svg) ![docker pulls](https://img.shields.io/docker/pulls/callforamerica/couchdb.svg)

## Maintainer

Joe Black <joe@valuphone.com>

## Introduction

CouchDB 2.0 for use in a kubernetes pod.

Now using a register-service init-container for automatic registration/clustering with the cluster

[todo] more intro


## Environments

### Build

### Run


## Instructions

### Docker

[todo]

### Kubernetes

* Create the necessary secrets listed in `couchdb-petset.yaml`
* Create the PersistentVolumes in `couchdb-pvs.yaml`
* Create the PersistentVolumeClaims in `couchdb-pvcs.yaml`
* Create the Service in `couchdb-service.yaml`
* Create the petset in `couchdb-service.yaml`


## Issues

### Docker.hub automated builds don't tolerate COPY or ADD to root /

I've added a comment to the Dockerfile noting this and for now am copying to
/tmp and then copying to / in the next statement.

ref: https://forums.docker.com/t/automated-docker-build-fails/22831/28

## Todos