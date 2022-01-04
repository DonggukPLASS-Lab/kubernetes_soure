#ingress
kubectl create ingress cystem \
	--annotation kubernetes.io/ingress.class=traefik \
	--annotation traefik.frontend.rule.type=PathPrefixStrip \
	--rule="/cystem=cystem:5111"

#service
kubectl expose deployment/cystem --port=5111
