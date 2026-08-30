package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	// Name computation helpers mirroring Helm chart
	#fullname: {
		if fullnameOverride != "" {
			fullnameOverride
		}
		if fullnameOverride == "" {
			metadata.name
		}
	}

	#appServiceName:   "\(#fullname)-app"
	#nginxServiceName: "\(#fullname)-nginx"
	#mysqlServiceName: "\(#fullname)-mysql"
	#redisServiceName: "\(#fullname)-redis"
	#configName:       "\(#fullname)-config"
	#secretName:       "\(#fullname)-secret"

	#serviceAccountName: {
		if serviceAccount.create {
			if serviceAccount.name != "" {
				serviceAccount.name
			}
			if serviceAccount.name == "" {
				#fullname
			}
		}
		if !serviceAccount.create {
			if serviceAccount.name != "" {
				serviceAccount.name
			}
			if serviceAccount.name == "" {
				"default"
			}
		}
	}

	app: {
		image: #Image & {
			repository: *"invoiceninja/invoiceninja-debian" | string
			tag:        *"latest" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		busyboxTag:   *"1.36" | string
		replicaCount: *1 | int & >0
		resources:    corev1.#ResourceRequirements
		podSecurityContext: corev1.#PodSecurityContext & {
			seccompProfile?: corev1.#SeccompProfile & {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *false | bool
			runAsGroup?:              int
			capabilities?: corev1.#Capabilities & {
				add: *["SETGID", "SETUID", "DAC_OVERRIDE", "FOWNER", "CHOWN"] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		initSecurityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65534 | int
			runAsGroup?:              int
			capabilities?: corev1.#Capabilities & {
				drop: *["ALL"] | [...string]
			}
		}
	}

	nginx: {
		image: #Image & {
			repository: *"nginxinc/nginx-unprivileged" | string
			tag:        *"alpine" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		replicaCount:  *1 | int & >0
		containerPort: *8080 | int & >0 & <=65535
		service: {
			type: *"ClusterIP" | "NodePort" | "LoadBalancer"
			port: *80 | int & >0 & <=65535
		}
		resources: corev1.#ResourceRequirements
		podSecurityContext: corev1.#PodSecurityContext & {
			seccompProfile?: corev1.#SeccompProfile & {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *101 | int
			runAsGroup?:              int
			capabilities?: corev1.#Capabilities & {
				drop: *["ALL"] | [...string]
			}
		}
		initSecurityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *false | bool
			runAsGroup?:              int
			capabilities?: corev1.#Capabilities & {
				drop: *["ALL"] | [...string]
			}
		}
	}

	mysql: {
		image: #Image & {
			repository: *"mariadb" | string
			tag:        *"lts" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		service: {
			port: *3306 | int & >0 & <=65535
		}
		resources: corev1.#ResourceRequirements
		podSecurityContext: corev1.#PodSecurityContext & {
			seccompProfile?: corev1.#SeccompProfile & {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup?:              int
			capabilities?: corev1.#Capabilities & {
				drop: *["ALL"] | [...string]
			}
		}
		nodeSelector: *{} | {[string]: string}
		affinity:     corev1.#Affinity
		tolerations:  *[...] | [...corev1.#Toleration]
	}

	redis: {
		image: #Image & {
			repository: *"redis" | string
			tag:        *"alpine" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		service: {
			port: *6379 | int & >0 & <=65535
		}
		resources: corev1.#ResourceRequirements
		podSecurityContext: corev1.#PodSecurityContext & {
			seccompProfile?: corev1.#SeccompProfile & {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup?:              int
			capabilities?: corev1.#Capabilities & {
				drop: *["ALL"] | [...string]
			}
		}
	}

	persistence: {
		appPublic: #PersistenceItem & {
			enabled:          *false | bool
			accessModes:      *["ReadWriteOnce"] | [...string]
			size:             *"1Gi" | string
			storageClassName: *"" | string
		}
		appStorage: #PersistenceItem & {
			enabled:          *false | bool
			accessModes:      *["ReadWriteOnce"] | [...string]
			size:             *"5Gi" | string
			storageClassName: *"" | string
		}
		mysqlData: #PersistenceItem & {
			enabled:          *false | bool
			accessModes:      *["ReadWriteOnce"] | [...string]
			size:             *"10Gi" | string
			storageClassName: *"" | string
		}
		redisData: #PersistenceItem & {
			enabled:          *false | bool
			accessModes:      *["ReadWriteOnce"] | [...string]
			size:             *"1Gi" | string
			storageClassName: *"" | string
		}
	}

	serviceAccount: {
		create: *false | bool
		name:   *"" | string
	}

	ingress: {
		enabled:   *false | bool
		className: *"" | string
		annotations: *{} | {[string]: string}
		hosts: *[{
			host: "invoiceninja.local"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}] | [...#IngressHost]
		tls: *[] | [...{
			hosts?: [...string]
			secretName?: string
		}]
	}

	secret: {
		appKey:          *"" | string
		dbPassword:      *"ninja" | string
		dbRootPassword:  *"ninjaAdm1nPassword" | string
		redisPassword:   *"" | string
		inUserEmail:     *"admin@example.com" | string
		inPassword:      *"changeme!" | string
	}

	env: {
		appUrl:                 *"http://localhost" | string
		appEnv:                 *"production" | string
		appDebug:               *"false" | string
		requireHttps:           *"false" | string
		phantomjsPdfGeneration: *"false" | string
		pdfGenerator:           *"snappdf" | string
		trustedProxies:         *"*" | string
		cacheDriver:            *"redis" | string
		queueConnection:        *"redis" | string
		sessionDriver:          *"redis" | string
		redisPort:              *"6379" | string
		filesystemDisk:         *"debian_docker" | string
		dbPort:                 *"3306" | string
		dbDatabase:             *"ninja" | string
		dbUsername:             *"ninja" | string
		dbConnection:           *"mysql" | string
		mailMailer:             *"log" | string
		mailHost:               *"smtp.mailtrap.io" | string
		mailPort:               *"2525" | string
		mailUsername:           *"null" | string
		mailPassword:           *"null" | string
		mailEncryption:         *"null" | string
		mailFromAddress:        *"user@example.com" | string
		mailFromName:           *"Self Hosted User" | string
		nordigenSecretId:       *"" | string
		nordigenSecretKey:      *"" | string
		isDocker:               *"true" | string
		scoutDriver:            *"null" | string
	}

	tolerations:  *[...] | [...corev1.#Toleration]
	affinity:     corev1.#Affinity
	nodeSelector: *{} | {[string]: string}
}

#Image: {
	repository: string
	tag:        string
	pullPolicy: *"IfNotPresent" | "Always" | "Never"
}

