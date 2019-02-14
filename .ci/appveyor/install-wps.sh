#!/bin/bash

# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

set -ex

SCRIPTDIR=$(dirname "$0")
cd $SCRIPTDIR/../..

if [ $BUILD_SYSTEM == "CMake" ]; then

    mkdir build && cd build

    # TODO remove -DMPI_* variables once these get auto-detected
    # Note that -DMODE alone decides whether MPI is used or not.
    cmake -G "MSYS Makefiles" \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=install -DWRF_DIR=../../WRF/build \
        -DENABLE_GRIB1=${GRIB1} -DENABLE_GRIB2_PNG=${GRIB2} -DENABLE_GRIB2_JPEG2000=${GRIB2} \
        -DMPI_INCLUDE_PATH=$MINGW_PREFIX/include -DMPI_C_LIBRARY="$MSMPI_LIB64/msmpi.lib" \
        -DMPI_Fortran_LIBRARY="$MSMPI_LIB64/msmpifec.lib" \
        -DDEBUG_ARCH=ON -DDEBUG_GLOBAL_DEFINITIONS=ON -LA ..

    # Sometimes there are intermittent issues (e.g. related to locked files).
    # The construction below means "try with 2 cores, and if it fails, try again with 1 core".
    cmake --build . --target install -- -j2 \
        || cmake --build . --target install \
        || cmake --build . --target install

else
    echo "Unknown system: ${BUILD_SYSTEM}"
    exit 1
fi