NAME := odbc-base

REPO ?= juaningles
.PHONY: all name info2 build info cloud-build clean clean-adaar docker-deps git-deps tag-all refresh quickview cves recommendations docker-deps $(DIR_SOURCES) $(SUB_DIRS)

all: build

UBUNTU_IMAGES=jammy mantic noble lunar
ALPINE_IMAGES=alpine
FULL_IMAGES=full
ALL_IMAGES= $(UBUNTU_IMAGES) $(ALPINE_IMAGES) $(FULL_IMAGES)


info:
	@echo $(DIR_SOURCES)
	@echo $(SUB_SOURCES)
	@echo $(SUB_DIRS)

info2:
	@echo "Original Sub Sources: $(SUB_SOURCES)"
	@echo "Sub Directories: $(SUB_DIRS)"

$(UBUNTU_IMAGES):
	echo Building $@
	podman build -t devnode:$@ -f Dockerfile.ubuntu --build-arg=VERSION=$@  .

$(ALPINE_IMAGES):
	echo Building $@
	podman build -t devnode:$@ -f Dockerfile.alpine --build-arg=VERSION=$@  .

$(FULL_IMAGES):
	echo Building $@
	podman build -t devnode:$@ -f Dockerfile.$@   .

tag-all:


puah-all: