# xdk-release

Repository to handle the environment required to virtualize and create multi platform releases of the XDK, including building cross-platform distributions.

Makensis does not seem to work on Apple Silicon with the same file set as we use on Linux, even though it did do that on @cpurdy's build Mac.
Could that have been an Intel Mac? We can investage later. As NSIS works perfectly fine on an x86_64 container on M1/aarch64, we can
just containerize the build step, which is great! Anyone can be their own build machine now.

The prerequisite is that you use Docker BuildKit and Docker Compose.

To run:

```
docker compose up
```

There should be a directory called "build" in your cloned folder with the build log, and distributions in .exe, zip and tar.gz form.

### Internals

The build process creates docker volumes on your host system for the checked out source and the cache. These persist between container runs. This is useful, because it still enabled Gradle caching between repeated builds. We do not want to start from a completely clean system.  On the other hand, it's very useful to be able to do the build process with nothing but the Gradle/Java base image, to ensure that it will install for any user on any new system, and confirm that there are no other requirements for XDK to build.

If you *do* want to start from scratch again, you need to remove or prune the Docker volumes from your host system. You will see them if you execute "docker volume ls | grep xdk". They should have the volume type "local".

### Work in progress.

This section is a bit unstructed and taken directly from the developer's log book. The issues will be migrated to the GitHub tracker,
and removed from this file.

Separate solutions that should be added to this branch are:
1) SDKMAN support (according to @cpurdy; TODO document use cases)
2) Homebrew support (document use cases and configuration)
3) Git release generation, through a Gradle/Git release plugin, and version file management.
4) Up to date checks of a repo and its dependencies.
5) Logic to also do ./gradlew publish* to various data sources.
6) installLocalDist could be called as a configurable option.
7) Significantly increase the ergonomics by using the Gradle Docker Compose plugin, and perhaps unify with CI/CD pipeline or even the XDK repo.
