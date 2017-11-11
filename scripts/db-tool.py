import os
import json
from collections import OrderedDict

import requests

json._default_decoder = json.JSONDecoder(
    object_hook=None,
    object_pairs_hook=OrderedDict
)

import couchdb, couchdb.tools, couchdb.tools.dump

# sandbox creds for now
USER = os.getenv('COUCHDB_ADMIN_USER', 'celiomyomectomy')
PASS = os.getenv('COUCHDB_ADMIN_PASS', 'twr4Cw0veRohYFb195l4OwW4lMWsR72H')
HOST = os.getenv('COUCHDB_HOST', 'localhost')
PORT = os.getenv('COUCHDB_PORT', '5984')
SERVER_URL = 'http://{}:{}@{}:{}'.format(USER, PASS, HOST, PORT)

couch = couchdb.Server(SERVER_URL)


# working url: http://celiomyomectomy:twr4Cw0veRohYFb195l4OwW4lMWsR72H@localhost:5984/_all_dbs
def get_dbs():
    url = SERVER_URL + '/_all_dbs'
    print(url)
    r = requests.get(url)
    if not r.ok:
        raise RuntimeError(
            'Error retrieving all_dbs: %s %s', r.status_code, r.json())
    return [db for db in r.json() if not db.startswith('_')]



def dump_dbs():
    url = 'http://{}:{}/'.format(HOST, PORT)
    dbs = get_dbs()
    print('dbs:', dbs)

for db in dbs:
    db_url = url + db
    db_file = db + '.couch-dump'
    print('url:', db_url, '  file:', db_file)

    with open(db_file) as fd:
        print('opened file:', db_file)
        couchdb.tools.dump.dump_db(
            db_url,
            username=USER,
            password=PASS,
            output=fd
        )


def load_dbs()
