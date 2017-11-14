import os
import glob

from invoke import Collection, task

from . import test, dc, kube, hub, ci, util


COLLECTIONS = [test, dc, kube, hub, ci]
CONFIG = dict(
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
    kube=dict(
        environment='testing'
    ),
    hub=dict(
        images=['couchdb']
    )
)

util.export_docker_tag()

ns = Collection()
for c in COLLECTIONS:
    ns.add_collection(c)

ns.configure(CONFIG)


@task
def templates(ctx):
    files = ' '.join(glob.iglob('templates/**.j2', recursive=True))
    ctx.run('tmpld --strict --data templates/vars.yaml {}'.format(files))

ns.add_task(templates)
