#!/bin/bash

echo "Enter the username for DockerHub Account : "
read UNAME
echo "Enter the password for DockerHub Account : "
read UPASS
echo "Provide value for source organization : "
read SRC
echo "Provide value for destination organization : "
read DEST

# Retrieve a token  
echo "Retrieving token ..."
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# Fetch the name  and privacy of the repository in source organization

CHECK=$(curl https://hub.docker.com/v2/repositories/infrac1/?page_size=100 | jq  '.results[]|"\(.name)=\(.is_private)"')
echo $CHECK


# Get the length of the CHECK variable to iterate number of repositories in source organization
len=${#CHECK}


migrate()
{

echo "Inside Migrate Function"
for i  in ${CHECK}
do
   NAME=$(echo $i | sed -e 's/\"//g' -e 's/=.*//')	
   RES=$(echo $i | sed -e 's/\"//g' -e 's/.*=//g')
   IMAGE_TAGS=$(curl https://hub.docker.com/v2/repositories/${SRC}/${NAME}/tags/?page_size=100 | jq -r '.results|.[]|.name')

 for t in ${IMAGE_TAGS}
 do	   
   for n in ${t}
   do	
      if [ "${RES}" == "false" ]; then
         docker pull ${SRC}/${NAME}:${n}
         docker tag ${SRC}/${NAME} ${DEST}/${NAME}
         docker push ${DEST}/$NAME
      fi
   done
 done
done
}

for itr in len:   
do
  if [ -z "${TOKEN}" ]
  then

       break

  else

       migrate
  fi
done

