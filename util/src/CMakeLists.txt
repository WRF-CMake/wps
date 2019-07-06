# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

# The plotgrids and plotfmt executables are omitted here as they depend
# on the ncarg library (NCAR Graphics) which does not run on Windows.

add_library(util_helpers STATIC
    "${GEOGRID_SRC}/cio.c"
    "${GEOGRID_SRC}/module_debug.F"
    "${GEOGRID_SRC}/misc_definitions_module.F"
    "${GEOGRID_SRC}/constants_module.F"
    "${UNGRIB_SRC}/module_stringutil.F"
    "${METGRID_SRC}/module_date_pack.F"
    "${METGRID_SRC}/gridinfo_module.F"
    "${METGRID_SRC}/read_met_module.F"
    "${METGRID_SRC}/write_met_module.F"
    "${METGRID_SRC}/module_date_pack.F"
    "${METGRID_SRC}/met_data_module.F"
)

add_executable(rd_intermediate rd_intermediate.F)
target_link_libraries(rd_intermediate util_helpers)

add_executable(avg_tsfc avg_tsfc.F)
target_link_libraries(avg_tsfc util_helpers)

add_executable(elev_angle elev_angle.F)

target_include_directories(elev_angle
   PRIVATE ${NETCDF_F77_INCLUDE_DIR}
)

target_link_libraries(elev_angle
   ${NETCDF_LIBRARIES}
   util_helpers
)

add_executable(calc_ecmwf_p calc_ecmwf_p.F)
target_link_libraries(calc_ecmwf_p util_helpers)

add_executable(mod_levs mod_levs.F)
target_link_libraries(mod_levs util_helpers)

add_executable(int2nc int2nc.F)

target_include_directories(int2nc
    PRIVATE ${NETCDF_F77_INCLUDE_DIR}
)

target_link_libraries(int2nc
    ${NETCDF_LIBRARIES}
    util_helpers
)

add_executable(height_ukmo height_ukmo.F)
target_link_libraries(height_ukmo util_helpers)

# IMPORTANT: When changing this list, also change cmake/post_install.
set(utils
    rd_intermediate
    avg_tsfc
    elev_angle
    calc_ecmwf_p
    mod_levs
    int2nc
    height_ukmo
)

set_property(
    TARGET ${utils} util_helpers
    PROPERTY Fortran_FORMAT FREE)

if (WIN32)
    # See cmake/post_install/CMakeLists.txt for why this is necessary.
    set(install_dir .)
else()
    # util is the executables location in WRF's makefiles.
    set(install_dir util)
endif()

install(TARGETS ${utils}
    RUNTIME DESTINATION ${install_dir}
)