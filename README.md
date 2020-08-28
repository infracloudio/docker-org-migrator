# docker-org-migrator
## Usage
### Using Help Command:

<!-- Code Blocks -->
```bash
$ ./org-repo-migrator.sh -h

  ./org-repo-migrator.sh [OPTIONS] VALUE

  example (using short-args): 
  ./org-repo-migrator.sh -s=",source-organization" -d="destination-organization" -sr="repo 1 repo 2 ..repo n" 

  example (using long-args):
  ./org-repo-migrator.sh -src=",source-organization" -dest="destination-organization" --skip-repos="repo 1 repo 2 ..repo n"


  Options:
  -s, --src               Name of the source organization from where the repository needs to be pulled for migration
  -d, --dest              Name of the destination organization where the repository needs to be migrated
  -sr, --skip-repos       List of repos to include for migration, if none is provided results in inclusion of all the repos
```

## Execution of script:

#### Fetch token 
  Export below environment variables to fetch token:

```bash  
    export DOCKER_USERNAME="<dockerhub-username>"
```
```bash
    export DOCKER_PASSWORD="<dockerhub-password>"
```

If no token is provided then script stops execution 

#### with short options

./org-repo-migrator.sh -s="" -d="" -sr=""
```bash
$ ./org-repo-migrator.sh -s="<source-org>" -d="<destination-org>" -sr="<repo names to skip>"
```
#### with long options

./org-repo-migrator.sh --src="" --dest="" --skip-repos=""
``` bash
$ ./org-repo-migrator.sh --src="<source-org>" --dest="<destination-org>" --skip-repos="<repo names to skip>"
```
## Parameters

-s/--src = DockerHub source organization from where the repositories are to be migrated <br/>
-d/--dest = DockerHub destination organization where the repositories are migrated <br/>
-sr/--skip-repos = List of repo names given in "", to skip for migration <br/>
### example:
```bash
$ ./org-repo-migrator.sh -s/--src="source-org" -d/--dest="remote-org" --skip-repos="repo 1 repo 2 ..repo n"
```
_--skip-repos_ can be skipped to include all the repositories
