#!/bin/bash
#set -x
begin=$(date +"%s")

# Adjust the following settings
NEXUS_FILE="$HOME/.nexus.dat"
AZURE_FILE="$HOME/.az.dat"
DOMAIN_NAME_LABEL="alfresco61-demo"
RESOURCE_GROUP_NAME_IMG="Alfresco_6.1_Demo_images"
RESOURCE_GROUP_NAME_DEPLOY="Alfresco_deployment"
LOCATION="uksouth"

# Packer
PACKER_EXE="packer"
export PACKER_LOG=0
#export PACKER_LOG_PATH="packerlog.txt"

# Terraform global variables
export TF_VAR_DOMAIN_NAME_LABEL=$DOMAIN_NAME_LABEL
export TF_VAR_LOCATION=$LOCATION
export TF_VAR_RESOURCE_GROUP_IMAGES=$RESOURCE_GROUP_NAME_IMG
export TF_VAR_RESOURCE_GROUP_DEPLOYMENT=$RESOURCE_GROUP_NAME_DEPLOY
#log levels TRACE, DEBUG, INFO, WARN or ERROR
export TF_LOG="DEBUG"
export TF_LOG_PATH="terraform.log"

ANSIBLE_DOWNLOAD_FILES_DIR="./ansible-download-files"
ANSIBLE_IMAGES_DIR="./ansible-images"

#Frontend
PACKER_FRONTEND_FILE="./packer-template-frontend.json"
PACKER_FRONTEND_IMG_NAME="AlfrescoFrontendImage"

#DB
PACKER_DB_FILE="./packer-template-db.json"
PACKER_DB_IMG_NAME="DBImage"

#Insight Engine
PACKER_INSIGHT_FILE="./packer-template-insight-engine.json"
PACKER_INSIGHT_IMG_NAME="InsightEngineImage"

#Activemq
PACKER_ACTIVEMQ_FILE="./packer-template-activemq.json"
PACKER_ACTIVEMQ_IMG_NAME="ActivemqImage"

#Transformation Service
PACKER_TRANSFORMATION_FILE="./packer-template-transform-service.json"
PACKER_TRANSFORMATION_IMG_NAME="TransformationServiceImage"

function nexus_credentials(){
   echo ""
   echo "Introduce the password for the Nexus credentials file"
   echo ""
   CREDENTIALS=$(openssl enc -aes-256-cbc -d -in $NEXUS_FILE)
   export NEXUS_USER=$(echo $CREDENTIALS|awk -F':' '{print $1}')
   export NEXUS_PASSWORD=$(echo $CREDENTIALS|awk -F':' '{print $2}')
}

function azure_credentials(){
  echo ""
  echo "Introduce the password for the Azure credentials file"
  echo ""
  CREDENTIALS=$(openssl enc -aes-256-cbc -d -in $AZURE_FILE)
  export TF_VAR_CLIENT_ID="$(echo $CREDENTIALS|jq -r '.client_id')"
  export TF_VAR_CLIENT_SECRET="$(echo $CREDENTIALS|jq -r '.client_secret')"
  export TF_VAR_SUBSCRIPTION_ID="$(echo $CREDENTIALS|jq -r '.subscription_id')"
  export TF_VAR_TENANT_ID="$(echo $CREDENTIALS|jq -r '.tenant_id')"
}

function create_image (){
  # Validate the packer template
  if ! $PACKER_EXE validate $1; then
    echo "Template $1 not valid!"
    exit 1
  fi
  
  echo ""
  echo "#####################################"
  echo "Creating image $2"
  echo "#####################################"
  echo ""
  begin_image=$(date +"%s")

  # Create the image
  $PACKER_EXE build -on-error=ask $1
  termin_image=$(date +"%s")
  difftimelps_image=$(($termin_image-$begin_image))

  echo ""
  echo "##################"
  echo "$(($difftimelps_image / 60)) minutes and $(($difftimelps_image % 60)) seconds elapsed for $2 image creation."
  echo "##################"
   

  if [ "$?" -ne 0 ]; then
    exit 1
  fi
}

function check_image_exist(){
   az image list |grep name |grep "$1" 1> /dev/null 2>&1
}

function create_images (){
   echo "" 
   echo "#############################################################"
   echo "Creating Images"
   echo "#############################################################"
   echo ""
   begin_images=$(date +"%s")

   az group list | grep name| grep $RESOURCE_GROUP_NAME_IMG 1> /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      az group create -n $RESOURCE_GROUP_NAME_IMG --location $LOCATION
   else
      echo "Resource Group $RESOURCE_GROUP_NAME_IMG already exists... skipping creation"
   fi

   check_image_exist $PACKER_FRONTEND_IMG_NAME
   if [ "$?" -ne 0 ]; then
      create_image $PACKER_FRONTEND_FILE $PACKER_FRONTEND_IMG_NAME
   else
      echo "Image $PACKER_FRONTEND_IMG_NAME already exist... skipping build"
   fi

   check_image_exist $PACKER_DB_IMG_NAME
   if [ "$?" -ne 0 ]; then
      create_image $PACKER_DB_FILE $PACKER_DB_IMG_NAME
   else
      echo "Image $PACKER_DB_IMG_NAME already exist... skipping build"
   fi

   check_image_exist $PACKER_INSIGHT_IMG_NAME
   if [ "$?" -ne 0 ]; then
      create_image $PACKER_INSIGHT_FILE $PACKER_INSIGHT_IMG_NAME
   else
      echo "Image $PACKER_INSIGHT_IMG_NAME already exist... skipping build"
   fi

   check_image_exist $PACKER_ACTIVEMQ_IMG_NAME
   if [ "$?" -ne 0 ]; then
      create_image $PACKER_ACTIVEMQ_FILE $PACKER_ACTIVEMQ_IMG_NAME
   else
      echo "Image $PACKER_ACTIVEMQ_IMG_NAME already exist... skipping build"
   fi

   check_image_exist $PACKER_TRANSFORMATION_IMG_NAME
   if [ "$?" -ne 0 ]; then
      create_image $PACKER_TRANSFORMATION_FILE $PACKER_TRANSFORMATION_IMG_NAME
   else
      echo "Image $PACKER_TRANSFORMATION_IMG_NAME already exist... skipping build"
   fi

   termin_images=$(date +"%s")
   difftimelps_images=$(($termin_images-$begin_images))

   echo ""
   echo "##################"
   echo "$(($difftimelps_images / 60)) minutes and $(($difftimelps_images % 60)) seconds elapsed for images creation task."
   echo "##################"
}

