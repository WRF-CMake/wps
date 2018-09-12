# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

cmake_minimum_required(VERSION 3.1)

if (ARCH_CUSTOM)
	set(ARCH_PATH "${CMAKE_SOURCE_DIR}/cmake/arch/custom/${ARCH_CUSTOM}.cmake")
	if (NOT EXISTS "${ARCH_PATH}")
		set(ARCH_PATH "${ARCH_CUSTOM}")
	endif()
	message(STATUS "Using ${ARCH_PATH}")
	include(${ARCH_PATH})
	if (NOT DEFINED ENV{CC})
		set(CMAKE_C_COMPILER ${CC})
	endif()
	if (NOT DEFINED ENV{FC})
		set(CMAKE_Fortran_COMPILER ${FC})
	endif()
endif()

project(WPS C Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(WPSHelpers)

enable_testing()

########################
#    User options      #
########################

# https://github.com/llvm-mirror/llvm/blob/632c2834/CMakeLists.txt#L52-L55
set(BUILD_TYPE_VALUES Debug Release)
if (NOT CMAKE_CONFIGURATION_TYPES) # ignore for multi-config generators like MSVC
	if (NOT CMAKE_BUILD_TYPE)
		message(STATUS "No build type selected, default to Release")
		set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type (default Release)" FORCE)
	endif()
	set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${BUILD_TYPE_VALUES})
	list (FIND BUILD_TYPE_VALUES "${CMAKE_BUILD_TYPE}" _index)
	if (${_index} EQUAL -1)
		message(FATAL_ERROR "CMAKE_BUILD_TYPE variable must be one of: ${BUILD_TYPE_VALUES} but is: ${CMAKE_BUILD_TYPE}")
	endif()
endif()

set(ARCH_CUSTOM "" CACHE STRING "Name of custom architecture configuration to use")
option(DISABLE_RUNTIME_CHECKS "Disable compiler runtime checks in Release mode" OFF)
option(DEBUG_ARCH "Print arch files debug information" OFF)
option(DEBUG_GLOBAL_DEFINITIONS "Print global preprocessor definitions applied to all source files" OFF)

# Note that WRF and WPS currently cannot be built without NetCDF support.
set(ENABLE_NETCDF ON)
# Note that only ungrib supports GRIB 2.
option(ENABLE_GRIB1 "Whether to enable GRIB1 support (ungrib always has GRIB1 support)" OFF)
option(ENABLE_GRIB2_PNG "Whether to enable PNG compression support for GRIB2 (in ungrib)" ON)
option(ENABLE_GRIB2_JPEG2000 "Whether to enable JPEG2000 compression support for GRIB2 (in ungrib)" ON)
set(WRF_DIR "" CACHE PATH "Path to the build folder of WRF (via cmake --build .) or to where WRF was installed to (via cmake --build . --target install)")

find_package(WRF REQUIRED CONFIG
	HINTS "${WRF_DIR}/cmake")

set(ENABLE_MPI ${WRF_HAS_MPI})
if (ENABLE_MPI)
	message(STATUS "WRF was compiled with MPI support, enabling MPI for WPS")
else()
	message(STATUS "WRF was NOT compiled with MPI support, disabling MPI for WPS")
endif()

if (ENABLE_GRIB1 AND NOT WRF_HAS_GRIB1)
	message(FATAL_ERROR "WRF was not compiled with GRIB 1 support, cannot use -DENABLE_GRIB1=ON")
endif()

# Note: GRIB 2 support in WPS does not rely on GRIB 2 support in WRF, hence no check.

#########################
#    Compiler flags     #
#########################

if (NOT MINGW AND NOT UNIX)
	message(FATAL_ERROR "Unsupported operating system")
endif()

