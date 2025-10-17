# Common Kubernetes Objects

## Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-name
spec:
  accessModes: [ ReadWriteMany ]
  resources:
    requests:
      storage: 1G
```

## Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-name
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-http
    traefik.ingress.kubernetes.io/router.entrypoints: web, websecure
    traefik.ingress.kubernetes.io/router.middlewares: >-
      traefik-compress@kubernetescrd,
      traefik-redirect-tls@kubernetescrd,
      traefik-secure-headers@kubernetescrd
spec:
  tls:
    - secretName: tls-bla.aut-sys.de
      hosts: [ bla.aut-sys.de ]
  rules:
    - host: bla.aut-sys.de
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  name: http
```
