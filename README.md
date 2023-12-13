# xdk-release

Repository to handle the environment required to virtualize and create multi platform releases of the XDK, including building cross-platform distributions.

## Supported environments

This container should run on any host operating system, including Mac with Apple Silicon. However, please note that, while the NSIS package
installed in the Linux container, the so called "EnVar" plugin, is cross-plaform and can execute only on x86. This means that any non x86
silicon needs to run the container through an emulation layer, which can be slower compared to a native x86 host. However, it is still not
impractically slow, as there have been significant improvements to the docker build kit, just to facilitate this kind of thing.

## Requirements

The prerequisite is that you have Docker installed on your system. You can check your docker version with ./scripts/check-docker-version.sh.
A Docker version >= 24, which can utilize the BuildKit is required. Without the BuildKit, using this container on any non-Intel silicon has
extreme overhead.

## Usage: Running with `docker compose`

This is the easiest, by far, and thus a strongly recommended way to execute XDK distribution builds inside the container.

To run:

```
[GITHUB_BRANCH=my-branch-name] docker compose up [-d]
```

or, if you want to build the latest master and don't need to refresh the build image, simply:

```
docker compose up [-d]
```

(The `-d` flag is used to run the container in the background, and is optional. Especially since this is a container that does one job,
and then exists. Detached containers are, of course, the common use case if you are running a containerized server or something.)

There should be a directory called "build" in your cloned folder with the build log, and distributions in .exe, zip and tar.gz form.

### Internals

The build process creates docker volumes on your host system for the checked out source and the cache. These persist between container runs. This is useful,
because it still enabled Gradle caching between repeated builds. We do not want to start from a completely clean system. On the other hand, it's very useful to
be able to do the build process with nothing but the Gradle/Java base image, to ensure that it will install for any user on any new system, and confirm that
there are no other requirements for XDK to build.

#### Clean build environment

If you *do* want to start from scratch and there existing volumes, you need to remove or prune them from your host system.
You will see them if you execute:

```
docker volume ls | grep xdk-builder 
```

They should have the volume type `local`. They can be purged as:

```
docker volume ls -q | grep xdk-builder | xargs docker volume rm
```

## Usage: Running everything from the Internet

Once again, make sure you have Docker installed on your system, preferably in a version >= 24. If you are
not on x86 native silicon, you need a Docker version that can successfully emulate linux/x86_64 without
undue overhead. The Docker Build Kit can do this, and it should be bundled in any modern Docker release.

### Login

Make sure you are logged onto the GitHub container registry:

```
docker login ghcr.io -u <your GitHub user name> --password-stdin
```

Enter the value of a GitHub token with read:package rights to the GitHub container registry as
password when prompted on stdin. The password token is a classic GitHub personal access token,
whose creation is described in the first section of the [GitHub documentation]
(https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

You can also set the system environment variable `GITHUB_TOKEN` to the value of the access token instead
of sending the `--password-stdin` argument to the login command.

You should see a message indicating that your login was successful.

### Pull the xdk-distros image from the Internet

```
docker pull gchr.io/xtclang/xdk-distros:latest
```

You can verify that you have successfully pulled the latest xdk-distros image by typing

```
docker images | grep xdk-distros
```

### Run the xdk-distros image from the Internet

```
[GITHUB_BRANCH=my-branch-name] docker run \
    [--rm] -v ~/my-xdk:/home/gradle/build \
    ghcr.io/xtclang/xdk-distros:latest
```

This will run the container you just pulled from GitHub on your local machine, mounting the `my-xdk` directory
under your home folder as the destinations for the distributions. It will clone out the latest version of
the branch "my-branch-name" for the container to build.

(The `--rm` flag is used to discard the container once it exists, its job done. Any volumes or bind mounts you have
added will, of course, persist until you manually delete them.)

Note that if you run the image without the compose script, as described above, you may have to map up your own 
caches (perhaps with `-v $GRADLE_USER_HOME:/home/gradle/gradle`, or with whatever local cache you prefer instead of
`$GRADLE_USER_HOME`). In order to facilitate incremental builds, it's likely a good idea to create a folder for that too. 

*(Note that if you have existing Gradle builds going on on the host machine, it's probably a bad idea to share the
Gradle cache dir they are using with the container. Use a clean directory instead. It will be reused between runs.)*

For example, this command line will create persistent caching builds under your `~/my-xdk` directory:

```
docker run                                  \ 
    [--rm]                                  \
    -v ~/my-xdk:/home/gradle/build          \
    -v ~/my-xdk/.cache:/home/gradle/.cache  \
    -v ~/my-xdk/src:/home/gradle/xvm        \
    ghcr.io/xtclang/xdk-distros:latest
```

The in-container mount points of the volumes need to be hard coded to the locations below (at least for now), because
that is where the running container expects its Gradle cache, build output and source input to be.

#### Using your own Docker volumes instead of local file system bind mounts

If you understand how Docker volumes work, and want to use them instead (recommended, or actually, it's recommende that you just 
use the Docker compose file and execute `docker compose up`, but you see what we mean)

```
docker volume create xdk-cache
docker volume create xdk-source
```

You only need to do this once, and can forget about the volumes afterwards. They will be persisted to your local
file system under /var/lib/docker or its equoivalent location, but root accessible only. You should only remove
containers through the docker command line anyway.

To list all existing docker volumes, you can execute:

```
docker volume ls
```

To remove a volume, you can execute:

```
docker volume rm <existing-volume-name>
```

Should the volume be in use, you'll like want to start using the "--rm" flag, as the XDK build containers aren't long running.
You can prune dead or stopped containers and images with 

```
docker container prune
docker image prune 
```

To delete all docker state from your machine (including cache layers, and not recommended), you can use: 

```
docker system prune --force --all --volumes
```

For example, this produces a repeatable build environment that uses the cache and existing source code clone. The latest
commit in the branch "my-cool-branch" will be synced and cloned for you:

```
docker run \
    -v ~/my-xdk:/home/gradle/build     \
    -v xdk-cache:/home/gradle/.cache   \
    -v xdk-src:/home/gradle/xvm        \
    ghcr.io/xtclang/xdk-distros:latest
```

This still contains a bind mount, the destination directory of the artifacts on your local file system, but of course it can
be a volume too. 

It's not hard to modify this scenario so that you can build installers for all platforms from any silicon,
using your current repository directory that you are working on your own branch with the source code.

### Work in progress

### Getting rid of the "EnVar plugin"

Ideally we would like to get rid of the EnVar plugin, as there is no official way to install it, and because it is x86 code only, and
is not supported by any package manager anywhere. There is probably a better way to get environment variables into an "nsi" installation file 
for Windows, and it would be worth a lot if we could generate the Windows installer on any platform. This is tracked as 
[an issue in GitHub](https://github.com/xtclang/xvm/issues/167)

### Developer backlog

This section is a bit unstructured and taken directly from the developer's log book. The issues are continuously migrated to the GitHub tracker,
and those files as issues on GitHub are removed from this file.

Separate solutions that should be added to this branch are:

1) SDKMAN support for the XDK in general (according to @cpurdy; TODO document use cases)
2) Homebrew support (document use cases and configuration). This is best done by a GitHub workflow and JReleaser. Everything else would be madness. 
3) Git release generation, through a Gradle/Git release plugin, and version file management. Again, JReleaser can help us a lot here.
4) Logic to also do ./gradlew publish* to various data sources.
5) Automate publishing to a SNAPSHOT repository that resides on GitHub on every push. The SNAPSHOT version number can be the same, but 
because we are a SNAPSHOT and not a normal release publiation, the existing ones should be overwritten.
