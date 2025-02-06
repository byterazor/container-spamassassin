# Spamassassin Container Image

## Description

This is a basic container image for running [Spamassassins](https://spamassassin.apache.org/) spamd service.

The container is based on debian:stable-slim.

## Features 

At the moment the container starts with the default spamassassin configuration. This configuration can not be changed at the moment. 

## Security

- spamd is running as a non-root user (default: spamassassin) to ensure that it does not have root access
- the containers root file system can be mounted readonly to prevent modifications 

## Supported Architectures

- amd64
- arm64

## Updates

I am trying to update the image weekly as long as my private kubernetes cluster is available. So I do not promise anything and do **not** rely 
your business on this image.

## Prerequisities

A container runtime like

* docker 
* podman
* kubernetes


## Container Parameters

* `SPAMD_ALLOWED_IPS` - (mandatory) the allowed ips for spamassassin. at the moment only one set is supported (will be fixed in the future) 
* `SPAMD_SPAMD_MAX_CHILDREN` - (optional) the maximum number of spamassassin child processes to spawn, default is 5

## Volumes
q

## Source Repository

* https://gitea.federationhq.de/Container/spamassassin.git

## Prebuild Images

* https://hub.docker.com/repository/docker/byterazor/spamassassin/general

## Authors

* **Dominik Meyer** - *Initial work* 

## License

This project is licensed under the GPLv3 License - see the [LICENSE](LICENSE) file for details.