#PersistenceItem: {
	enabled:          *false | bool
	accessModes:      *["ReadWriteOnce"] | [...string]
	size:             string
	storageClassName: *"" | string
}

#IngressPath: {
	path:     *"/" | string
	pathType: *"Prefix" | "ImplementationSpecific" | "Exact"
}

#IngressHost: {
	host:  string
	paths: [...#IngressPath]
}

#Instance: {
	config: #Config

	objects: {
		configMap:      #ConfigMap & {#config: config}
		nginxConfigMap: #NginxConfigMap & {#config: config}
		secret:         #Secret & {#config: config}

		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		if config.persistence.appPublic.enabled {
			appPublicPVC: #AppPublicPVC & {#config: config}
		}
		if config.persistence.appStorage.enabled {
			appStoragePVC: #AppStoragePVC & {#config: config}
		}
		if config.persistence.mysqlData.enabled {
			mysqlDataPVC: #MysqlDataPVC & {#config: config}
		}
		if config.persistence.redisData.enabled {
			redisDataPVC: #RedisDataPVC & {#config: config}
		}

		appDeploy:   #AppDeployment & {#config: config}
		appService:  #AppService & {#config: config}
		nginxDeploy: #NginxDeployment & {#config: config}
		nginxService: #NginxService & {#config: config}
		mysqlDeploy: #MysqlDeployment & {#config: config}
		mysqlService: #MysqlService & {#config: config}
		redisDeploy: #RedisDeployment & {#config: config}
		redisService: #RedisService & {#config: config}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
	}
}
