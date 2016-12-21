# docker-couchdb minimal example

A minimal example of deploying CouchDB 2.0 with the Couchdiscover sidecar in Kubernetes.

Keep in mind that this example doesn't use persistent volumes, dynamic volume provisioning, and doesn't create a load balanced service such as in the full example.

## Requirements
* Kubernetes 1.5+ *(Couchdiscover 0.2.3+ Supports Kubernetes 1.5+, use 0.2.2 for older compatibility)*


## Usage

### Create a headless service
* *Required for proper dns resolution*
* *Names do not matter but need to match those in the last step*

```yaml
# couchdb-headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: couchdb-bal
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: 'true'
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
kubectl create -f couchdb-headless-service.yaml
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
          value: admin
        - name: COUCHDB_ADMIN_PASS
          value: secret
        - name: ERLANG_COOKIE
          value: insecure-cookie
        ports:
        - name: data
          containerPort: 5984
        - name: admin
          containerPort: 5986
      - name: couchdiscover
        image: callforamerica/couchdiscover:latest
        imagePullPolicy: IfNotPresent
      restartPolicy: Always
```

```bash
kubectl create -f couchdb-statefulset.yaml
```
