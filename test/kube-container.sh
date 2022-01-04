#!/bin/bash
PROJECT_PATH="/mnt/RAID-1/PROJECTS" #ROOT path
USER_VALUE=$2
API=$3
CONFIG_PATH="/mnt/RAID-1/CONFIGS"


cnt=`kubectl -n ide get pods | wc -l`
cnt=`expr $cnt % 5 + 1`
NODE="node$cnt"

echo $PROJECT_PATH
echo $USER_VALUE
echo $API
echo $NODE

mkdir -p "$PROJECT_PATH/$USER_VALUE"

#if [ ! -d "$CONFIG_PATH/$USER_VALUE" ] ; then
#	cp -r "$PWD/modules/config" "$CONFIG_PATH/$USER_VALUE/"
#fi

mkdir -p "yaml"

cat << EOF > yaml/$USER_VALUE.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: $USER_VALUE
  namespace: ide
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.frontend.rule.type: PathPrefixStrip
spec:
  rules:
  - http:
      paths:
      - path: /$API
        backend:
          serviceName: $USER_VALUE
          servicePort: http
---
apiVersion: v1
kind: Service
metadata:
        name: $USER_VALUE
        namespace: ide
spec:
        sessionAffinity: ClientIP
        selector:
                app: ide
                user: $USER_VALUE
        ports:
                - name: http
                  port: 5111
                  targetPort: 5111
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv-$USER_VALUE
  namespace: ide
  labels:
    name: nfs-pv-$USER_VALUE
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: $PROJECT_PATH/$USER_VALUE
    server: 210.94.194.102
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfs-pvc-$USER_VALUE
  namespace: ide
spec:
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  selector:
    matchLabels:
      name: nfs-pv-$USER_VALUE
---
apiVersion: apps/v1
kind: Deployment
metadata:
        labels:
                app: ide
                user: $USER_VALUE
        name: $USER_VALUE
        namespace: ide
spec:
        selector:
                matchLabels:
                        app: ide
                        user: $USER_VALUE
        template:
                metadata:
                        labels:
                                app: ide
                                user: $USER_VALUE
                spec:
                        affinity:
                                podAntiAffinity:
                                        requiredDuringSchedulingIgnoredDuringExecution:
                                        - labelSelector:
                                                  matchExpressions:
                                                  - key: user
                                                    operator: In
                                                    values:
                                                    - $USER_VALUE
                                          topologyKey: "kubernetes.io/hostname"
                        securityContext:
                                runAsUser: 0
                        containers:
                                - image: dguplms/ide:1.4
                                  name: $USER_VALUE
                                  env:
                                  - name: user
                                    value: "$API"
                                  command: [ "code-server" ]
                                  ports:
                                          - containerPort: 5111
                                  volumeMounts:
                                  - name: pvc-volume-pro
                                    mountPath: /home/coder/projects
                        nodeSelector:
                          ide: $NODE
                        volumes:
                        - name: pvc-volume-pro
                          persistentVolumeClaim:
                            claimName: nfs-pvc-$USER_VALUE
                        imagePullSecrets:
                                - name: plass-hub
EOF

kubectl apply -f yaml/$USER_VALUE.yaml
