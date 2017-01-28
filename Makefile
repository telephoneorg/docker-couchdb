SHELL = /bin/zsh
SHELLFLAGS = -c

NAME := $(shell basename $(PWD) | cut -d'-' -f2)
BRANCH ?= $(shell basename $(shell git status | head -1 | rev | cut -d" " -f1 | rev))
ifeq ($(BRANCH),master)
	TAG := latest
else
	TAG := $(BRANCH)
endif
DOCKER_USER ?= callforamerica
DOCKER_IMAGE := $(DOCKER_USER)/$(NAME):$(TAG)

BUILD_TOKEN = aa10a848-ccc4-46ab-a67d-b345c45b6e3c

CSHELL = bash -l
ENV_ARGS = --env-file default.env
PORT_ARGS = -p "5984:5984" -p "5986:5986"
# VOLUME_ARGS = --tmpfs /volumes/$(NAME)/data:size=512M

-include ../Makefile.inc

.PHONY: all build rebuild tag info test run launch shell launch-as-dep
.PHONY: rmf-as-dep logs start kill stop rm rmi rmf hub-login hub-push hub-build
.PHONY: kube-local kube-local-rm kube-deploy kube-rm

build:
	@docker build -t $(DOCKER_IMAGE) --force-rm .
	@-test $(LOCAL) && $(MAKE) dclean

rebuild:
	@docker build -t $(DOCKER_IMAGE) --force-rm --no-cache .
	@-test $(LOCAL) && $(MAKE) dclean

tag:
	@test $(ALT_TAG) && \
		docker tag $(DOCKER_IMAGE) $(DOCKER_USER)/$(NAME):$(ALT_TAG)

info:
	@echo "NAME: 		$(NAME)"
	@echo "BRANCH: 	$(BRANCH)"
	@echo "TAG: 		$(TAG)"
	@echo "DOCKER_USER: 	$(DOCKER_USER)"
	@echo "DOCKER_IMAGE: 	$(DOCKER_IMAGE)"

test:
	@tests/run

run:
	@docker run -it --rm --name $(NAME).local \
		$(ENV_ARGS) $(DOCKER_IMAGE) $(CSHELL)

launch:
	@docker run -d --name $(NAME) -h $(NAME).local \
		$(ENV_ARGS) $(VOLUME_ARGS) $(PORT_ARGS) $(DOCKER_IMAGE)

shell:
	@docker exec -ti $(NAME) $(CSHELL)

launch-as-dep:
	@$(MAKE) launch

rmf-as-dep:
	@$(MAKE) rmf

logs:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	@-docker kill $(NAME)

stop:
	@-docker stop $(NAME)

rm:
	@-docker rm $(NAME)

rmi:
	@-docker rmi $(DOCKER_IMAGE)

rmf:
	@-docker rm --force $(NAME)

hub-login:
	@docker login -u $(DOCKER_USER) -p $(DOCKER_PASS)

hub-push:
	@docker push $(DOCKER_USER)/$(NAME)

hub-build:
	@curl -s -X POST -H "Content-Type: application/json" \
		--data '{"docker_tag": "$(TAG)"}' \
		https://registry.hub.docker.com/u/$(DOCKER_USER)/$(NAME)/trigger/$(BUILD_TOKEN)/

kube-local:
	@kubectl apply -f tests/manifests/local.yaml

kube-local-rm:
	@kubectl delete -f tests/manifests/local.yaml

kube-deploy:
	@kubectl apply -f kubernetes

kube-rm:
	@kubectl delete -f kubernetes
