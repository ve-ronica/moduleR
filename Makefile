MODELDIR = model
SRCDIR = src
CONFDIR = conf
SRC = Dockerfile $(wildcard $(SRCDIR)/*) $(wildcard $(CONFDIR)/*)
DOCKER = docker
ECR = myrepo
REPO = predict-service
VERSION = latest

.PHONY: image run connect push test

image: $(SRC)
	$(DOCKER) build -t $(ECR)/$(REPO):$(VERSION) .

run:
	$(DOCKER) run -d --name rapache -p 80:80 $(ECR)/$(REPO):$(VERSION)

connect:
	$(DOCKER) exec -it rapache /bin/bash

push:
	$(DOCKER) push $(ECR)/$(REPO):$(VERSION)

clean: 
	$(DOCKER) kill rapache && $(DOCKER) rm rapache

test:
	curl --data 'x1=1&x2=2&x3=3' http://192.168.99.100/predict/test/1
