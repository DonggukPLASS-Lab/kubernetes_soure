cat << EOF > test.yaml
apiVersion: v1
kind: Service
metadata:
        name: $1
spec:
        selector:
                app: ide
                user: cystem
        ports:
                - name: http
                  port: 5111
                  targetPort: 5111
---
apiVersion: apps/v1
kind: Deployment
metadata:
        labels:
                app: ide
                user: cystem
        name: cystem
spec:
        selector:
                matchLabels:
                        app: ide
                        user: cystem
        template:
                metadata:
                        labels:
                                app: ide
                                user: cystem
                spec:
                        securityContext:
                                runAsUser: 0
                        containers:
                                - image: dguplms/ide:1.31
                                  name: cystem
                                  env:
                                  - name: user
                                    value: "cystem"
                                  command: [ "code-server" ]
                                  ports:
                                          - containerPort: 5111
                        imagePullSecrets:
                                - name: regcred
EOF
