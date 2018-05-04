PREFIX ?= consul-backup

container:
	${MAKEFILE_SUDO_COMMAND} docker build --pull -t $(PREFIX) .
.PHONY: container

tinker: container
	docker run --env-file env.list -it --rm $(PREFIX) /bin/bash
.PHONY: tinker

backup: container
	docker run --env-file env.list -it --rm $(PREFIX) /backup.sh
.PHONY: backup

restore: container
	docker run --env-file env.list -it --rm $(PREFIX) /restore.sh
.PHONY: restore
