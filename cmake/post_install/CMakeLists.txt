# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

# See https://gitlab.kitware.com/cmake/cmake/issues/17989 for why this code is in a separate file/folder.

if (WIN32)
	# fixup_bundle needs a "primary executable" but considers all
	# executables in the same folder.
	# On Windows, fixup_bundle does not work if some executables
	# are in subfolders of the main executable as this will lead
	# to an error during bundle verification. This is fine as we
	# don't want to copy DLLs into multiple folders anyway.
	set(app	"\${CMAKE_INSTALL_PREFIX}/geogrid.exe")

	# This copies all necessary DLLs next to the executables.
	install(CODE "
		include(BundleUtilities)
		fixup_bundle(\"${app}\" \"\" \"\")
		" COMPONENT Runtime)
endif()
