#!/bin/bash

function dump_env() {
    echo "System environment:"
    env | sort | grep GRADLE
    env | sort | grep GITHUB
    echo "HOME: $HOME"
    echo "Current working directory: $PWD"
}    

function dump_storage() {
    echo "Checking existing volumes:"
    du -sh .gradle
    du -sh xvm
    if [ -d xvm/xdk/build/distributions ]; then
	du -sh xvm/xdk/build/distributions
    fi
}    

echo "Running container as $TARGETARCH on a host architecture of $BUILDARCH"

GRADLE_TASK=$1
if [ -z $GRADLE_TASK ]; then
    echo "No Gradle task given to entry point. Using default 'install'"
    export GRADLE_TASK="install"
fi

GRADLE_FLAGS=""
if [ "$BUILDARCH" != "TARGETARCH" ]; then
    echo "WARNING: Container is running on a different architecture than host; file system watch will be disabled."
    GRADLE_FLAGS="--no-watch-fs"
fi

dump_env
dump_storage

log_path="+%F-%T"

pushd xvm >/dev/null
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

dump_storage

end_time=$(date "+%F-%T")
echo >>$log_path "$GITHUB_BRANCH Build finished at: $end_time\n"
cp $log_path /build
cat $log_path >> /build/build.log
cp xvm/xdk/build/distributions/* /build

#
# TODO attempt to install as local dist, also export that.
#

echo "Done."
