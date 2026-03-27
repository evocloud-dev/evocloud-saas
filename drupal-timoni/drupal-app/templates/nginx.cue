package templates

import (
    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
)

// This template defines the Nginx Web Server workload.
#NginxDeployment: appsv1.#Deployment & {
    #config: #Config
    #cmName:   string
    #pvcName:  string

    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: {
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels & {
            tier: "frontend"
        }
        name:      "\(#config.metadata.name)-nginx"
    }
    spec: appsv1.#DeploymentSpec & {
        replicas: #config.nginx.replicas
        strategy: {
            type: #config.nginx.strategy
            if type == "RollingUpdate" {
                rollingUpdate: {
                    maxUnavailable: 1
                    maxSurge:       1
                }
            }
        }
        selector: matchLabels: {
            #config.selector.labels
            tier: "frontend"
        }
        template: {
            metadata: {
                labels: {
                    #config.selector.labels
                    tier: "frontend"
                    if #config.nginx.podLabels != _|_ {
                        #config.nginx.podLabels
                    }
                }
                if #config.nginx.podAnnotations != _|_ {
                    annotations: #config.nginx.podAnnotations
                }
            }
            spec: corev1.#PodSpec & {
                if #config.nginx.tolerations != _|_ {
                    tolerations: #config.nginx.tolerations
                }
                if #config.nginx.nodeSelector != _|_ {
                    nodeSelector: #config.nginx.nodeSelector
                }
                
                initContainers: [
                    if #config.drupal.siteRoot != "/" {
                        {
                            name:  "init-site-root"
                            image: #config.drupal.initContainerImage
                            command: ["/bin/sh", "-c", "mkdir -p \"/webroot$(dirname \"\(#config.drupal.siteRoot)\")\" && ln -s /var/www/html \"/webroot\(#config.drupal.siteRoot)\""]
                            volumeMounts: [{
                                name:      "webroot"
                                mountPath: "/webroot"
                            }]
                            securityContext: {
                                runAsUser:    33
                                runAsGroup:   33
                                runAsNonRoot: true
                            }
                        }
                    }
                ]

                containers: [
                    {
                        name:            "nginx"
                        image:           #config.nginx.image + ":" + [ if #config.nginx.tag != "" { #config.nginx.tag }, #config.moduleVersion + "-nginx" ][0]
                        imagePullPolicy: #config.nginx.imagePullPolicy
                        ports: [
                            {
                                name:          "http"
                                containerPort: 8080
                                protocol:      "TCP"
                            },
                            {
                                name:          "https"
                                containerPort: 8443
                                protocol:      "TCP"
                            }
                        ]

                        if #config.nginx.healthcheck.enabled {
                            if #config.nginx.healthcheck.probes != _|_ {
                                if #config.nginx.healthcheck.probes.livenessProbe != _|_ {
                                    livenessProbe: #config.nginx.healthcheck.probes.livenessProbe
                                }
                                if #config.nginx.healthcheck.probes.readinessProbe != _|_ {
                                    readinessProbe: #config.nginx.healthcheck.probes.readinessProbe
                                }
                            }
                            if #config.nginx.healthcheck.probes == _|_ {
                                readinessProbe: {
                                    httpGet: {
                                        path: "/_healthz"
                                        port: 8080
                                    }
                                    initialDelaySeconds: 0
                                    periodSeconds:       5
                                }
                                livenessProbe: {
                                    httpGet: {
                                        path: "/_healthz"
                                        port: 8080
                                    }
                                    initialDelaySeconds: 1
                                    periodSeconds:       5
                                }
                            }
                        }

                        if #config.nginx.resources != _|_ {
                            resources: #config.nginx.resources
                        }

                        volumeMounts: [
                            {
                                mountPath: "/etc/nginx/nginx.conf"
                                name:      "cm-nginx"
                                readOnly:  true
                                subPath:   "nginx.conf"
                            },
                            if !#config.drupal.disableDefaultFilesMount {
                                {
                                    mountPath: "/var/www/html/sites/default/files"
                                    name:      [
                                        if #config.drupal.persistence.enabled { "files" },
                                        if #config.azure.azureFile.enabled || #config.azure.sharedDisk.enabled { "files-public" },
                                        "files",
                                    ][0]
                                    subPath:   "public"
                                }
                            },
                            if #config.drupal.siteRoot != "/" {
                                {
                                    name:      "webroot"
                                    mountPath: "/webroot"
                                }
                            },
                            {
                                name:      "nginx-cache"
                                mountPath: "/var/cache/nginx"
                            },
                            {
                                name:      "nginx-run"
                                mountPath: "/var/run"
                            },
                            {
                                name:      "nginx-tmp"
                                mountPath: "/tmp"
                            },
                        ]
                        securityContext: {
                            runAsUser:    33
                            runAsGroup:   33
                            runAsNonRoot: true
                        }
                    },
                ]

                if #config.nginx.imagePullSecrets != _|_ {
                    imagePullSecrets: #config.nginx.imagePullSecrets
                }
                if #config.nginx.securityContext != _|_ {
                    securityContext: {
                        runAsUser:    *33 | int
                        runAsGroup:   *33 | int
                        runAsNonRoot: *true | bool
                        fsGroup:      #config.nginx.securityContext.fsGroup
                    }
                }

                volumes: [
                    {
                        name: "cm-nginx"
                        configMap: name: #cmName
                    },
                    if #config.drupal.persistence.enabled {
                        {
                            name: "files"
                            persistentVolumeClaim: claimName: #pvcName
                        }
                    },
                    if !#config.drupal.persistence.enabled && (#config.azure.azureFile.enabled || #config.azure.sharedDisk.enabled) {
                        {
                            name: "files-public"
                            persistentVolumeClaim: claimName: "\(#config.metadata.name)-public"
                        }
                    },
                    if !#config.drupal.persistence.enabled && !(#config.azure.azureFile.enabled || #config.azure.sharedDisk.enabled) && !#config.drupal.disableDefaultFilesMount {
                        {
                            name: "files"
                            emptyDir: {}
                        }
                    },
                    if #config.drupal.siteRoot != "/" {
                        {
                            name: "webroot"
                            emptyDir: {}
                        }
                    },
                    {
                        name: "nginx-cache"
                        emptyDir: {}
                    },
                    {
                        name: "nginx-run"
                        emptyDir: {}
                    },
                    {
                        name: "nginx-tmp"
                        emptyDir: {}
                    },
                ]
            }
        }
    }
}
