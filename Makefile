image = ksuderman/galaxy-maintenance
version = 0.6
platform = linux/amd64

help:
	@echo "GOALS"
	@echo "    docker   - builds the Docker image"
	@echo "    push     - push the image to the Docker hub"
	@echo "    run      - runs a Bash shell in the Docker container"
	@echo "    help     - prints this help message. This is the default goal."
	@echo
	@echo "VARIABLES"
	@echo "    image    - the name of the image to build. Default is $(image)"
	@echo "    version  - version number for the Docker tag. Default is $(version)"
	@echo "    platform - platform to target. Default is $(platform)"
	
docker:
	docker build -t $(image):$(version) --platform $(platform) .
	
run:
	docker run -it $(image):$(version) bash

push:
	docker push $(image):$(version)

