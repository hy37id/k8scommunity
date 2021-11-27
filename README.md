# Kubernetes Community Workshop - Rzeszow

## Prepare Your local computer to work with Azure and K8s

1. Azure CLI Install  [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Kubectl            [Kubectl](https://kubernetes.io/docs/tasks/tools/)
3. (OPTIONAL) Kubectx [Kubectx](https://github.com/ahmetb/kubectx)
4. (OPTIONAL) VSCODE  [VSCODE] (https://code.visualstudio.com/) and plugins to validate YAML files

## How to start with K8s on Azure?

After succesfull installation You need to know two params of Your cluster: ResourceGroupName and ClusterName.
```
az aks get-credentials -n <ClusterName> -g <ResourceGroupName> --overwrite 

kubectl config get-contexts

kubectl config set-context aks-primer 
```
