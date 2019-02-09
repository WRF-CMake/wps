#!/bin/bash

# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

set -e

if [ $BUILD_SYSTEM == "cmake" ]; then

    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=install -DWRF_DIR=../../WRF/build \
          -DENABLE_GRIB1=${GRIB1} -DENABLE_GRIB2_PNG=${GRIB2} -DENABLE_GRIB2_JPEG2000=${GRIB2} \
          -DDEBUG_ARCH=ON -DDEBUG_GLOBAL_DEFINITIONS=ON -LA ..
    cmake --build . --target install -- -j2
    cd ..

elif [ $BUILD_SYSTEM == "make" ]; then

    if [[ $OS_NAME == 'linux' ]]; then

        case $MODE in
            serial) cfg=1 ;;
            dmpar)  cfg=3 ;;
            *) echo "Invalid: $MODE" ;;
        esac

        # Need to create symlinked folder hierarchy that WRF expects...
        mkdir netcdf
        ln -s /usr/include netcdf/include
        ln -s /usr/lib/x86_64-linux-gnu netcdf/lib

        export NETCDF=`pwd`/netcdf

        ## As the zlib and PNG libraries are not in a standard path that will be checked automatically by the compiler,
        ## we include them with the JASPER include and library path
        export JASPERLIB="/usr/lib/x86_64-linux-gnu"
        export JASPERINC="/usr/include/jasper -I/usr/include"

    elif [[ $OS_NAME == 'osx' ]]; then

        case $MODE in
            serial) cfg=17 ;;
            dmpar)  cfg=21 ;;
            *) echo "Invalid: $MODE" ;;
        esac

        # see comment in `install-wrf.sh` about `greadlink``
        export NETCDF=$(greadlink -f $(brew --prefix netcdf))

        export JASPERLIB=$(brew --prefix jasper)/lib
        export JASPERINC=$(brew --prefix jasper)/include

    else
        echo "The environment is not recognised"
    fi

    echo "./configure <<< $cfg\n"
    ./configure <<< $cfg$'\n'

    echo "./compile"
    ./compile

    if [ ! -f ungrib.exe ]; then
        exit 1
    fi

else
    echo "Unknown system: ${system}"
    exit 1
fi