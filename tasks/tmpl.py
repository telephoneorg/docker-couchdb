import glob

from invoke import task

from . import util


@task
def render(ctx):
    val = ' '.join('--data templates/{}'.format(v) for v in ctx.tmpl['values'])
    files = ' '.join(glob.iglob(ctx.tmpl['glob'], recursive=True))
    print(val)
    print(files)
    print(list(glob.iglob(ctx.tmpl['glob'], recursive=True)))
    ctx.run('tmpld --strict {} {}'.format(val, files))
