# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#Certficate Eamil
$UserEmailAddress = "dongbum@outlook.com"

#Get Kubernetes Resource information
$kubernetesResourceGroup = az aks show -g contosoretail -n contosoretailk8s041

#Get KubernetesNode Resource Information
$kubeNodeResourceGroupName = ($kubernetesResourceGroup | ConvertFrom-Json).nodeResourceGroup

#Public IP
$ip = kubectl get svc -n ingress-nginx -o jsonpath="{.items[?(.metadata.name == 'ingress-nginx-controller')].status.loadBalancer.ingress[0].ip}"

#Get Public IP for Nginx Controller
$ingressnetwork = az network public-ip list -g $kubeNodeResourceGroupName --query "[?contains(ipAddress, '$ip')].name" -o tsv

#CreateRandom 8 digit not to duplicate DNS Name
$surfix = (Get-Random -Maximum 10000000).toString().PadLeft(8, "0")

$publicEndpoint = az network public-ip update --dns-name contoso$surfix -n $ingressnetwork -g $kubeNodeResourceGroupName --query dnsSettings.fqdn -o tsv

Write-Host "Your Ingress Controller seeting has been completed.`n`r"
Write-Host "Your profile Service API endpoint is : $publicEndpoint/profile"
Write-Host "Your product Service API endpoint is : $publicEndpoint/product"
Write-Host "Your purchasehistory Service API endpoint is : $publicEndpoint/purchasehistory"
Write-Host "Your recommendationbyuser Service API endpoint is : $publicEndpoint/recommendationbyuser"
Write-Host "Your recommendationbyitem Service API endpoint is : $publicEndpoint/recommendationbyitem"

#Set up yaml files to adding public endpoint
((Get-Content -path .\setupIngress-prod.yaml.template -Raw) -replace '{servicedns}', $publicEndpoint) | Set-Content -Path .\setupIngress-prod.yaml

#Set up yaml files to adding User Email to Certificate
((Get-Content -path .\setupClusterIssuer-prod.yaml.template -Raw) -replace '{eamiladdress}', $UserEmailAddress) | Set-Content -Path .\setupClusterIssuer-prod.yaml

#Set up Deploy3.ps1.tempate service endpoint information
((Get-Content -path .\Deploy3.ps1 -Raw) -replace '{serviceendpoint}', $publicEndpoint) | Set-Content -Path .\Deploy3.ps1



