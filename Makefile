SRC = Dockerfile fraudscore.R rapache.conf RSourceOnStartup.R fraudscore.logrotate logstash.conf dockerstart.sh cacert.pem
MODELS = $(wildcard model/*rds)
DOCKER = docker
ECR = 112942558241.dkr.ecr.us-east-1.amazonaws.com
REPO = fraudscore-service
VERSION = latest

.PHONY: image run connect push login

image: $(SRC) $(MODELS)
	$(DOCKER) build -t $(ECR)/$(REPO):$(VERSION) .

run:
	$(DOCKER) run -d --name rapache -p 80:80 $(ECR)/$(REPO):$(VERSION)

connect:
	$(DOCKER) exec -it rapache /bin/bash

fraudscore.zip: $(SRC) $(MODELS)
	zip $@ $^

push:
	$(DOCKER) push $(ECR)/$(REPO):$(VERSION)

clean: 
	$(RM) fraudscore.zip

#
# ECR How-To
#
# Log into ECR
# $ eval $(aws ecr get-login --region us-east-1)
#
# Pull down an ECR image to local
# $ docker pull 112942558241.dkr.ecr.us-east-1.amazonaws.com/zookeeper-single-node:3.4.6
#
# Tag a local image (can be done at image creation time with -t)
# $ docker tag <imageid> 112942558241.dkr.ecr.us-east-1.amazonaws.com/fraudscore-service:latest
#
# Push a local image to ECR
# $ docker push 112942558241.dkr.ecr.us-east-1.amazonaws.com/fraudscore-service
#
# Create docker-machine with specific Docker version
# $ docker-machine create -d virtualbox --virtualbox-boot2docker-url=https://github.com/boot2docker/boot2docker/releases/download/v1.9.1/boot2docker.iso v1.9.1

