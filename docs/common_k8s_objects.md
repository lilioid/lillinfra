# Common Kubernetes Objects

## Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-name
spec:
  accessModes: [ ReadWriteOnce ]
  storageClassName: nfs-fast # nfs-slow is also available
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
spec:
  tls:
    - secretName: tls-bla.ftsell.de
      hosts:
        - bla.ftsell.de
  rules:
    - host: bla.ftsell.de
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
