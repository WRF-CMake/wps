#!/bin/bash

set -ex

# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then

    # Existing python is 2.7, upgrade to 3.
    brew upgrade python

    python3 -V
    pip3 -V

fi
