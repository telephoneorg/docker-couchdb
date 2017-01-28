# Creates a stable branch identifier when executing CI on pull requests.
if [[ $TRAVIS_PULL_REQUEST == "false" ]]; then
    export BRANCH=$TRAVIS_BRANCH
else
    export BRANCH=$TRAVIS_PULL_REQUEST_BRANCH
fi
