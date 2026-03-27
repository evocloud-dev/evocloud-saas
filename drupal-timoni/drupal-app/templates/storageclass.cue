package templates

import (
	storagev1 "k8s.io/api/storage/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#StorageClass: storagev1.#StorageClass & {
	#config: #Config
	apiVersion: "storage.k8s.io/v1"
	kind:       "StorageClass"
	metadata: {
		name:      "\(#config.metadata.name)-csi-azure"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	
	if #config.azure.azureFile.enabled {
		provisioner: [
			if timoniv1.#SemVer & {#Version: #config.kubeVersion, #Minimum: "1.21.0"} {
				"file.csi.azure.com"
			},
			"kubernetes.io/azure-file",
		][0]
		parameters: {
			skuName:  #config.azure.azureFile.skuName
			protocol: #config.azure.azureFile.protocol
		}
	}

	if #config.azure.sharedDisk.enabled {
		provisioner: [
			if timoniv1.#SemVer & {#Version: #config.kubeVersion, #Minimum: "1.19.0"} {
				"disk.csi.azure.com"
			},
			"kubernetes.io/azure-disk",
		][0]
		parameters: {
			skuname:     #config.azure.azureFile.skuName
			cachingMode: "None"
			maxShares:   "\(#config.azure.sharedDisk.maxShares)"
		}
	}
}
