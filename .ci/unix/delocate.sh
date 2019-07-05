#!/bin/bash

# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

set -ex

SCRIPTDIR=$(dirname "$0")
cd $SCRIPTDIR/../..

if [ "$(uname)" == "Darwin" ]; then

    pip3 install delocate
    delocate-listdeps --all --depending build/install
    delocate-path build/install
    delocate-listdeps --all --depending build/install

else
    echo "Unknown OS: $(uname)"
    exit 1
fi