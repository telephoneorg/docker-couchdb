---
target: /config/local.ini
---
{% set config_map = env.get('CONFIG_MAP', 'couchdb') %}
{% set config = kube.get('configmap', config_map).data -%}

[couchdb]
database_dir = {{ config.get('couchdb.data-dir', '/volumes/couchdb/data') }}
view_index_dir = {{ config.get('couchdb.data-dir', '/volumes/couchdb/data/index') }}

[chttpd]
require_valid_user = false
port = {{ config.get('couchdb.port', '5984') }}
bind_address = 0.0.0.0

[httpd]
require_valid_user = false
port = {{ config.get('couchdb.port', '5986') }}
bind_address = 0.0.0.0

[cluster]
q = {{ config.get('couchdb.shards', '3') }}
n = {{ config.get('couchdb.replicas', '2') }}
r = {{ config.get('couchdb.read-quorum', '1') }}
w = {{ config.get('couchdb.write-quorum', '1') }}

[couch_httpd_auth]
iterations = 1000

[log]
level = {{ config.get('couchdb.log.level', 'info').lower() }}
