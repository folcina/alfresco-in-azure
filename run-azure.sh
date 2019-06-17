#!/bin/bash
#set -x
begin=$(date +"%s")

################################
# Adjust the following settings#
################################
NEXUS_FILE="$HOME/.nexus.dat"
AZURE_FILE="$HOME/.az.dat"
DOMAIN_NAME_LABEL="alfresco61-demo"
RESOURCE_GROUP_NAME_IMG="Alfresco_6.1_Demo_images_azure_connector"
RESOURCE_GROUP_NAME_DEPLOY="Alfresco_deployment_azure_connector"
LOCATION="uksouth"

#OpenSSL
OPENSSL_EXE="openssl"

#AZURE CLI
AZ_EXE="az"

# Packer
PACKER_EXE="packer"
export PACKER_LOG=0
#export PACKER_LOG_PATH="packerlog.txt"

# Terraform
TERRAFORM_EXE="terraform"
TERRAFORM_PLUGINS_FOLDER="$HOME/.terraform.d/plugins"

#log levels TRACE, DEBUG, INFO, WARN or ERROR
export TF_LOG="DEBUG"
export TF_LOG_PATH="terraform.log"

#################################
# End of adjustable settings    #
#################################


# Don't change values below unless is necessary

SSH_PUBLIC_KEY_FILE="./ssh-keys/id_rsa.pub"
SSH_PRIVATE_KEY_FILE="./ssh-keys/id_rsa"
SSH_KEYS_FOLDER="./ssh-keys"

export TF_VAR_DOMAIN_NAME_LABEL=$DOMAIN_NAME_LABEL
export TF_VAR_LOCATION=$LOCATION
export TF_VAR_RESOURCE_GROUP_IMAGES=$RESOURCE_GROUP_NAME_IMG
export TF_VAR_RESOURCE_GROUP_DEPLOYMENT=$RESOURCE_GROUP_NAME_DEPLOY
export TF_VAR_SSH_PUBLIC_KEY_FILE=$SSH_PUBLIC_KEY_FILE
export TF_VAR_SSH_PRIVATE_KEY_FILE=$SSH_PRIVATE_KEY_FILE

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

function check_software_versions(){
   # Packer >=1.4.0

   echo -n "Checking Packer version (>=1.4.0)..... "
   if [ "$($PACKER_EXE -version | grep -i -c -E '[1-9]\.[4-9]\.[0-9]')" -eq "1" ]; then
      echo "OK"
   else
      echo "Packer version should be equal or higher than 1.4.0"
      exit 1
   fi

   # Terraform >= 0.11.13

   echo -n "Checking Terraform version (>=0.11.13)..... "
   if [ "$($TERRAFORM_EXE --version |head -1| awk '{print $2}' |grep -i -c -E '[0-9]\.[1-9][1-9]\.[1-9][3-9]|[2-9][0-9]')" -eq "1" ]; then
      echo "OK"
   else
      echo "Terraform version should be equal or higher than 0.11.13"
      exit 1
   fi

   # Terraform Ansible provider >= 0.11.13
   echo -n "Checking Terraform Ansible Provider (=2.1.2)..... "
   if [ "$(find $TERRAFORM_PLUGINS_FOLDER |grep -c 'terraform-provisioner-ansible_v2.1.2')" -eq "1" ]; then
      echo "OK"
   else
      echo "Terraform provisioner ansible v2.1.2 wasn't found or version was incorrect. Check also that the file name of the module is correct and matches the pattern recognized by Terraform: terraform-provisioner-ansible_v2.1.2"
      exit 1
   fi

   # AZ client
   echo -n "Checking az cli version (>=2.0.55)..... "
   if [ "$($AZ_EXE --version 2>/dev/null |head -1 |awk '{print $2}'  |grep -i -c -E '[2-9]\.[0-9]\.[5-9][5-9]|[6-9][0-9]')" -eq "1" ]; then
      echo "OK"
   else
      echo "az cli version should be equal or higher than 2.0.55"
      exit 1
   fi

   #OpenSSL >=1.0.2.f
   echo -n "Checking OpenSSL version (>=1.0.2f)..... "
   if [ "$($OPENSSL_EXE version |awk '{print $2}' |grep -c -E '1\.([0-9]\.[2-9][f-z]|[1-9]\.[0-9][a-z])')" -eq "1" ]; then
      echo "OK"
   else
      echo "OpenSSL version should be equal or higher than 1.0.2f"
      exit 1
   fi

}

