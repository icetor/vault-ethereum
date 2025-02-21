.ONESHELL:

DATE = $(shell date +'%s')

docker-build:
	docker build --build-arg always_upgrade="$(DATE)" -t cypherhat/vault-ethereum:latest .

docker-vault-build:
	docker build -f Dockerfile.vaultbuild --build-arg always_upgrade="$(DATE)" -t hashicorp/vault:1.17 .

docker-plugin-build:
	docker build -f Dockerfile.pluginbuild -t vault-ethereum-builder .

run:
	docker-compose -f docker/docker-compose.yml up -d --build --remove-orphans

all: docker-build run