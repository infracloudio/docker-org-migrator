This repository consist of a shell script file that can be used to migrate the public repositories from source to destination organization.

## Installation

TODO:

### git clone the url

https://github.com/infracloudio/docker-org-migrator.git

## Usage

Execution of script:

./org-repo-migrator.sh -s/--src="<source-org>" -d/--dest="<destination-org>" -sr/--skip-repos="<repo names to skip>" -ip/--include-private="<true/false>"
  
 ### Parameters
  -s/--src = DockerHub source organization from where the repositories are to be migrated <br />
 -d/--dest = DockerHub destination organization where the repositories are migrated <br />
 -sr/--skip-repos = List of repo names given in "", to skip for migration <br />
 -ip/--include-private = provide "false", if only public repositories are to be migrated <br />
 
 
  
