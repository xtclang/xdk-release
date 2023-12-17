#!/bin/bash

echo "Building XVM branch $GITHUB_BRANCH.."
echo "Home: $HOME"
echo "Pwd: $PWD"

pushd xvm
echo "Build Pwd:$PWD"
./gradlew build --info --no-scan --stacktrace |tee $HOME/build-$GITHUB_BRANCH.log
echo "Build finished."
popd
du -sh xvm 
du -sh .gradle 
cat $HOME/build-$GITHUB_BRANCH.log

#rm -fr /current-repo-version.json
#curl https://api.github.com/repos/xtclang/xvm/git/refs/heads/$GITHUB_BRANCH -o /current-repo-version.json
#if [ -f /repo-version.json ]; then
#    echo "Existing 'repo-version.json' stamp exists."
#    if cmp --silent -- "/repo-version.json" "current-repo-version.json"; then#
#	echo "Same git commit as the last build was requsted. Skipping ./gradlew build"
#    else	#
#	env | grep GRADLE | sort#
#	git clone --branch $GITHUB_BRANCH --depth=1 https://github.com/xtclang/xvm /xvm
#	(cd /xvm && ./gradlew build --no-scan --info --stacktrace | tee /build-$GITHUB_BRANCH.log)	
#    fi
#fi

