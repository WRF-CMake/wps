# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

# See https://gitlab.kitware.com/cmake/cmake/issues/17989 for why this code is in a separate file/folder.

if (WIN32)
	set(apps
		"\${CMAKE_INSTALL_PREFIX}/geogrid.exe"
		"\${CMAKE_INSTALL_PREFIX}/ungrib.exe"
		"\${CMAKE_INSTALL_PREFIX}/metgrid.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/rd_intermediate.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/avg_tsfc.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/elev_angle.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/calc_ecmwf_p.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/mod_levs.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/int2nc.exe"
		"\${CMAKE_INSTALL_PREFIX}/util/height_ukmo.exe"
		)

	# This copies all necessary DLLs next to the executables.
	foreach (app ${apps})
		install(CODE "
			include(BundleUtilities)
			fixup_bundle(\"${app}\" \"\" \"\")
			" COMPONENT Runtime)
	endforeach()
endif()
