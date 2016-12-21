# docker-couchdb full example

A full example of deploying CouchDB 2.0 with the Couchdiscover sidecar in Kubernetes.

## Requirements
* Kubernetes 1.5+ *(Couchdiscover 0.2.3+ Supports Kubernetes 1.5+, use 0.2.2 for older compatibility)*


## Usage

### Create a secret for couchdb creds
*Names don't matter as long as they match those used in the last step* 

```bash
kubectl create secret generic couchdb-creds --from-literal=couchdb.user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=cochdb.pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

### Create a secret for the erlang-cookie
*Not required but highly suggested*

```bash
kubectl create secret generic erlang-cookie --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

### Create a configmap for CouchDB & CouchDiscover
*Not required but you will need to set your environment values inline in the last step*


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

```bash
kubectl create -f couchdb-config.yaml
```

### Create a headless service
* *Required for proper dns resolution*
* *Names do not matter but need to match those in the last step*

```yaml
# couchdb-headless-service.yaml
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
    port: 5984
  - name: admin
    port: 5986
```

```bash
kubectl create -f couchdb-headless-service.yaml
```

### Create a ClusterIP service
* *Required for load balancing requests across couch servers.*
* *Names do not matter but will effect the DNS name*

```yaml
# couchdb-balanced-service.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: couchdb-bal
spec:
  selector:
    app: couchdb
  ports:
  - name: data
    port: 5984
  - name: admin
    port: 5986
```

```bash
kubectl create -f couchdb-balanced-service.yaml
```

### Create the StatefulSet
* *Name's do not matter but make sure it matches what you did earlier*

```yaml
# couchdb-statefulset.yaml
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: couchdb
spec:
  serviceName: couchdb
  replicas: 3
  template:
    metadata:
      labels:
        app: couchdb
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: couchdb
        image: callforamerica/couchdb:latest
        imagePullPolicy: IfNotPresent
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
        ports:
        - name: data
          containerPort: 5984
        - name: admin
          containerPort: 5986
        resources:
          requests:
            cpu: 1
            memory: 1Gi
          limits:
            cpu: 1
            memory: 1Gi
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
      - name: couchdiscover
        image: callforamerica/couchdiscover:latest
        imagePullPolicy: IfNotPresent
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: couchdb-config
              key: couchdiscover.log-level
      restartPolicy: Always
  volumeClaimTemplates:
  - metadata:
      name: couchdb-data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 8Gi
```

```bash
kubectl create -f couchdb-statefulset.yaml
```
