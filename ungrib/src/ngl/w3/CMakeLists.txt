# WRF-CMake (https://github.com/WRF-CMake/wps).
# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

if (APPLE)
    add_definitions(-DMACOS)
endif()

set(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/mod)

add_library(w3 STATIC
    bacio.v1.3.c
    baciof.f
    baciof.h
    clib.h
    errexit.c
    errmsg.f
    fparsei.f
    fparser.f
    gbytes_char.f
    gbytes.f
    getbit.f
    getgb.f
    getgb1r.f
    getgb1re.f
    getgb1s.f
    getgbe.f
    getgbeh.f
    getgbem.f
    getgbemh.f
    getgbemp.f
    getgbens.f
    getgbep.f
    getgbex.f
    getgbexm.f
    getgbh.f
    getgbm.f
    getgbmh.f
    getgbmp.f
    getgbp.f
    getgi.f
    getgir.f
    idsdef.f
    instrument.f
    iw3jdn.f
    ixgb.f
    lengds.f
    pdsens.f
    pdseup.f
    putgb.f
    putgbe.f
    putgben.f
    putgbens.f
    putgbex.f
    putgbn.f
    r63w72.f
    sbyte.f
    sbytes.f
    start.f
    summary.f
    w3difdat.f
    w3doxdat.f
    w3fi01.f
    w3fi58.f
    w3fi59.f
    w3fi63.f
    w3fi68.f
    w3fi71.f
    w3fi72.f
    w3fi73.f
    w3fi74.f
    w3fi75.f
    w3fi76.f
    w3fi82.f
    w3fi83.f
    w3fs21.f
    w3fs26.f
    w3locdat.f
    w3log.f
    w3movdat.f
    w3reddat.f
    w3tagb.f
    w3utcdat.f
)

set_property(TARGET w3 PROPERTY Fortran_FORMAT FIXED)

target_include_directories(w3
    INTERFACE ${CMAKE_Fortran_MODULE_DIRECTORY}
)