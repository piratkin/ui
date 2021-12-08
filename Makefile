# Copyright (c) Mainflux
# SPDX-License-Identifier: Apache-2.0

MF_DOCKER_IMAGE_NAME_PREFIX ?= mainflux
BUILD_DIR = build
SERVICES = users things http coap lora influxdb-writer influxdb-reader mongodb-writer \
        mongodb-reader cassandra-writer cassandra-reader postgres-writer postgres-reader cli \
        bootstrap opcua auth twins mqtt provision certs smtp-notifier
CGO_ENABLED ?= 0
GOARCH ?= amd64

define compile_service
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) GOARM=$(GOARM) go build -mod=vendor -ldflags "-s -w" -o ${BUILD_DIR}/mainflux-$(1) cmd/$(1)/main.go
endef

all: $(SERVICES)

.PHONY: all $(SERVICES) release

ui:
	docker build --tag=mainflux/ui -f docker/Dockerfile .

ui-experimental:
	docker build --tag=mainflux/ui-experimental -f docker/Dockerfile.experimental .

run:
	docker-compose -f docker/docker-compose.yml up

clean:
	docker-compose -f docker/docker-compose.yml down --rmi all -v --remove-orphans

release:
	$(eval version = $(shell git describe --abbrev=0 --tags))
	git checkout $(version)
	docker tag mainflux/ui mainflux/ui:$(version)
	docker push mainflux/ui:$(version)

proto:
	protoc --gofast_out=plugins=grpc:. *.proto
	protoc --gofast_out=plugins=grpc:. pkg/messaging/*.proto

$(SERVICES):
	$(call compile_service,$(@))
