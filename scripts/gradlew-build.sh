#!/bin/bash

GRADLE_TASK=$1
echo "Running gradle task: $gradle_task for $GRADLE_TASK..."
echo "Home: $HOME"
echo "Pwd: $PWD"

arch=$(uname -m)
echo "ARCH: "$arch
if [ "$arch" == "x86_64" ]; then
    echo "Install task."
    GRADLE_FLAGS="--no-watch-fs"
else
    GRADLE_FLAGS=""
fi

echo "Checking existing volumes:"
du -sh xvm
du -sh .gradle

echo "Environment:"
env | sort | grep GRADLE
env | sort | grep GITHUB

pushd xvm
echo "Build Pwd:$PWD"
echo "GRADLE_LOG_LEVEL_FLAG: $GRADLE_LOG_LEVEL_FLAG"
echo "GRADLE_TASK: $GRADLE_TASK"
gradle_cmd="./gradlew $GRADLE_TASK --no-scan --stacktrace $GRADLE_FLAGS"
if [ ! -z $GRADLE_LOG_LEVEL_FLAG ]; then
    echo "GRADLE_LOG_LEVEL flag set to $GRADLE_LOG_LEVEL_FLAG."
    gradle_cmd="$gradle_cmd $GRADLE_LOG_LEVEL_FLAG"
else
    echo "No GRADLE_LOG_LEVEL_FLAG specified. Will run with defaults (i.e. lifecycle logging)."
fi
echo "Running Gradle command: $gradle_cmd"
eval "$gradle_cmd" | tee $HOME/build-$GITHUB_BRANCH.log
echo "Build finished."
popd

echo "Directory: $PWD"
du -sh xvm 
du -sh .gradle 
cp $HOME/build-$GITHUB_BRANCH.log /build
cp xvm/xdk/build/distributions/* /build

echo "Done."
