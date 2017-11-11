from invoke import task


@task(default=True)
def docker(ctx):
    name = ctx.docker['name']
    ctx.run('tests/run {}'.format(name), pty=True)
