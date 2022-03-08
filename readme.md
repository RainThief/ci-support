# CI Support

This project provides common CI functionality in a single place that can be used by all projects.  There are some key principles for this project which are:

* CI stages can be ran inside containers to guarantee same result to all users;
* Containers images and scripts must be versioned so that adding new requirements will not break older projects automation;
* CI stages must be portable so can easily be used on any automation platform [*](#Compatibility);
* Scripts can be executed outside container environment to provide flexibility to project and engineers;

## Requirements

To run CI support you will need

* [Docker](https://docs.docker.com/get-docker/)
* Bash

Linux users will need `qemu-user-static` package to build multi arch images.

## Compatibility

It is not practicable to create scripting for different systems. There is a minimal code base in place to build and run stages in containers.  This has been written with bash scripting and tested only on Debian therefore, only stated compatible with Debian and derivatives, your mileage will vary with other *nix systems.

Debian has been selected due to its popularity on automation systems and its availability on WSL for Windows users.  It is also free to use and easily accessible.  Users who do not use Debian can easily use Debian within a container run these scripts.  However, if using these scripts inside a container which will then start its own container, remember to forward the socket.

## Features

* Automatic creation of container images and syncing to registry
* Multi-stage images detected and built in separate stages
* Images have cache manifest exported and are pulled for use as cache layers on CI environment
* Used locally on developers machines utilise standard layer caching with buildkit
* Extra image versions can be created by just adding a new Dockerfile

## Installation

The codebase contained within this project needs to be imported into your project to run.  This is achieved by a simple git clone. When developing you can check out the feature branch instead of master.

```bash
git clone <repo address> --depth 1 --branch master <local directory>;
```

It is more useful to provide scripting within your project to pull this in and start the CI stages.  An example using a makefile [can be found here](./docs/Makefile).

Your scripting needs to export certain environment variables which are

* `PROJECT_ROOT`  
  The PWD of the project root directory. All actions will be based off this path

* `APP_IMAGE_NAME`  
  The name, including registry e.g. `ghcr.io/organisation/app-image` for the production image to be created for the project.  
  **Dockerfile must reside within the `build` folder**  

* `GIT_URL`  
  For the release functionality, you will need to declare which repo to fetch and push the tags to.

* `CI_IMAGE_NAME_BASE`  
  All CI images automatically created will be stored in a registry and will have dynamically generated tags to identify them. CI_IMAGE_NAME_BASE sets the location for this registry e.g. `ghcr.io/organisation/ci-support`.

* `CI` (optional)  
  By default this is false but to leverage the cache manifests on images with auto sync to registries then this needs to be exported and set to `true`

* `DOCKER_USER`  
  Within CI environment (`CI=true`) images are synced and published to a registry.  This registry username or ID needs to be set for authentication.

* `DOCKER_PASS`  
  Within CI environment (`CI=true`) images are synced and published to a registry.  This registry password needs to be set for authentication.

* `DOCKER_REG`  
  Within CI environment (`CI=true`) images are synced and published to a registry.  This registry address needs to be set for authentication  e.g. `ghcr.io`

* `GITHUB_TOKEN`  
  Dependencies being built into CI images may come from a private repository.  To allow private repos to be used GITHUB_TOKEN must be exported into the environment and it will be passed into each docker build process as a secret.  It will nto remain in the build history or final image so is safe to use.

* `CONVENTIONAL_COMMIT`  
  Set to `true` to enable semver tag bumping based on [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)

* `AWS_ACCESS_KEY_ID` (optional)  
  If your pipelines use AWS and or terraform with AWS, you must export this variable

* `AWS_SECRET_ACCESS_KEY` (optional)  
  If your pipelines use AWS and or terraform with AWS, you must export this variable

* `AWS_DEFAULT_REGION` (optional)  
If your pipelines use AWS and or terraform with AWS, you must export this variable

* `DIFF_LINT` (optional)  
  When set to `true`, static analysis checks will only work on files that are modified from the main branch.

* `DOCKER_PROGRESS` (optional)  
  If you wish to see full output when building images export `DOCKER_PROGRESS=plain`

* `USE_CACHE` (optional)  
  If you wish to disable docker layer caching then export `USE_CACHE=false`

* `SCAN` (optional)  
  Scans application images after build for vulnerabilities defaults to `true`.

* `DOCKER_PLATFORM` (optional)  
  By default images will be built for the arch of system being ran on.  To build for a different arch or multi arch then this `DOCKER_PLATFORM` may be used to specify this.
  e.g. for arm `DOCKER_PLATFORM="linux/arm64"`
  for multi `DOCKER_PLATFORM=linux/amd64,linux/arm64`

* `CI_IMAGE_ARCH` (optional)  
  As with `DOCKER_PLATFORM` by default CI support images will be built for the arch of system being ran on.  To build for a different arch or multi arch then this `CI_IMAGE_ARCH` may be used to specify this.
  e.g. for arm `CI_IMAGE_ARCH="linux/arm64"`
  CI images are built in real time when needed so their is not a need to build multi arch unless testing images are compatible.

* `DOCKER_BUILD_ARGS` (optional)  
  Extra args can be passed to the `build-_image.sh` script via `DOCKER_BUILD_ARGS` to be used at build time
  for example

  ```bash
  export DOCKER_BUILD_ARGS="--build-arg HEALTH_CHECK_PORT=8080"
  ```

## Creating images
  
### Creating and using CI images

Dockerfile's are namespaced by directory structure to a two level tier.  All Dockerfile's are kept below the `images` directory.  For example, to create a new image for Python 3.9 related workloads I would put the Dockerfile in directory `images/python/3.9/Dockerfile`.

Using directory namespace is simple and flexible.  If you needed to update your Dockerfile but still leave the old one in place for non breaking changes you could create the new file in `images/python/3.9-1/Dockerfile`.

Please note that to leverage full caching if using multi stage builds, your build stage should be named `builder`.

Calling a container image requires loading in the script responsible and running the `exec_ci_container` function.

```bash
source ${CI_DIR_NAME}/common/docker.sh;
exec_ci_container python 3.8 <command or script>";
```

Whilst this example is in bash, it can be neater use a makefile to combine all your CI stages, and example of which [can be found here](./docs/Makefile).

If specifying a script to run in the container, this is always relative to your PROJECT_ROOT so will be ran from [within your project repo](#installation).  There are two main reasons this is done this way.

1. Although not recommended due to difference in tolol versions can give undesired results, 
iIt gives engineers the flexibility to run scripts outside on an container.

2. CI scripts inside this support repo are intended to be generic. A specific project may need to ability to run specific CI scripting and this scripting should always reside with the project itself.

### Creating App Images

It is also possible to use these scripts to create production images for your application.  A script resides at `common/build_images.sh` which will build your Dockerfile, create a cache manifest and cache image and publish your production image to your registry.

Please note that to leverage full caching if using multi stage builds, your build stage should be named `builder`.

This process will automatically tag your image with the branch name being built unless it is either "master" or "main" then the image tag will be "latest".

To build your image

```bash
export APP_IMAGE_NAME="ghcr.io/organisation/app-image-name";
./${CI_DIR_NAME}/common/build_image.sh;
```

This stage is not ran within a container as it would require [DIND](https://hub.docker.com/_/docker) which seems to not provide any benefit as the host machine will already have docker installed.

### build_image args

* `-s` will also scan built image for CVE's

* `-t` will also tag and push an incremented semver tag to the image  
       Note. only works on main branches and if CI="true"

### Note on package pinning

Images should be built pinning all packages as explained below.

#### Replicable platform

Whether the image is built locally on developers machine or on GitHub actions (multi arch aside) we have an exact same platform with all libraries and dependencies the same.  What works in one place will be the exact same when deployed or built in another place.

#### Stability

You should pin package versions so that you are satisfied with the dependencies you are using.  Tracking latest may and sometimes does bring in fixes but also new bugs.  If we want predictable behaviour we control when we upgrade our packages.

There is an argument to pinning to exact version or pinning to minor releases which can be done with apt, dnf and apk but that is aside from this overview

#### Caching

This is the area overlooked and not understood often.  Docker uses layer caching, when it builds an image if the command in docker file has not changed then the layer will be reused from the cache.  There is a skill in getting layers in the right order and how to combine, again beyond the scope here.

If we do not pin packages then the image will be built with the latest version and that layer will be cached.  If the package version changes then we will not get it as we will always be using the cached layer.  To change a pin will invalidate this layer and force a rebuild of this and subsequent layers (hence position important).

You can work around this by building --no-cache but that invalidates all layers and each system test or GitHub build will take a lot, lot longer.  You can export `CACHE=false` for any fringe case that requires this.

CI system, to work around GitHub actions limitations, uses cache manifest layers so it may use existing images as cache.  This is the default behaviour.
