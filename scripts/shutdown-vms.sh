#!/bin/bash

#AZURE CLI
AZ_EXE="az"

RESOURCE_GROUP_NAME_DEPLOY="Alfresco_deployment"


LIST_VMS=$($AZ_EXE vm list -g $RESOURCE_GROUP_NAME_DEPLOY --query "[].id" -o tsv)

echo "Shutting down the following VMs:"
echo ""
$AZ_EXE vm list -g $RESOURCE_GROUP_NAME_DEPLOY --query "[].id"

$AZ_EXE vm deallocate --ids $LIST_VMS --no-wait 1> /dev/null
