.ONESHELL:

DATE = $(shell date +'%s')

docker-vault-build:
	docker build -f Dockerfile.vaultbuild --build-arg always_upgrade="$(DATE)" -t hashicorp/vault:1.17 .

docker-plugin-build:
	docker build -f Dockerfile.pluginbuild -t vault-ethereum-builder .
