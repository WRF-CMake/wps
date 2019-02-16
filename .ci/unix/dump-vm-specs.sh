#!/usr/bin/env bash

if [ "$(uname)" == "Darwin" ]; then
    sw_vers
    top -l 1 -s 0 | grep PhysMem
    sysctl hw
    df -h
elif [ "$(uname)" == "Linux" ]; then
    lsb_release -a
    free -m
    lscpu
    df -h --total
else
    echo "Unknown system: $(uname)"
    exit 1
fi