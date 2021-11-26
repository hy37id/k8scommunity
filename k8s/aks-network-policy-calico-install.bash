#!/bin/bash

# based on https://docs.microsoft.com/en-us/azure/container-instances/container-instances-using-azure-container-registry


# -o create ,delete ,status. shutdown
# -n aks-name
# -g aks-rg
# set your name and resource group

# aks-network-policy-calico-install.bash -n aks-security2020 -g rg-aks -l northeurope -o create

me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

display_usage() { 
	echo "Example of usage:" 
	echo -e "bash $me -n aks-primer -g rg-aks -l northeurope -o create" 
	echo -e "bash $me -n aks-primer -g rg-aks -l northeurope -o stop" 
	echo -e "bash $me -n aks-primer -g rg-aks -l northeurope -o start" 
	echo -e "bash $me -n aks-primer -g rg-aks -l northeurope -o status" 
	echo -e "bash $me -n aks-primer -g rg-aks -l northeurope -o delete" 
	} 

while getopts n:g:o:l: option
do
case "${option}"
in
n) AKS_NAME=${OPTARG};;
g) AKS_RG=${OPTARG};;
o) AKS_OPERATION=${OPTARG};;
l) AKS_LOCATION=${OPTARG};;
esac
done


if [ -z "$AKS_OPERATION" ]
then
      echo "\$AKS_OPERATION is empty"
	  display_usage
	  exit 1
else
      echo "\$AKS_OPERATION is NOT empty"
fi

if [ -z "$AKS_NAME" ]
then
      echo "\$AKS_NAME is empty"
	  display_usage
	  exit 
else
      echo "\$AKS_NAME is NOT empty"
fi

if [ -z "$AKS_RG" ]
then
      echo "\$AKS_RG is empty"
	  display_usage
	  exit 1
else
      echo "\$AKS_RG is NOT empty"
fi

if [ -z "$AKS_LOCATION" ]
then
      echo "\$AKS_LOCATION is empty"
	  display_usage
	  exit 1
else
      echo "\$AKS_LOCATION is NOT empty"
fi

set -u
set -e

az aks get-versions -l $AKS_LOCATION #--query 'orchestrators[-1].orchestratorVersion' -o tsv

AKS_VERSION=$(az aks get-versions -l $AKS_LOCATION --query 'orchestrators[-3].orchestratorVersion' -o tsv)

AKS_NODES=2
AKS_VM_SIZE=Standard_B2s

echo "AKS_NAME: $AKS_NAME"
echo "AKS_LOCATION: $AKS_LOCATION"
echo "AKS_NODES: $AKS_NODES"
echo "AKS_VERSION: $AKS_VERSION"
echo "AKS_VM_SIZE: $AKS_VM_SIZE"


if [ "$AKS_OPERATION" = "create" ] ;
then

    echo "Creating AKS cluster...";

    az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/PodSecurityPolicyPreview')].{Name:name,State:properties.state}"
    # wait until you have State = Registered

    # Create a resource group
    az group create --name $AKS_RG --location $AKS_LOCATION


    # Enable network policy by using the `--network-policy` parameter
    az aks create \
        --resource-group $AKS_RG \
        --name $AKS_NAME \
        --vm-set-type AvailabilitySet \
        --enable-addons monitoring \
        --kubernetes-version $AKS_VERSION \
        --node-vm-size $AKS_VM_SIZE \
        --node-count $AKS_NODES \
        --generate-ssh-keys \
        --network-plugin azure \
        --service-cidr 10.0.0.0/16 \
        --dns-service-ip 10.0.0.10 \
        --docker-bridge-address 172.17.0.1/16 \
        --network-policy calico



    # 3. Add public static IP for ingress controller     
    RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
    echo $RG_VM_POOL
    az network public-ip create --resource-group $RG_VM_POOL --name myIngressPublicIP \
      --dns-name myingress --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv

    az network public-ip list --resource-group $RG_VM_POOL --query "[?name=='myIngressPublicIP'].[dnsSettings.fqdn]" -o tsv


fi # of create


if [ "$AKS_OPERATION" = "start" ] ;
then
echo "starting VMs...";
  # get the resource group for VMs
  
  RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
  echo "RG_VM_POOL: $RG_VM_POOL"
  
  az vm list -d -g $RG_VM_POOL  | grep powerState 
  az vm start --ids $(az vm list -g $RG_VM_POOL --query "[].id" -o tsv) --no-wait
fi
 
if [ "$AKS_OPERATION" = "stop" ] ;
then
echo "stopping VMs...";
  # get the resource group for VMs
  RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)

  echo "RG_VM_POOL: $RG_VM_POOL"

  az vm list -d -g $RG_VM_POOL  | grep powerState

  az vm deallocate --ids $(az vm list -g $RG_VM_POOL --query "[].id" -o tsv) --no-wait
fi


if [ "$AKS_OPERATION" = "status" ] ;
then
  echo "AKS cluster status"
  az aks show --name $AKS_NAME --resource-group $AKS_RG
  
  # get the resource group for VMs
  RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
  echo "RG_VM_POOL: $RG_VM_POOL"
  
  az vm list -d -g $RG_VM_POOL  | grep powerState 
  
fi 


if [ "$AKS_OPERATION" = "delete" ] ;
then
  echo "AKS cluster deleting ";
  az aks delete --name $AKS_NAME --resource-group $AKS_RG
  az acr delete --name $ACR_NAME --resource-group $AKS_RG
fi 

