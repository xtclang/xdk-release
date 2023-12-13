#!/bin/bash

pushd xvm
echo "Building installers..."
popd

cp xvm/xdk/build/distributions/* /build
ls -l /build

echo "Copied distributions to build."