function deploy_bastion (){

    #Checking first if bastion is already deployed
    az vm list -g $RESOURCE_GROUP_NAME_DEPLOY 2> /dev/null |grep "bastion-vm" 1> /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
      return
    fi
   
    begin_bastion=$(date +"%s")
  
    echo "" 
    echo "#############################################################"
    echo "Deploying bastion"
    echo "#############################################################"
    echo ""

    terraform init

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform init command"
      exit 1
    fi

    terraform plan -out=tfplan-bastion -input=false -target=azurerm_virtual_machine.bastionvm

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform plan command"
      exit 1
    fi

    terraform apply -input=false -auto-approve tfplan-bastion

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform apply command"
      exit 1
    fi
   
    termin_bastion=$(date +"%s")
    difftimelps_bastion=$(($termin_bastion-$begin_bastion))

    echo ""
    echo "##################"
    echo "$(($difftimelps_bastion / 60)) minutes and $(($difftimelps_bastion % 60)) seconds elapsed for bastion deployment."
    echo "##################"

}

function deploy_all (){
    echo "" 
    echo "#############################################################"
    echo "Deploying entire infrastructure (bastion already deployed)"
    echo "#############################################################"
    echo ""
    
    begin_all_infrastructure=$(date +"%s")

    terraform init

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform init command"
      exit 1
    fi

    terraform plan -out=tfplan-all -input=false

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform plan command"
      exit 1
    fi

    terraform apply -input=false -auto-approve tfplan-all

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform apply command"
      exit 1
    fi
    
    termin_all_infrastructure=$(date +"%s")
    difftimelps_all_infrastructure=$(($termin_all_infrastructure-$begin_all_infrastructure))

    echo ""
    echo "##################"
    echo "$(($difftimelps_all_infrastructure / 60)) minutes and $(($difftimelps_all_infrastructure % 60)) seconds elapsed for entire infrastructure deployment."
    echo "##################"

}

function show_info(){
    terraform refresh 1> /dev/null 2>/dev/null
    APP_GATEWAY_IP=$(terraform output app_gateway_ip)
    DNS_NAME=$(terraform output dns_name)
    BASTION_IP=$(terraform output bastion_ip)

    echo ""
    echo "#############################################################"
    echo "DNS NAMES AND IPS GENERATED"
    echo "#############################################################"
    echo ""
    echo "VM created on resource group \"$RESOURCE_GROUP_NAME_DEPLOY\""
    echo ""
    echo "Alfresco Content Services 6.1 (share) -----------> http://$DNS_NAME/share"
    echo "Alfresco Content Services 6.1 (admin console) ---> http://$DNS_NAME/alfresco/s/enterprise/admin/admin-systemsummary"
    echo "Digital Workspace -------------------------------> http://$DNS_NAME/digital-workspace"
    echo "Alfresco Insight Engine 1.0.0 -------------------> http://$DNS_NAME/zeppelin"
    echo ""
    echo "Via Bastion urls:"
    echo "-----------------"
    echo "Alfresco Search Services 1.2.0 ------------------> http://$BASTION_IP:8983"
    echo ""
    echo "IPs:"
    echo "----"
    echo "Application gateway IP: $APP_GATEWAY_IP"
    echo "Bastion ip (ssh): $BASTION_IP"
}


echo "~~~~~~~~~~~~~~~~~~~~~"	
echo " M A I N - M E N U"
echo "~~~~~~~~~~~~~~~~~~~~~"
echo ""
echo "1. Run the entire project (create Azure Images, build infrastructure and deploy Alfresco Enterprise 6.1)"
echo "2. Create Azure Images"
echo "3. Build Azure infrastructure and deploy Alfresco Enterprise 6.1"
echo "4. Show infrastructure IPs and DNS names"
echo ""
read -p "Enter choice [ 1 - 4] " OPTION

case $OPTION in

     1)
          # Run the entire project
          nexus_credentials
          azure_credentials
          create_images
          deploy_bastion
          deploy_all
          show_info
          ;;
     2)
          # Create Azure Images
          nexus_credentials
          azure_credentials
          create_images
          ;;
     3)
          #Creating infrastructure
          azure_credentials
          deploy_bastion
          deploy_all
          show_info
          ;;
     4)
          # Showing infrastructure info
          azure_credentials
          show_info
          ;;

     *)
          echo "Option not valid"
          ;;
esac


echo ""

termin=$(date +"%s")
difftimelps=$(($termin-$begin))
echo "$(($difftimelps / 60)) minutes and $(($difftimelps % 60)) seconds elapsed for Script Execution."
