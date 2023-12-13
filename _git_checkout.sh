#!/bin/bash 
echo "GithubToken: "$GITHUB_TOKEN
git clone https://$GITHUB_TOKEN@github.com/xtclang/xvm.git
git checkout $GITHUB_BRANCH
git checkout tags/$GITHUB_TAG -b $GITHUB_BRANCH

