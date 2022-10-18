#!/bin/bash
#
# ******************************************************************************
# @file discard-release.sh
# @brief Script which discards an in-progress release
# ******************************************************************************

#Include '_common.sh'
if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

script_begin "discard-release.sh"

#-------------------------------------------------------------------------------

#Verify that a release is already in progress
if [ ! -e "${CONFIG_RELEASE_FLAG_FILEPATH}" ]; then
	script_exit_error "No release in progress"
fi

git_local_branch="$(git rev-parse --abbrev-ref HEAD)"

#Verify required configuration values
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_branch_prefix"
testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "develop_branch"

#Read configuration values
config_release_branch_prefix=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_branch_prefix")
config_develop_branch=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "develop_branch")

#Verify prerequisates
echo "${git_local_branch}" | grep "${config_release_branch_prefix}/" > /dev/null
if [ $? -ne 0 ]; then
	script_exit_error "Not in '${config_release_branch_prefix}/*' branch"
fi

#-------------------------------------------------------------------------------

read -p "Are you sure you want to discard this release? [yes/no]: " confirm
if [[ ${confirm} != "yes" ]]; then
	script_exit_error "Cancelled"
fi

#Reset current branch
git reset --hard

#Checkout development branch
git checkout "${config_develop_branch}"

#Force delete release branch
git branch -D "${git_local_branch}"

#Clear release flag
rm -f "${CONFIG_END_RELEASE_FLAG_FILEPATH}"
rm -f "${CONFIG_RELEASE_FLAG_FILEPATH}"
rm -f "${CONFIG_RELEASE_CHANGES_FILEPATH}"

#-------------------------------------------------------------------------------

script_exit