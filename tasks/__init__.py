import os

from invoke import Collection, task

from . import admin, ci, dc, hub, kube, test, tmpl, util


CONFIG = dict(
    modules=[admin, ci, dc, hub, kube, test, tmpl],
    project='couchdb',
    repo='docker-couchdb',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER', 'joeblackwaslike'),
        org=util.get_docker_org(),
        name='couchdb',
        tag=util.get_docker_tag(),
        image='{}/{}:{}'.format(
            util.get_docker_org(), 'couchdb', util.get_docker_tag()
        ),
        shell='bash'
    ),
    dc=dict(
        files=['docker-compose.yaml'],
        defaults=dict(
            up=['abort-on-container-exit', 'no-build'],
            down=['volumes']
        )
    ),
    test=dict(
        image='telephoneorg/dcgoss:latest'
    ),
    kube=dict(
        environment='testing'
    ),
    hub=dict(
        images=['couchdb']
    ),
    admin=dict(
        url='http://127.0.0.1:5984/_utils/'
    ),
    tmpl=dict(
        glob='templates/**/*.j2',
        values=['vars.yaml']
    )
)

util.export_docker_tag()

ns = Collection()
for c in CONFIG['modules']:
    ns.add_collection(c)

ns.configure(CONFIG)
