FROM aelsabbahy/goss:onbuild

COPY goss /

WORKDIR /goss

CMD ["validate", "--retry-timeout", "5m", "--sleep", "10s"]
