#!/usr/bin/env bash

# WRF-CMake (https://github.com/WRF-CMake/wps).
# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

set -ex

SCRIPTDIR=$(dirname "$0")
cd $SCRIPTDIR/../..

if [ $BUILD_SYSTEM == "CMake" ]; then

    mkdir build && cd build

    cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=install -DWRF_DIR=../../WRF/build \
          -DENABLE_GRIB1=${GRIB1} -DENABLE_GRIB2_PNG=${GRIB2} -DENABLE_GRIB2_JPEG2000=${GRIB2} \
          -DDEBUG_ARCH=ON -DDEBUG_GLOBAL_DEFINITIONS=ON -LA ..
    
    export VERBOSE=1
    cmake --build . --target install -- -j2

elif [ $BUILD_SYSTEM == "Make" ]; then

    # See install-wrf.sh in WRF repository.
    export PATH=$(pwd)/../WRF/compilers:$PATH

    # WRF does not use CC/FC, so let's check what gcc/gfortran actually points to.
    which gcc
    gcc --version
    which gfortran
    gfortran --version

    if [ "$(uname)" == "Linux" ]; then

        case $MODE in
            serial) cfg=1 ;;
            dmpar)  cfg=3 ;;
            *) echo "Invalid: $MODE" ;;
        esac

        if [ "$(lsb_release -c -s)" == "trusty" -o "$(lsb_release -i -s)" == "CentOS" ]; then
            export NETCDF=/usr
        else
            # Need to create symlinked folder hierarchy that WRF expects...
            mkdir netcdf
            ln -s /usr/include netcdf/include
            ln -s /usr/lib/x86_64-linux-gnu netcdf/lib

            export NETCDF=`pwd`/netcdf
            ls -al $NETCDF/lib
        fi

        ## As the zlib and PNG libraries are not in a standard path that will be checked automatically by the compiler,
        ## we include them with the JASPER include and library path
        if [ "$(lsb_release -i -s)" == "CentOS" ]; then
            export JASPERLIB="/usr/lib64"
        else
            export JASPERLIB="/usr/lib/x86_64-linux-gnu"
        fi
        export JASPERINC="/usr/include/jasper -I/usr/include"

    elif [ "$(uname)" == "Darwin" ]; then

        case $MODE in
            serial) cfg=17 ;;
            dmpar)  cfg=21 ;;
            *) echo "Invalid: $MODE" ;;
        esac

        # see comment in `install-wrf.sh` about `greadlink``
        export NETCDF=$(greadlink -f $(brew --prefix netcdf))

        export JASPERLIB=$(brew --prefix jasper)/lib
        export JASPERINC=$(brew --prefix jasper)/include

        # Otherwise libpng is not found.
        # Note that LIBRARY_PATH and CPATH applies to all compiler invocations.
        export LIBRARY_PATH=/usr/local/lib
        export CPATH=/usr/local/include

    else
        echo "The environment is not recognised"
        exit 1
    fi

    echo "./configure <<< $cfg\n"
    ./configure <<< $cfg$'\n'

    echo "==== configure.wps ===="
    cat configure.wps
    echo "==== end configure.wps ===="

    echo "./compile"
    ./compile

    if [ ! -f geogrid.exe ]; then
        exit 1
    fi

    if [ ! -f ungrib.exe ]; then
        exit 1
    fi

    if [ ! -f metgrid.exe ]; then
        exit 1
    fi

else
    echo "Unknown system: $(uname)"
    exit 1
fi