import os

from invoke import task

def image_name(ctx, tag):
    return '{}/{}:{}'.format(ctx.docker['org'], ctx.docker['name'], tag)


@task(default=True)
def tag_build(ctx):
    current_image = ctx.docker['image']
    build_tag = image_name(
        ctx, 'travis-{}'.format(os.getenv('TRAVIS_BUILD_NUMBER', '0')))

    ctx.run('docker tag {src} {dst}').format(src=current_tag, dst=build_tag)
