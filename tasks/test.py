from invoke import task


@task(default=True)
def docker(ctx):
    tag = ctx.docker['tag']
    env = ctx.test['env']
    ctx.run('tests/run {} {}'.format(env, tag), pty=True)
