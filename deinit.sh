#!/bin/bash
#
# ******************************************************************************
# @file deinit.sh
# @brief Script which deinitializes the project
#
# This script "undoes" opperations performed by init.sh
#
# ******************************************************************************

if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "deinit.sh"

#Delete git hooks
echo "Removing git hooks..."

git_dir=$(git rev-parse --git-dir)
git_hook_dir="${git_dir}/hooks"

rm -f "${git_hook_dir}/post-commit"
rm -f "${git_hook_dir}/post-merge"
rm -f "${git_hook_dir}/pre-commit"
rm -f "${git_hook_dir}/pre-merge-commit"

#Remove local configuration
echo "Removing local configuration files..."
rm -f "${CONFIG_LOCAL_PROJECT_CONFIGURATION_FILEPATH}"
rm -f "${CONFIG_BUILD_VERSION_FILEPATH}"
rm -f "${CONFIG_BUILD_INFO_FILEPATH}"
rm -f "${CONFIG_COMMIT_FLAG_FILEPATH}"
rm -f "${CONFIG_BUILD_FLAG_FILEPATH}"

script_exit