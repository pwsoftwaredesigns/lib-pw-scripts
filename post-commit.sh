#!/bin/bash
#
# ******************************************************************************
# @file post-commit.sh
# @brief Firmware versioning script to be executed by the post-commit git hook
#
# ******************************************************************************

if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "post-commit.sh"

#Delete the build version file (because the commit hash was updated)
rm -f "${CONFIG_BUILD_VERSION_FILEPATH}"

#Delete the build info file (new commit ID means the build info is stale)
rm -f "${CONFIG_BUILD_INFO_FILEPATH}"

script_exit