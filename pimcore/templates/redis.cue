package templates

import (
    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
)

#RedisStatefulSet: appsv1.#StatefulSet & {
    #config: #Config
    apiVersion: "apps/v1"
    kind:       "StatefulSet"
    metadata: {
        name:      "redis-master"
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels
    }
    spec: appsv1.#StatefulSetSpec & {
        serviceName: "redis-master-headless"
        replicas:    #config.redis.replicas
        selector: matchLabels: {
            "app.kubernetes.io/name":     "redis"
            "app.kubernetes.io/instance": "redis"
            "app.kubernetes.io/component": "master"
        }
        template: {
            metadata: {
                labels: {
                    "app.kubernetes.io/name":     "redis"
                    "app.kubernetes.io/instance": "redis"
                    "app.kubernetes.io/component": "master"
                }
            }
            spec: corev1.#PodSpec & {
                containers: [
                    {
                        name:            "redis"
                        image:           "\(#config.redis.image.registry):\(#config.redis.image.tag)"
                        imagePullPolicy: #config.redis.image.pullPolicy
                        ports: [
                            {
                                containerPort: 6379
                                name:          "redis"
                            },
                        ]
                        env: [
                            if #config.redis.auth.password != "" {
                                {
                                    name:  "REDIS_PASSWORD"
                                    value: #config.redis.auth.password
                                }
                            },
                        ]
                        args: [
                            if #config.redis.auth.password != "" {
                                "--requirepass"
                            },
                            if #config.redis.auth.password != "" {
                                #config.redis.auth.password
                            },
                            for _, flag in #config.redis.master.extraFlags {
                                flag
                            },
                        ]
                        volumeMounts: [
                            {
                                name:      "redis-data"
                                mountPath: "/data"
                            },
                        ]
                        if #config.redis.resources != _|_ {
                            resources: #config.redis.resources
                        }
                    },
                ]
            }
        }
        volumeClaimTemplates: [
            corev1.#PersistentVolumeClaim & {
                metadata: name: "redis-data"
                spec: corev1.#PersistentVolumeClaimSpec & {
                    accessModes: [#config.pvc.redis.accessMode]
                    resources: {
                        requests: storage: #config.pvc.redis.storage
                    }
                    if #config.pvc.redis.storageClass != "" {
                        storageClassName: #config.pvc.redis.storageClass
                    }
                }
            },
        ]
    }
}

#RedisHeadlessService: corev1.#Service & {
    #config: #Config
    apiVersion: "v1"
    kind:       "Service"
    metadata: {
        name:      "redis-master-headless"
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels
    }
    spec: corev1.#ServiceSpec & {
        clusterIP: "None"
        selector: {
            "app.kubernetes.io/name":     "redis"
            "app.kubernetes.io/instance": "redis"
            "app.kubernetes.io/component": "master"
        }
        ports: [
            {
                name:       "redis"
                port:       6379
                targetPort: 6379
            },
        ]
    }
}

#RedisService: corev1.#Service & {
    #config: #Config
    apiVersion: "v1"
    kind:       "Service"
    metadata: {
        name:      "redis-master"
        namespace: #config.metadata.namespace
        labels:    #config.metadata.labels
    }
    spec: corev1.#ServiceSpec & {
        type: corev1.#ServiceTypeClusterIP
        selector: {
            "app.kubernetes.io/name":     "redis"
            "app.kubernetes.io/instance": "redis"
            "app.kubernetes.io/component": "master"
        }
        ports: [
            {
                name:       "redis"
                port:       6379
                targetPort: 6379
            },
        ]
    }
}
