from invoke import task


@task
def open(ctx, url=None):
    url = url or ctx.admin['url']
    ctx.run('open {}'.format(url))