if (NOT ARCH_CUSTOM)
	set(ARCH_C_VARS debug optimized checked temps other)
	set(ARCH_Fortran_VARS debug optimized preprocess io checked temps other)
	foreach (language C Fortran)
		set(ARCHS
			"${CMAKE_${language}_COMPILER_ID}"
			"${CMAKE_${language}_COMPILER_ID}_${CMAKE_SYSTEM_NAME}"
		)
		list(APPEND ARCHS "${CMAKE_${language}_COMPILER_ID}_${language}")
		if (UNIX)
			list(APPEND ARCHS "${CMAKE_${language}_COMPILER_ID}_${language}_UNIX")
		endif()
		list(APPEND ARCHS "${CMAKE_${language}_COMPILER_ID}_${language}_${CMAKE_SYSTEM_NAME}")
		foreach(ARCH ${ARCHS})
			set(ARCH_PATH "${CMAKE_SOURCE_DIR}/cmake/arch/default/${ARCH}.cmake")
			if (EXISTS ${ARCH_PATH})
				message(STATUS "Using ${ARCH_PATH} (${language})")
				foreach (var ${ARCH_${language}_VARS})
					set(${var} "${${language}_${var}}")
				endforeach()
				include(${ARCH_PATH})
				foreach (var ${ARCH_${language}_VARS})
					set(${language}_${var} "${${var}}")
				endforeach()
			elseif (DEBUG_ARCH)
				message("Not found: ${ARCH_PATH}")
			endif()
		endforeach()
	endforeach()
endif()

if (NOT DEFINED C_debug OR NOT DEFINED C_optimized)
	message(FATAL_ERROR "Missing or incomplete architecture files for C, 'debug' or 'optimized' variable missing")
elseif (NOT DEFINED Fortran_debug OR NOT DEFINED Fortran_optimized)
	message(FATAL_ERROR "Missing or incomplete architecture files for Fortran, 'debug' or 'optimized' variable missing")
elseif (NOT DEFINED Fortran_preprocess OR NOT DEFINED Fortran_io)
	message(FATAL_ERROR "Missing or incomplete architecture files for Fortran, 'preprocess' or 'io' variable missing")
endif()

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${C_checked}")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${C_optimized}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_other}")
set(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} ${Fortran_checked}")
set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} ${Fortran_optimized}")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${Fortran_preprocess} ${Fortran_io} ${Fortran_other}")

if (NOT DISABLE_RUNTIME_CHECKS)
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${C_checked}")
    set(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} ${Fortran_checked}")
endif()

if (SAVE_TEMPS)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_temps}")
	set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${Fortran_temps}")
endif()

if (ENABLE_MPI)
	if (MINGW)
		# TODO look for msmpi and headers
		set(MPI_C_INCLUDE_PATH ${MPI_INCLUDE_PATH})
		set(MPI_C_LIBRARIES ${MPI_C_LIBRARY})
		set(MPI_Fortran_INCLUDE_PATH ${MPI_INCLUDE_PATH})
		set(MPI_Fortran_LIBRARIES ${MPI_Fortran_LIBRARY} ${MPI_C_LIBRARY})
		# needed for MS MPI headers
		set(MPI_C_COMPILE_FLAGS "-D_WIN64")
		set(MPI_Fortran_COMPILE_FLAGS "-fno-range-check")
	else()
		find_package(MPI REQUIRED)
	endif()
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${MPI_C_COMPILE_FLAGS}")
	set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${MPI_Fortran_COMPILE_FLAGS}")
endif()

if (DEBUG_ARCH)
	foreach (language C Fortran)
		message("\n${language} arch variables:")
		foreach (var ${ARCH_${language}_VARS})
			message("${var} = ${${language}_${var}}")
		endforeach()
		foreach (build_type DEBUG RELEASE)
			message("\n${language} ${build_type} flags: ${CMAKE_${language}_FLAGS} ${CMAKE_${language}_FLAGS_${build_type}}")
		endforeach()
	endforeach()
endif()

# If WRF was compiled with OpenMP then it is implicitly linked against the OpenMP
# libraries. These dependencies are lost in the imported WRF targets. In order
# to link against the static WRF libraries we need to enable OpenMP here
# as well. The variable WRF_HAS_OpenMP comes from the WRFConfig.cmake script
# imported during find_package(WRF) above.
# Note that CMake 3.9 provides improved OpenMP integration which would allow to
# get rid of this work-around (e.g. by linking against the OpenMP::OpenMP_<lang>
# imported targets).
if (WRF_HAS_OpenMP)
	find_package(OpenMP REQUIRED)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
	set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}")
endif()

#########################
#      Linker flags     #
#########################

# For consistency with WRF's conventions we use .exe on Linux as well.
set(CMAKE_EXECUTABLE_SUFFIX .exe)

