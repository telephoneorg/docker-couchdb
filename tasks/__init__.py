import os
import glob

from invoke import Collection, task

from . import test, dc, kube, hub, ci


COLLECTIONS = [test, dc, kube, hub, ci]

ns = Collection()
for c in COLLECTIONS:
    ns.add_collection(c)


ns.configure(dict(
    project='couchdb',
    repo='docker-couchdb',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER', 'joeblackwaslike'),
        org=os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')),
        name='couchdb',
        tag=os.getenv('DOCKER_TAG', os.getenv('TRAVIS_COMMIT', 'latest'))[:7],
        image='{}/{}:{}'.format(
            os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')),
            'couchdb',
            os.getenv('DOCKER_TAG', os.getenv('TRAVIS_COMMIT', 'latest'))[:7]
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
