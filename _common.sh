#!/bin/bash
#
# ******************************************************************************
# @file _common.sh
# @brief Common include file for all scripts
#
# ******************************************************************************

#Global check if inside git repo
git rev-parse --is-inside-work-tree > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "ERROR: Not within a git repository!"
	exit 2
fi

#===============================================================================
# CONFIGURATION GLOBALS
#===============================================================================

#Current version of these scripts
CONFIG_SCRIPT_VERSION=4

CONFIG_INITIAL_VERSION="0.0.0"
CONFIG_INITIAL_BUILD_VERSION="0"
EOL="\r\n"
CONFIG_GIT_IGNORE_EXTENSION=".local"

#===============================================================================

#The working directory of the script
CONFIG_WORKING_DIRECTORY_PATH="$(pwd)"

#The root path of the git repository
CONFIG_GIT_PROJECT_ROOT_PATH="$(git rev-parse --show-toplevel)"

#How wide is the terminal?
CONFIG_COLUMNS=80
if [ command -v tput &> /dev/null ]; then
	CONFIG_COLUMNS=$(tput cols)
fi

#Path to the project configuration file (tracked by git)
CONFIG_PROJECT_CONFIGURATION_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twproject"

#Path to the LOCAL project configuration file (not tracked by git)
CONFIG_LOCAL_PROJECT_CONFIGURATION_FILEPATH="${CONFIG_PROJECT_CONFIGURATION_FILEPATH}${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to the cache file containing the current project version (tracked by git)
CONFIG_VERSION_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twversion"

