NAME := odbc-base

REPO ?= juaningles
DEFAULT_TAG ?= jammy

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

build: $(DEFAULT_TAG)

tag-all:

push-all:

test-trivy:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c "./install_trivy.sh ; trivy --version"

test-azcli:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c "./install_azcli.sh ; az --version"

test-databricks:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c "./install_databricks.sh ; databricks --version"

test-odbc:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c "./install_odbc.sh ; /opt/mssql-tools18/bin/sqlcmd -? | head -n 3"

test-podman:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c "./install_podman.sh ; podman info"

test-python:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG) sh -c "./install_python.sh ; python --version"

test: test-databricks test-azcli test-python test-podman  test-odbc test-trivy
	@echo SUCCESS

runit:
	podman run -it --rm --privileged  devnode:$(DEFAULT_TAG)
