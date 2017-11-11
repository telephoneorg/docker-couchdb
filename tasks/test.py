from invoke import task


def update_env(ctx)
    os.environ.update(dict(DOCKER_TAG=ctx.docker['tag']))


@task(default=True)
def docker(ctx):
    update_env(ctx)
    name = ctx.docker['name']
    ctx.run('tests/run {}'.format(name), pty=True)