#Path to file containing the project build version (not tracked by git)
CONFIG_BUILD_VERSION_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twbuildversion${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to file which caches information from the last build
CONFIG_BUILD_INFO_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twbuildinfo${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to flag used to indicate if a commit is in progress (pre-commit has been executed)
CONFIG_COMMIT_FLAG_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twcommitflag${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to flag used to indicate if a build is in progress (pre-build has been executed)
CONFIG_BUILD_FLAG_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twbuildflag${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to flag used to indicate if a release is in progress (begin-release has been executed)
CONFIG_RELEASE_FLAG_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twreleaseflag${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to flag used to indicate if a end release is in progress (end-release has been executed)
CONFIG_END_RELEASE_FLAG_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/.twendreleaseflag${CONFIG_GIT_IGNORE_EXTENSION}"

#Path to a local/temporary file which list commits since last release
CONFIG_RELEASE_CHANGES_FILEPATH="${CONFIG_GIT_PROJECT_ROOT_PATH}/CHANGES.md${CONFIG_GIT_IGNORE_EXTENSION}"

#Marker used to determine if the user has modified the release notes file
CONFIG_RELEASE_NOTES_MARKER="<<<<--REMOVE THIS LINE-->>>>"

#===============================================================================
# FUNCTIONS
#===============================================================================

#-----[ FUNCTION: echoerr( [string] ) ]-----------------------------------------
echoerr() { 
    echo -e "\033[0;31m$@\033[0m" 1>&2; 
}

#-----[ FUNCTION: script_begin( [title] ) ]-------------------------------------
script_begin() {
	local title=$1
	
	printf "%${CONFIG_COLUMNS}s\n" " " | tr ' ' '-' 
	printf "%*s\n" $(((${#title}+${CONFIG_COLUMNS})/2)) "${title}"
	printf "%${CONFIG_COLUMNS}s\n\n" " " | tr ' ' '-' 
}

#-----[ FUNCTION: script_exit( [code] ) ]---------------------------------------
script_exit() {
	local code=0

	if [ -n ${1+set} ]; then
		code=$1
	fi
	
	printf "\n"
	printf "%${CONFIG_COLUMNS}s\n" " " | tr ' ' '-' 
	
	exit ${code}
}

#-----[ FUNCTION: script_exit_error( [message] (code) ) ]-----------------------
script_exit_error() {
	local msg="$1"
	local code=1
	
	 if [ "$#" -eq 2 ]; then
    	code="$2"
    fi
	
	echoerr "${msg}"
	
	script_exit ${code}
}

#-----[ FUNCTION: test_return( $? ) ]-------------------------------------------
test_return() {
	local ret=$?
	local msg=$1

	if [ ${ret} -ne 0 ]; then
		script_exit_error "${msg}" ${ret}
	fi
}

#-----[ FUNCTION: check_and_init_file( [file path] (initial value) ) ]----------
check_and_init_file() {
	local filepath="$1"
	local init_value="$2"

	if [ ! -e "${filepath}" ]; then
        #Create directories (if necessary)
        mkdir -p $(dirname ${filepath})
        
        #Init file
		printf "${init_value}" > "${filepath}"
	fi
}

#-----[ FUNCTION: testfile( [file path] ) ]-------------------------------------
testfile_or_exit() {
	local filepath="$1"
	if [ ! -e "${filepath}" ]; then
		script_exit_error "File '${filepath}' does not exist!"
	fi
}

#-----[ FUNCTION: readfile( [file path] (default value) ]-----------------------
readfile() {
	local file="$1"
	local default=""
	local val;
	
	#Optional argument 'default value'
	if [ "$#" -eq 2 ]; then
    	default="$2"
    fi
    
    if [ -e "${file}" ]; then
    	val=$(cat "${file}")
    else
  		val="${default}"
	fi
	
	#Return value to caller
    echo "${val}"
}

#-----[ FUNCTION: readconfig( [file] [key] (default value) ) ]------------------
#See https://unix.stackexchange.com/questions/346878/can-i-get-the-exit-code-from-a-sub-shell-launched-with-command
readconfig() {
    local file="$1"
    local key="$2"
    local default=""
    local val;
    
    if [ "$#" -eq 3 ]; then
    	default="$3"
    fi
    
    if [ -e "${file}" ]; then
	    #Check if key exists
	    grep -x "${key}=.*" "${file}" &> /dev/null
	    if [ $? -eq 0 ]; then
	    	#Get value from configuration file
	    	val=$(grep -x "${key}=.*" "${file}" | cut -d'=' -f2- )
	    else
	  		#Use default value
	  		val="${default}"
		fi
	else
		#Use default value
	  	val="${default}"
	fi
    
    #Return value to caller
    echo "${val}"
}

#-----[ FUNCTION: testconfig( [file] [key] ) ]----------------------------------
testconfig() {
    local file="$1"
    local key="$2"
       
    if [ -e "${file}" ]; then
	    #Check if key exists
	    grep -w "${key}" "${file}" &> /dev/null
		exit $?
	else
		exit 1
	fi
}

#-----[ FUNCTION: testconfig( [file] [key] ) ]----------------------------------
testconfig_or_exit() {
	local file="$1"
    local key="$2"
    
    if [ -e "${file}" ]; then
		$(testconfig "${file}" "${key}")
		test_return "'${file}' does not contain configuration key '${key}'"
	else
		script_exit_error "Configuration file '${file}' does not exist"
	fi
}

#-----[ FUNCTION: writeconfig( [file] [key] [value] ) ]-------------------------
writeconfig() {
    local file="$1"
    local key="$2"
    local value="$3"
    
    check_and_init_file "${file}" ""
    
    #Check if key exists
    grep -x "${key}=.*" "${file}" &> /dev/null
    if [ $? -eq 0 ]; then
        #Update value in configuration file if it already exists
        #See https://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern for the following line
        local _escaped_value=$(printf '%s\n' "${value}" | sed -e 's/[\/&]/\\&/g')
        sed -i "s/\(${key}=\)\(.*\)/\1${_escaped_value}/" "${file}"
    else
        #Add new pair to config file
        printf "${key}=${value}${EOL}" >> "${file}"
    fi
}

#-----[ FUNCTION: check_for_init() ]--------------------------------------------
check_for_init() {
	local init=$(readconfig "${CONFIG_LOCAL_PROJECT_CONFIGURATION_FILEPATH}" init 0)
	
    if [ ${CONFIG_SCRIPT_VERSION} -gt ${init} ]; then
        script_exit_error "Not initialized! Please run init.sh first."
    fi
}

#------[ FUNCTION: splitversion ( [in:version string] [out:major] [out:minor] [out:patch] ) ]-----
splitversion() {
	local _input="$1"
	
	local _major="$2"
	local _minor="$3"
	local _patch="$4"
	
	eval ${_major}=$(echo "${_input}" | cut -d'.' -f1 -s)
	eval ${_minor}=$(echo "${_input}" | cut -d'.' -f2 -s)
	eval ${_patch}=$(echo "${_input}" | cut -d'.' -f3 -s)
}

#------[ FUNCTION: joinversion ( [out:string] [in:major] [in:minor] [in:patch] ) ]-----
joinversion() {
	local _output="$1" 
	
	local _major="$2"
	local _minor="$3"
	local _patch="$4"
	
	eval ${_output}="${_major}.${_minor}.${_patch}"
}

#-----[ FUNCTION: git_test_uncomitted_changes() ]-------------------------------
git_test_uncomitted_changes() {
	#Verify that there are no unstaged/uncommitted changes
	git update-index -q --refresh

	git diff-files --quiet --
	if [ $? -ne 0 ]; then
		return 1
	fi

	git diff-index --cached --quiet HEAD --
	if [ $? -ne 0 ]; then
		return 1
	fi
	
	return 0
}

#-----[ FUNCTION: git_branch_name() ]-------------------------------------------
#Get the name of the current git branch
#See https://stackoverflow.com/questions/18659425/get-git-current-branch-tag-name
git_branch_name() {
	git symbolic-ref -q --short HEAD || git describe --tags --exact-match
}