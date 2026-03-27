package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PersistentVolume: corev1.#PersistentVolume & {
	#config:   #Config
	#folder:   string
	#provider: "file" | "shared"
	
	apiVersion: "v1"
	kind:       "PersistentVolume"
	metadata: {
		name: "\(#config.metadata.name)-\(#folder)"
		#ann: [
			if #provider == "file" { #config.azure.azureFile.annotations },
			#config.azure.sharedDisk.annotations,
		][0]
		if #ann != _|_ {
			annotations: #ann
		}
	}
	spec: corev1.#PersistentVolumeSpec & {
		#size: [
			if #provider == "file" { #config.azure.azureFile.size },
			#config.azure.sharedDisk.size,
		][0]
		#access: [
			if #provider == "file" { #config.azure.azureFile.accessMode },
			#config.azure.sharedDisk.accessMode,
		][0]
		
		capacity: storage: #size
		accessModes: [#access]
		
		if #config.azure.storageClass.create {
			storageClassName: "\(#config.metadata.name)-csi-azure"
		}
		if !#config.azure.storageClass.create {
			#sc: [
				if #provider == "file" { #config.azure.azureFile.storageClass },
				#config.azure.sharedDisk.storageClass,
			][0]
			if #sc != "" {
				if #sc == "-" {
					storageClassName: ""
				}
				if #sc != "-" {
					storageClassName: #sc
				}
			}
		}
		
		csi: {
			driver: [
				if #provider == "file" {
					[
						if timoniv1.#SemVer & {#Version: #config.kubeVersion, #Minimum: "1.21.0"} {
							"file.csi.azure.com"
						},
						"kubernetes.io/azure-file",
					][0]
				},
				[
					if timoniv1.#SemVer & {#Version: #config.kubeVersion, #Minimum: "1.19.0"} {
						"disk.csi.azure.com"
					},
					"kubernetes.io/azure-disk",
				][0],
			][0]
			volumeHandle: "\(#config.metadata.name)-\(#folder)"
		}
	}
}

#PersistentVolumeClaimEx: corev1.#PersistentVolumeClaim & {
	#config:   #Config
	#folder:   string
	#provider: "file" | "shared"

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-\(#folder)"
		namespace: #config.metadata.namespace
		#ann: [
			if #provider == "file" { #config.azure.azureFile.annotations },
			#config.azure.sharedDisk.annotations,
		][0]
		if #ann != _|_ {
			annotations: #ann
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		#size: [
			if #provider == "file" { #config.azure.azureFile.size },
			#config.azure.sharedDisk.size,
		][0]
		#access: [
			if #provider == "file" { #config.azure.azureFile.accessMode },
			#config.azure.sharedDisk.accessMode,
		][0]
		
		accessModes: [#access]
		resources: requests: storage: #size
		
		#disableVolName: [
			if #provider == "file" { #config.azure.azureFile.disableVolumeName },
			#config.azure.sharedDisk.disableVolumeName,
		][0]
		if !#disableVolName {
			volumeName: "\(#config.metadata.name)-\(#folder)"
		}

		if #config.azure.storageClass.create {
			storageClassName: "\(#config.metadata.name)-csi-azure"
		}
		if !#config.azure.storageClass.create {
			#sc: [
				if #provider == "file" { #config.azure.azureFile.storageClass },
				#config.azure.sharedDisk.storageClass,
			][0]
			if #sc != "" {
				if #sc == "-" {
					storageClassName: ""
				}
				if #sc != "-" {
					storageClassName: #sc
				}
			}
		}
	}
}
