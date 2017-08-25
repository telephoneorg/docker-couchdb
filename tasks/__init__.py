import os
import glob

from invoke import Collection, task

from . import test, dc, kube


COLLECTIONS = [test, dc, kube]

ns = Collection()
for c in COLLECTIONS:
    ns.add_collection(c)


ns.configure(dict(
    project='couchdb',
    repo='docker-couchdb',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER'),
        org=os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'joeblackwaslike')),
        name='couchdb',
        tag='%s/%s:latest' % (
            os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'joeblackwaslike')), 'couchdb'
        ),
        shell='bash'
    ),
    kube=dict(
        environment='testing'
    ),
    test=dict(
        env='-e "LOCAL_DEV_CLUSTER=true"'
    )
))

@task
def templates(ctx):
    files = ' '.join(glob.iglob('templates/**.j2', recursive=True))
    ctx.run('tmpld --strict --data templates/vars.yaml {}'.format(files))

ns.add_task(templates)
