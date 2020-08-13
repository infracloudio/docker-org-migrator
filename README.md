# docker-org-migrator

**git clone https://github.com/infracloudio/docker-org-migrator.git**

## Usage
Execution of script:

#### *with short options*

**./org-repo-migrator.sh -s="<source-org>" -d="<destination-org>" -sr="<repo names to skip>" -ip="<true/false>"**
  
#### *with long options*  
**./org-repo-migrator.sh --src="<source-org>" --dest="<destination-org>" --skip-repos="<repo names to skip>" --include-private="<true/false>"**
  
 ### Parameters
 -s/--src = DockerHub source organization from where the repositories are to be migrated <br />
 -d/--dest = DockerHub destination organization where the repositories are migrated <br />
 -sr/--skip-repos = List of repo names given in "", to skip for migration <br />
 -ip/--include-private = provide "false", if only public repositories are to be migrated <br />
 
 
> example:

> ./org-repo-migrator.sh -s/--src="source-org" -d/--dest="remote-org" --skip-repos="repo 1 repo 2 ..repo n" --include-private="false"
  


