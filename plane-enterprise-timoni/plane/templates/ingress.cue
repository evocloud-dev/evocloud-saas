package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#PlaneIngress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-ingress"
		annotations: #config.ingress.annotations
	}
	spec: {
		ingressClassName: #config.ingress.ingressClass
		rules: [
			{
				host: #config.license.licenseDomain
				http: paths: [
					{
						path:     "/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-web"
							port: number: 3000
						}
					},
					{
						path:     "/spaces/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-space"
							port: number: 3000
						}
					},
					{
						path:     "/god-mode/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-admin"
							port: number: 3000
						}
					},
					{
						path:     "/api/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-api"
							port: number: 8000
						}
					},
					{
						path:     "/auth/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-api"
							port: number: 8000
						}
					},
					{
						path:     "/live/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-live"
							port: number: 3000
						}
					},
					{
						path:     "/graphql/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-api"
							port: number: 8000
						}
					},
					{
						path:     "/marketplace/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-api"
							port: number: 8000
						}
					},
					if #config.services.silo.enabled {
						{
							path:     "/silo/"
							pathType: "Prefix"
							backend: service: {
								name: "\(#config.metadata.name)-silo"
								port: number: 3000
							}
						}
					},
					if #config.services.pi.enabled {
						{
							path:     "/pi/"
							pathType: "Prefix"
							backend: service: {
								name: "\(#config.metadata.name)-pi-api"
								port: number: 8000
							}
						}
					},
					if #config.services.minio.local_setup {
						{
							path:     "/bucket" // Simplified matching for literal rule
							pathType: "Prefix"
							backend: service: {
								name: "\(#config.metadata.name)-minio"
								port: number: 9000
							}
						}
					},
				]
			},
			if #config.services.minio.local_setup && #config.ingress.minioHost != "" {
				{
					host: #config.ingress.minioHost
					http: paths: [{
						path:     "/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-minio"
							port: number: 9090
						}
					}]
				}
			},
			if #config.services.rabbitmq.local_setup && #config.ingress.rabbitmqHost != "" {
				{
					host: #config.ingress.rabbitmqHost
					http: paths: [{
						path:     "/"
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.metadata.name)-rabbitmq"
							port: number: 15672
						}
					}]
				}
			},
		]
		if #config.ssl.tls_secret_name != "" {
			tls: [{
				hosts: [
					#config.license.licenseDomain,
					if #config.ingress.minioHost != "" { #config.ingress.minioHost },
					if #config.ingress.rabbitmqHost != "" { #config.ingress.rabbitmqHost },
				]
				secretName: #config.ssl.tls_secret_name
			}]
		}
	}
}
