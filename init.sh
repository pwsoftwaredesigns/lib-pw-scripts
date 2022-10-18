#!/bin/bash
#
# ******************************************************************************
# @file init.sh
# @brief Script which initializes the project
#
# ******************************************************************************

if [ ${BASH_SOURCE+set} ]; then
	source "$(dirname ${BASH_SOURCE[0]})/_common.sh"
else
	source "$(dirname $0)/_common.sh"
fi

#-------------------------------------------------------------------------------

arg_force=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      arg_force=1
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

#-------------------------------------------------------------------------------

script_begin "init.sh"

config_init_version=$(readconfig "${CONFIG_LOCAL_PROJECT_CONFIGURATION_FILEPATH}" "init" 0)
echo "Current Project Settings Version: ${config_init_version}"

if [ ${arg_force} -eq 1 ]; then
	echo "NOTE: Forcing initialization"	
fi

if [ ${arg_force} -eq 1 ] || [ ${CONFIG_SCRIPT_VERSION} -gt ${config_init_version} ]; then
	echo "NOTE: Update Required"
	echo ""
	echo "Configuring project..."
	
	#Check for required project configuration values
	testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "production_branch"
	testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_branch_prefix"
	testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "develop_branch"
	testconfig_or_exit "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "version_header_filepath"
	
	#Read configuration values
	config_production_branch=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "production_branch")
	config_release_branch_prefix=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "release_branch_prefix")
	config_develop_branch=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "develop_branch")
	config_version_header_filepath=$(readconfig "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "version_header_filepath")
	#config_version_header_filepath=$(realpath -m --relative-to "${CONFIG_PROJECT_CONFIGURATION_FILEPATH}" "${config_version_header_filepath}")
	config_version_header_dirpath=$(dirname "${config_version_header_filepath}")
	
	mkdir -p "${config_version_header_dirpath}"
		
	#---------------------------------------------------------------------------
	
	echo ""
	echo "Configuring git..."
	
	#Ensure that commits to standard branches are NOT fast forwarded
	#This makes tracking of version merges easier when viewing git history
	git config branch.${config_production_branch}.mergeoptions "--no-ff"
	git config branch.${config_release_branch_prefix}.mergeoptions "--no-ff"
	git config branch.${config_develop_branch}.mergeoptions "--no-ff"
    
    #---------------------------------------------------------------------------
    
    echo ""
    echo "Updating .gitignore..."
    
    gitignore_filepath="${CONFIG_GIT_PROJECT_ROOT_PATH}/.gitignore"
    
    check_and_init_file "${gitignore_filepath}"
    
    #Check for "${CONFIG_GIT_IGNORE_EXTENSION}" in .gitignore
    grep "${CONFIG_GIT_IGNORE_EXTENSION}" "${gitignore_filepath}" &> /dev/null
    if [ $? -ne 0 ]; then
        #Append to gitignore
        printf "${EOL}#AUTOMATICALLY ADDED BY INIT.SH${EOL}*${CONFIG_GIT_IGNORE_EXTENSION}${EOL}" >> "${gitignore_filepath}"
    fi
    
    #See https://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
    #version_header_filepath_rel="$(realpath -m --relative-to ${CONFIG_GIT_PROJECT_ROOT_PATH} ${config_version_header_filepath})"

    grep "${config_version_header_filepath}" "${gitignore_filepath}" &> /dev/null
    if [ $? -ne 0 ]; then
        #Append to gitignore
        printf "${EOL}#AUTOMATICALLY ADDED BY INIT.SH${EOL}${config_version_header_filepath}${EOL}" >> "${gitignore_filepath}"
    fi
    
    
    #---------------------------------------------------------------------------
    
    #Check if initial commit has been made
	git rev-parse --verify HEAD > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		
		echo ""
		echo "Performing initial commit..."
		
		#Create version file
		check_and_init_file "${CONFIG_VERSION_FILEPATH}" "${CONFIG_INITIAL_VERSION}"
		
		git add --all
		
		#Set initial branch name to ${config_production_branch}
		#See https://stackoverflow.com/questions/11225105/is-it-possible-to-specify-branch-name-on-first-commit-in-git
		git symbolic-ref HEAD refs/heads/"${config_production_branch}"
		git commit -m "Initial commit"
		git tag "v${CONFIG_INITIAL_VERSION}"
	
		#Switch to 'minor' branch
		git checkout -b "${config_develop_branch}"
	fi
	
	#---------------------------------------------------------------------------
	
	echo ""
	echo "Adding git hooks..."
	
	#The path to the '.git' directory
	git_dir=$(git rev-parse --git-dir)
	git_hook_dir="${git_dir}/hooks"
	
	script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
	
	printf "#!/bin/sh${EOL}\"${script_dir}/post-commit.sh\"${EOL}if [ \$? -ne 0 ]; then${EOL} exit 1${EOL}fi${EOL}" > "${git_hook_dir}/post-commit"
	printf "#!/bin/sh${EOL}\"${script_dir}/post-commit.sh\"${EOL}if [ \$? -ne 0 ]; then${EOL} exit 1${EOL}fi${EOL}" > "${git_hook_dir}/post-merge"
	
	printf "#!/bin/sh${EOL}\"${script_dir}/pre-commit.sh\"${EOL}if [ \$? -ne 0 ]; then${EOL} exit 1${EOL}fi${EOL}" > "${git_hook_dir}/pre-commit"
	printf "#!/bin/sh${EOL}\"${script_dir}/pre-commit.sh\"${EOL}if [ \$? -ne 0 ]; then${EOL} exit 1${EOL}fi${EOL}" > "${git_hook_dir}/pre-merge-commit"
		
	#---------------------------------------------------------------------------
	
	#Set init configuration value
	writeconfig "${CONFIG_LOCAL_PROJECT_CONFIGURATION_FILEPATH}" "init" "${CONFIG_SCRIPT_VERSION}"
	
else

	echo "No initialization required"
	
fi

script_exit