#!/bin/bash

export XVM_REPO_ROOT=$HOME/xvm

sudo chown -R gradle:gradle "$GRADLE_HOME"

#
# Marshall any arguments given to entrypoint to shell execution.
#
entrypoint_args=${@}
if [ -z "$entrypoint_args" ]; then
    echo "No extra entrypoint arguments for container."
else
    echo "Handing over entrypoint arguments to exec: ${@}"
    exec "${@}"
fi

function ensure_repo() {
    if [ -z "$GITHUB_REPOSITORY" ]; then
        echo "GITHUB_REPOSITORY is not set. This environment variable is required."
        exit 1
    fi
    echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
}

function dump_env() {
    echo "System environment:"
    echo "---"
    env | sort | grep GRADLE
    env | sort | grep GITHUB
    echo "HOME: $HOME"
    echo "Current working directory: $PWD"
    echo "---"
}

function dump_storage() {
    echo "Volume environment:"
    echo "---"
    local distros=${XVM_REPO_ROOT}/xdk/build/distributions
    du -sh .gradle
    du -sh "${XVM_REPO_ROOT}"
    if [ -d "$distros" ]; then
	    echo "Distributions generated:"
	    find "$distros"
	    du -sh "$distros"
    else
      echo "WARNING: No distributions have been generated."
    fi
    echo "---"
}

function write_latest_commit() {
    latest_commit=$(git -C "${XVM_REPO_ROOT}" rev-parse HEAD)
    echo "$latest_commit" >"${XVM_REPO_ROOT}"/latest-build-commit
    echo "Latest commit: $latest_commit. Written to ${XVM_REPO_ROOT}/latest-build-commit."
    echo "Done."
}

function clone_xvm() {
    echo "No repository found. Cloning XVM to source Docker volume."
    rm -fr "${XVM_REPO_ROOT:?}"/*
    git clone --branch "$GITHUB_BRANCH" --depth=1 https://github.com/xtclang/xvm "${XVM_REPO_ROOT}"
    write_latest_commit
}

function update_xvm() {
    echo "Updating XVM to latest version."
    git -C "${XVM_REPO_ROOT}" pull --rebase
    write_latest_commit
}

# Check if there is a version file on the XDK volume.
#
# If no version info is present, or a version file different to the one we last built on is present, we need to update source branch.
# If a version file is present and it's the same as the latest change in the requested repo, we do not need to do any source code
# operations.
function update_source() {
  commit_latest=$(curl -s https://api.github.com/repos/xtclang/xvm/git/refs/heads/"$GITHUB_BRANCH" | jq -r '.object.sha')
  commit_current=""
  if [ ! -f "${XVM_REPO_ROOT}/latest-build-commit" ]; then
    echo "No build info found from a previous build."
    clone_xvm
    return 0
  fi

  commit_current=$(cat "${XVM_REPO_ROOT}"/latest-build-commit)
  if [ "$commit_latest" != "$commit_current" ]; then
    update_xvm
    return 0
  fi

  echo "XVM repository cloned to the 'xvm' volume is up to date."
}

function run_gradle_task() {
  local distros=${XVM_REPO_ROOT}/xdk/build/distributions
  # Delete any existing distributions, but retain the build cache and the rest of the build.
  rm -fr "${distros:?}"/*
  echo "Deleted any distributions from $distros"

  local log_path="+%F-%T"
  pushd xvm >/dev/null || exit 1
  echo "Current working directory for build: $PWD"
  gradle_cmd="./gradlew $GRADLE_TASK_NAME --no-scan --stacktrace $gradle_flags"

  if [ -n "$GRADLE_LOG_LEVEL_FLAG" ]; then
      echo "GRADLE_LOG_LEVEL flag set to $GRADLE_LOG_LEVEL_FLAG."
      gradle_cmd="$gradle_cmd $GRADLE_LOG_LEVEL_FLAG"
  else
      echo "No GRADLE_LOG_LEVEL_FLAG specified. Will run with defaults (i.e. lifecycle logging)."
  fi
  echo "Running Gradle command: $gradle_cmd"

  local start_time=$(date "+%F-%T")
  log_path="$HOME/gradle-$GRADLE_TASK_NAME-$GITHUB_BRANCH-$start_time.log"
  printf >>"$log_path" "%s Build started at: $start_time\n" "$GITHUB_BRANCH"
  eval "$gradle_cmd" | tee "$HOME/build-$GITHUB_BRANCH.log"
  echo "Build finished."
  popd || exit 1

  echo "Current working directory after build: $PWD"
  dump_storage

  local end_time=$(date "+%F-%T")
  printf >>"$log_path" "%s Build finished at: $end_time\n" "$GITHUB_BRANCH"
  echo "LOG_PATH: $log_path"
  cp "$log_path" "$HOME/build"
  cat "$log_path" >> "$HOME/build/build.log"
  #sudo cp "${XVM_REPO_ROOT}"/xdk/build/distributions/* "$HOME/build"

  if [ -n "$COPY_DISTRIBUTIONS" ]; then
    if [ ! -d "$distros" ]; then
      echo "ERROR: No distributions where generated for Gradle $GRADLE_TASK_NAME"
    else
      echo "Copying distributions to host."
      cp -r $distros $HOME/build
      echo "Done."
    fi
  else
    echo "No distributions requested for host (Gradle $GRADLE_TASK_NAME)."
  fi

  echo "Done."
}

echo "Running container as $TARGETARCH on a host architecture of $BUILDARCH"
gradle_flags=""
if [ "$BUILDARCH" != "$TARGETARCH" ]; then
    echo "WARNING: Container is running on a different architecture than host; file system watch will be disabled."
    gradle_flags="--no-watch-fs"
  else
    echo "Container is running on the same architecture as host; file system watch will be enabled."
fi

dump_env
dump_storage
update_source

echo "Running container with task name: $GRADLE_TASK_NAME"
if [ ! -n "$GRADLE_TASK_NAME" ]; then
    echo "No Gradle task name given. Defaulting to installDist."
    export GRADLE_TASK_NAME=installDist
fi
run_gradle_task

