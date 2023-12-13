# xdk-release

Repository to handle the environment required to virtualize and create multi platform releases of the XDK, including building cross-platform distributions.

Makensis does not seem to work on Apple Silicon with the same file set as we use on Linux, even though it did do that on @cpurdy's build Mac.
Could that have been an Intel Mac? We can investage later. As NSIS works perfectly fine on an x86_64 container on M1/aarch64, we can
just containerize the build step, which is great! Anyone can be their own build machine now.

The prerequisite is that you use Docker BuildKit and Docker Compose.

To run:

```
docker compose build
docker compose up
```

There should be a directory called "build" in your cloned folder with the build log, and distributions in .exe, zip and tar.gz form.

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
