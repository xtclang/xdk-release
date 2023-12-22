#!/bin/bash

echo "OS_ARCH: $OS_ARCH"

GRADLE_TASK=$1
if [ -z $GRADLE_TASK ]; then
    echo "No Gradle task given to entry point. Using default 'install'"
    export GRADLE_TASK="install"
fi

function dump_env() {
    env | sort | grep GRADLE
    env | sort | grep GITHUB
    echo "HOME: $HOME"
    echo "Current working directory: $PWD"
}    
    
echo "Running Gradle task: $GRADLE_TASK..."

# TODO. This should really be the host architecture
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

log_path="+%F-%T"

pushd xvm
echo "Current working directory for build: $PWD"
gradle_cmd="./gradlew $GRADLE_TASK --no-scan --stacktrace $GRADLE_FLAGS"

if [ ! -z $GRADLE_LOG_LEVEL_FLAG ]; then
    echo "GRADLE_LOG_LEVEL flag set to $GRADLE_LOG_LEVEL_FLAG."
    gradle_cmd="$gradle_cmd $GRADLE_LOG_LEVEL_FLAG"
else
    echo "No GRADLE_LOG_LEVEL_FLAG specified. Will run with defaults (i.e. lifecycle logging)."
fi
echo "Running Gradle command: $gradle_cmd"
start_time=$(date "+%F-%T")
log_path=$HOME/build-$GITHUB_BRANCH.log
echo >>$log_path "$GITHUB_BRANCH Build started at: $start_time\n"
eval "$gradle_cmd" | tee $HOME/build-$GITHUB_BRANCH.log
echo "Build finished."
popd

echo "Current working directory after build: $PWD"

du -sh xvm 
du -sh xvm/xdk/build/distributions
du -sh .gradle

end_time=$(date "+%F-%T")
echo >>$log_path "$GITHUB_BRANCH Build finished at: $end_time\n"
cp $log_path /build
cat $log_path >> /build/build.log
cp xvm/xdk/build/distributions/* /build

#
# TODO attempt to install as local dist, also export that.
#

echo "Done."