if (NOT ARCH_CUSTOM)
	set(ARCHS)
	foreach (language C Fortran)
		list(APPEND ARCHS "${CMAKE_${language}_COMPILER_ID}")
		if (UNIX)
			list(APPEND ARCHS "${CMAKE_${language}_COMPILER_ID}_UNIX")
		endif()
		list(APPEND ARCHS "${CMAKE_${language}_COMPILER_ID}_${CMAKE_SYSTEM_NAME}")
	endforeach()
	list(REMOVE_DUPLICATES ARCHS)
	foreach(ARCH ${ARCHS})
		set(ARCH_PATH "${CMAKE_SOURCE_DIR}/cmake/arch/default/${ARCH}.cmake")
		if (EXISTS ${ARCH_PATH})
			message(STATUS "Using ${ARCH_PATH} (linker)")
			include(${ARCH_PATH})
		elseif (DEBUG_ARCH)
			message("Not found: ${ARCH_PATH}")
		endif()
	endforeach()
endif()

if (linker)
	set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${linker}")
endif()

if (DEBUG_ARCH)
	message("Linker flags: ${CMAKE_EXE_LINKER_FLAGS}")
endif()

##########################
#     Include paths      #
##########################

# Most executables only need the headers of io_grib_share and don't have to link to the library itself.
# Therefore we make a variable available so that they can do that.
get_target_property(IO_GRIB_SHARE_INCLUDE_DIR WRF::io_grib_share INTERFACE_INCLUDE_DIRECTORIES)

##########################
#  Package dependencies  #
##########################

if (ENABLE_NETCDF)
	find_package(NetCDF REQUIRED COMPONENTS F77 F90)

	# If we link against the static netCDF-C library (currently required on mingw64) then its
	# HDF5 dependency is not linked into the netCDF-C library (not exactly sure why).
	# To fix that we try to import netCDF-C by CMake config file as this has all dependencies defined.
	STRING(REGEX MATCH ".a$" match ${NETCDF_LIBRARY})
	if (match)
		find_package(HDF5 REQUIRED COMPONENTS C HL)
		set(NETCDF_F77_LIBRARIES ${NETCDF_F77_LIBRARIES} ${NETCDF_C_LIBRARIES} ${HDF5_LIBRARIES} ${HDF5_HL_LIBRARIES})
		set(NETCDF_F99_LIBRARIES ${NETCDF_F99_LIBRARIES} ${NETCDF_C_LIBRARIES} ${HDF5_LIBRARIES} ${HDF5_HL_LIBRARIES})
		set(NETCDF_LIBRARIES ${NETCDF_LIBRARIES} ${HDF5_LIBRARIES} ${HDF5_HL_LIBRARIES})
	endif()
endif()

if (ENABLE_GRIB2_PNG)
	find_package(PNG REQUIRED)
	find_package(ZLIB REQUIRED)
endif()

if (ENABLE_GRIB2_JPEG2000)
	find_package (Jasper REQUIRED)
endif()

####################################
#  Common preprocessor definitions #
####################################

add_definitions(
	-D_UNDERSCORE
	-DBYTESWAP
)

if (ENABLE_MPI)
	add_definitions(-D_MPI)
endif()

if (ENABLE_NETCDF)
	add_definitions(-DIO_NETCDF)
endif()

if (ENABLE_GRIB1)
	add_definitions(-DIO_GRIB1)
endif()

if (DEBUG_GLOBAL_DEFINITIONS)
	get_directory_property(defs COMPILE_DEFINITIONS)
	message("${defs}")
endif()

###########################
# Walk the subdirectories #
###########################

# Some helper variables to make cross-referencing easier.
# Normally this is handled by symlinking source files into the folders that need them,
# but we don't rely on that to make Windows people's lives easier.
set(GEOGRID_SRC "${CMAKE_SOURCE_DIR}/geogrid/src")
set(METGRID_SRC "${CMAKE_SOURCE_DIR}/metgrid/src")
set(UNGRIB_SRC "${CMAKE_SOURCE_DIR}/ungrib/src")

add_subdirectory(geogrid)
add_subdirectory(ungrib)
add_subdirectory(metgrid)
add_subdirectory(util)
add_subdirectory(cmake/post_install)

install(FILES link_grib.py DESTINATION .)