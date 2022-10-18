# Versioning Scripts

## .twproject.example

In order to use any of the scripts withing a project, the project must contain
a file named .twproject in the root directory of the git repository.  The
example file provided here shows all the fields within this file and provides
their standard default values.

## _common.sh

This script contains common configuration and functions for the other scripts.
It is "included" (i.e., sourced) by the other scripts.

## init.sh

**Every** user/developer of this project must first run the init.sh script 
within their local copy to properly initialize the project based upon its
settings and to configure the other scripts to work correctly.

## deinit.sh

Undoes the operations performed by init.sh

## pre-build.sh

Script executed by the compiler before it begins to build the project.  This
script updates the version header file with the current version and git
information.

## post-build.sh

Script to be executed by the compiler after the project has been 
**successfully** built.

## begin-release.sh

This script helps to automate the process of creating a release of the project.

In order to release the fimrware image, the following requirements/prerequisates
must be met:
 - Must be in the development branch

The following procedure is followed when releasing the project:
 1. Request the new version number
    - Must be GREATER than the current version number
 2. Create a new branch named [release_branch_prefix]/[version]
 3. Update version file
 4. Commit changes to version file
 5. Perform test cases and minor pre-release tweaks here.
    Ensure that the project compiles
 6. Update the RELEASE.md file
 7. Commit changes to files
 8. Merge changes with [production_branch]
 9. Tag commit with version number
 10. Merge release branch with development branch
 11. Delete the release branch
 
## end-release.sh

This script is executed by the user after a preceding execution of
begin-release.sh.

See begin-release.sh for the release procedure.  This script performs steps
(6) to (11) of this procedure.

## export.sh

The script takes an input file (usually the compiled binary) and makes a copy
of it renamed to to include the version information of the build.