function check_azure_account(){
   echo -n "Checking if az subscription is enabled....."
   if [ "$($AZ_EXE account show | jq -r '.state' |grep -c -i 'enabled')" -eq "1" ]; then
      echo "OK"
   else
      echo "az cli didn't find any enabled account (az account show)"
      exit 1
   fi
}

function generate_ssh_keys(){
   #Create ssh-keys folder if it doesn't exist
   if [ ! -d $SSH_KEYS_FOLDER ]; then
      mkdir -p $SSH_KEYS_FOLDER
   fi

   #Check if keys already exist

   if [ -f $SSH_PUBLIC_KEY_FILE ] ; then
      return
   fi

   echo ""
   echo "#####################################"
   echo "Generating ssh keys"
   echo "#####################################"

   ssh-keygen -t rsa -b 4096 -P "" -f $SSH_PRIVATE_KEY_FILE 1> /dev/null 2>/dev/null
}

function nexus_credentials(){
   echo ""
   echo "Introduce the password for the Nexus credentials file"
   echo ""
   CREDENTIALS=$($OPENSSL_EXE enc -aes-256-cbc -d -in $NEXUS_FILE)
   export NEXUS_USER=$(echo $CREDENTIALS|awk -F':' '{print $1}')
   export NEXUS_PASSWORD=$(echo $CREDENTIALS|awk -F':' '{print $2}')
}

function azure_credentials(){
  echo ""
  echo "Introduce the password for the Azure credentials file"
  echo ""
  CREDENTIALS=$($OPENSSL_EXE enc -aes-256-cbc -d -in $AZURE_FILE)
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
   $AZ_EXE image list --resource-group $RESOURCE_GROUP_NAME_IMG |grep name |grep "$1" 1> /dev/null 2>&1
}

function create_images (){
   echo ""
   echo "#############################################################"
   echo "Creating Images"
   echo "#############################################################"
   echo ""
   begin_images=$(date +"%s")

   $AZ_EXE group list | grep name| grep $RESOURCE_GROUP_NAME_IMG 1> /dev/null 2>&1
   if [ "$?" -ne 0 ]; then
      $AZ_EXE group create -n $RESOURCE_GROUP_NAME_IMG --location $LOCATION
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
    $AZ_EXE vm list -g $RESOURCE_GROUP_NAME_DEPLOY 2> /dev/null |grep "bastion-vm" 1> /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
      return
    fi

    begin_bastion=$(date +"%s")

    echo ""
    echo "#############################################################"
    echo "Deploying bastion"
    echo "#############################################################"
    echo ""

    $TERRAFORM_EXE init

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform init command"
      exit 1
    fi

    $TERRAFORM_EXE plan -out=tfplan-bastion -input=false -target=azurerm_virtual_machine.bastionvm

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform plan command"
      exit 1
    fi

    $TERRAFORM_EXE apply -input=false -auto-approve tfplan-bastion

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

    $TERRAFORM_EXE init

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform init command"
      exit 1
    fi

    $TERRAFORM_EXE plan -out=tfplan-all -input=false

    if [ "$?" -ne 0 ]; then
      echo "ERROR: failed terraform plan command"
      exit 1
    fi

    $TERRAFORM_EXE apply -input=false -auto-approve tfplan-all

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
    $TERRAFORM_EXE refresh 1> /dev/null 2>/dev/null
    APP_GATEWAY_IP=$($TERRAFORM_EXE output app_gateway_ip)
    DNS_NAME=$($TERRAFORM_EXE output dns_name)
    BASTION_IP=$($TERRAFORM_EXE output bastion_ip)

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
    echo ""
    echo "SSH:"
    echo "----"
    echo "(See list of ports to connect via ssh to any VM in https://github.com/folcina/alfresco-in-azure)"
    echo ""
    echo "ssh -i ./ssh-keys/id_rsa azureuser@$BASTION_IP -p [PORT]"
}

#Check if all software versions are Okay
check_software_versions

#Check if the azure subscription is enabled
check_azure_account

#Generate ssh keys to access the infrastructure
generate_ssh_keys

#Showing menu
echo ""
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
