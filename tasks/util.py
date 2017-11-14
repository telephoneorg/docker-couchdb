import os


def get_docker_tag():
    if os.getenv('TRAVIS') == 'true':
        return get_docker_tag_ci()
    else:
        return os.getenv('DOCKER_TAG', 'latest')


def get_docker_tag_ci():
    event_type = os.getenv('TRAVIS_EVENT_TYPE')
    travis_branch = os.getenv('TRAVIS_BRANCH')
    travis_tag = os.getenv('TRAVIS_TAG')
    travis_commit = os.getenv('TRAVIS_COMMIT')
    travis_pr = os.getenv('TRAVIS_PULL_REQUEST')

    if event_type == 'pull_request':
        return '{}-pr-{}'.format(travis_branch, travis_pr)
    elif event_type == 'push':
        if travis_tag == travis_branch:
            return travis_tag
        else:
            return travis_commit[:7]


def image_name(ctx, tag):
    return '{}/{}:{}'.format(ctx.docker['org'], ctx.docker['name'], tag)


def export_docker_tag():
    tag = get_docker_tag()
    os.environ.update(dict(DOCKER_TAG=tag))


def get_docker_org():
    return os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg'))


def flags_to_arg_string(flags):
    return ' '.join(['--{}'.format(flag) for flag in flags])
