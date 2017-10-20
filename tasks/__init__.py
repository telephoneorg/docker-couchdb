import os
import glob

from invoke import Collection, task

from . import test, dc, kube, hub


COLLECTIONS = [test, dc, kube, hub]

ns = Collection()
for c in COLLECTIONS:
    ns.add_collection(c)


ns.configure(dict(
    project='couchdb',
    repo='docker-couchdb',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER'),
        org=os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')),
        name='couchdb',
        tag='%s/%s:latest' % (
            os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')), 'couchdb'
        ),
        shell='bash'
    ),
    kube=dict(
        environment='testing'
    ),
    hub=dict(
        images=['couchdb']
    )
))

@task
def templates(ctx):
    files = ' '.join(glob.iglob('templates/**.j2', recursive=True))
    ctx.run('tmpld --strict --data templates/vars.yaml {}'.format(files))

ns.add_task(templates)
