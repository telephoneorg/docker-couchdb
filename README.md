# CouchDB 2.0

![docker automated build](https://img.shields.io/docker/automated/callforamerica/couchdb.svg) ![docker pulls](https://img.shields.io/docker/pulls/callforamerica/couchdb.svg)


## Maintainer

Joe Black <joe@valuphone.com>


## Introduction

CouchDB 2.0 for use in a kubernetes pod.

Now using a CouchDiscover sidecar container to do autoclustering of CouchDB 2.0 under Kubernetes.


## Usage

Create a secret to hold the couchdb credentials.  
*Names and keys don't matter here as long as they match those used in the petset spec* 
Use and modify the the following commands to generate the base64 encoded data needed for this step.

```bash
# base64 encode a username
echo -n admin | base64
# generate and base64 encode a password
python -c 'import os,base64; print base64.b64encode(os.urandom(32))' | base64
```

```yaml
# couchdb-creds.yaml
apiVersion: v1
kind: Secret
metadata:
  name: couchdb-creds
type: Opaque
data:
  couchdb.user: [encoded-username-from-above]
  couchdb.pass: [encoded-password-from-above]
```

Create another secret for the erlang-cookie.  This isn't required but is highly suggested.

```bash
# generate and base64 encode a password
python -c 'import os,base64; print base64.b64encode(os.urandom(64))' | base64
```

```yaml
# erlang-cookie.yaml
apiVersion: v1
kind: Secret
metadata:
  name: erlang-cookie
type: Opaque
data:
  erlang.cookie: [encoded-erlang-cookie-from-above]
```

Now create both secrets in kubernetes

```bash
kubectl create -f couchdb-creds.yaml
kubectl create -f erlang-cookie.yaml
```

Create a configmap holding the configration for CouchDB.
*This isn't a necessary step but you will need to set your environment values in the petset inline during the last step*

Note: I have included alot of different environment variable hooks in my CouchDB image so that all important configuration information can be manipulated at container run.

```yaml
# couchdb-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: couchdb-config
  labels:
    app: couchdb
data:
  erlang.threads: '25'
  couchdb.log-level: info
  couchdb.require-valid-user: 'false'
  couchdb.shards: '4'
  couchdb.replicas: '3'
  couchdb.read-quorum: '1'
  couchdb.write-quorum: '2'
  
  couchdiscover.log-level: info
```

Now create the configmap in kubernetes

```bash
kubectl create -f couchdb-config.yaml
```

Create a headless service for the petset that will tolerate unready endpoints.
* *This is required for proper dns resolution*
* *Names here don't matter but need to match what is used in the petset spec*

```yaml
# couchdb-service-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: couchdb
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: 'true'
spec:
  clusterIP: None
  selector:
    app: couchdb
  ports:
  - name: data
    protocol: TCP
    port: 5984
  - name: admin
    protocol: TCP
    port: 5986
```

```bash
kubectl create -f couchdb-service-headless.yaml
```

Create a normal service in order to obtain a clusterIP and load balance requests across couch servers.*Name doesn't matter but will effect how you discover the service through DNS*

```yaml
# couchdb-service-balanced.yaml
apiVersion: v1
kind: Service
metadata:
  name: couchdb-bal
spec:
  selector:
    app: couchdb
  ports:
  - name: data
    protocol: TCP
    port: 5984
  - name: admin
    protocol: TCP
    port: 5986
```

```bash
kubectl create -f couchdb-service-balanced.yaml
```

Create the petset for CouchDB.
*Name's don't matter here but make sure things match with the other specs you're creating*

```yaml
# couchdb-petset.yaml
apiVersion: apps/v1alpha1
kind: PetSet
metadata:
  name: couchdb
spec:
  serviceName: couchdb
  replicas: 3
  template:
    metadata:
      labels:
        app: couchdb
      annotations:
        pod.alpha.kubernetes.io/initialized: 'true'
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: couchdb
        image: callforamerica/couchdb-app:latest
        ports:
        - name: data
          protocol: TCP
          containerPort: 5984
        - name: admin
          protocol: TCP
          containerPort: 5986
        env:
        - name: COUCHDB_ADMIN_USER
          valueFrom:
            secretKeyRef:
              name: couchdb-creds
              key: couchdb.user
        - name: COUCHDB_ADMIN_PASS
          valueFrom:
            secretKeyRef:
              name: couchdb-creds
              key: couchdb.pass
        - name: ERLANG_COOKIE
          valueFrom:
            secretKeyRef:
              name: erlang-cookie
              key: erlang.cookie
        - name: ERLANG_THREADS
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: erlang.threads
        - name: COUCHDB_LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdb.log-level
        - name: COUCHDB_REQUIRE_VALID_USER
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdb.require-valid-user
        - name: COUCHDB_SHARDS
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdb.shards
        - name: COUCHDB_REPLICAS
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdb.replicas
        - name: COUCHDB_READ_QUORUM
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdb.read-quorum
        - name: COUCHDB_WRITE_QUORUM
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdb.write-quorum
        resources:
          requests:
            cpu: 2
            memory: 2Gi
          limits:
            cpu: 2
            memory: 2Gi
        readinessProbe:
          httpGet:
            path: /
            port: 5984
          initialDelaySeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 5
        livenessProbe:
          httpGet:
            path: /_up
            port: 5984
          initialDelaySeconds: 15
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 5
        volumeMounts:
        - name: couchdb-data
          mountPath: /volumes/couchdb/data
        imagePullPolicy: IfNotPresent
      - name: couchdb-discover
        image: callforamerica/couchdb-discover:latest
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdiscover.log-level
        imagePullPolicy: IfNotPresent
      restartPolicy: Always
  volumeClaimTemplates:
  - metadata:
      name: couchdb-data
      annotations:
        volume.alpha.kubernetes.io/storage-class: anything
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 8Gi
```

Create the petset in kubernetes

```bash
kubectl create -f couchdb-petset.yaml
```

### IMPORTANT NOTES:

* If you do not have dynamic volume provisioning setup or enabled in your kubernetes cluster, you will need to comment or modify the `volumeClaimTemplates` and `volumeMounts` keys from the above yaml.  Setting up Dynamic Volume Provisioning it **way** outside the scope of this README.  

* You will need to make sure the annotation value for `storage-class` in `volumeClaimTemplates` matches the configured storage-class in your cluster.

* Adjust the above `resource` `requests` and `limits` to your needs.

* Adjust the `readinessProbe` and `livenessProbe` settings to your needs.

* Expected cluster size will be retrieved from `spec.replicas` in the petset above.  This value will be used to trigger the cluster finish action of the cluster_setup endpoint. 

* To override the expected cluster size, add an additional environment variable to the **`couchdb`** container (not couchdiscover) named: `COUCHDB_CLUSTER_SIZE` with the value of the expected size of your cluster.  It should be rare that this is necessary though.  Keep in mind that by doing this your cluster will not be ready to store or retrieve information until you reach the number of nodes specified in `COUCHDB_CLUSTER_SIZE`.  Until that point you will see continuous errors in your CouchDB logs complaining about missing databases.


## Environment variables used by couchdiscover:

### `couchdb` container:
* `COUCHDB_ADMIN_USER`: username to use when enabling the node, required.
* `COUCHDB_ADMIN_PASS`: password to use when enabling the node, required.
* `ERLANG_COOKIE`: cookie value to use as the `.erlang.cookie`, not required, fails back to insecure cookie value when not set.
* `COUCHDB_CLUSTER_SIZE`: not required, overrides the value of `spec.replicas` in the petset, should rarely be necessary to set. Don't set unless you know what you're doing.

### `couchdiscover` container:
* `LOG_LEVEL`: logging level to output container logs for.  Defaults to `INFO`, most logs are either INFO or WARNING level.


## How information is discovered

In order to best use something that is essentially "zero configuration," it helps to understand how the necessary information is obtained from the environment and api's. 

1. Initially a great deal of information is obtained by grabbing the hostname of the container that's part of a petset and parsing it.  This is how the namespace is determined, how hostnames are calculated later, the name of the petset to look for in the api, the name of the headless service, the node name, the index, whether a node is master or not, etc.

2. The kubernetes api is used to grab the petset and entrypoint objects. The entrypoint object is parsed to obtain the `hosts` list.  Then the petset is parsed for the ports, then the environment is resolved, fetching any externally referenced configmaps or secrets that are necessary.  Credentials are resolved by looking through the environment for the keys: `COUCHDB_ADMIN_USER`, `COUCHDB_ADMIN_PASS`.  Finally the expected cluster size is set to the number of replicas in the fetched petset.  You can override this as detailed in the above notes section, but should be completely unnecessary for most cases.


## Main logic

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