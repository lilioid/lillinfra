# ImagePullSecret Patcher

See GitHub [github.com/titansoft-pte-ltd/imagepullsecret-patcher](https://github.com/titansoft-pte-ltd/imagepullsecret-patcher/tree/master).

This application ensures that certain image pull secrets are globally available to all ServiceAccounts in all
namespaces.


## How to a add Credentials

For each new registry with which the cluster should automatically authenticate, a new secret and a new deployment to synchronize that secret need to be created.

1. **Create the dockerconfig.json content**

   For details, either see the [Kubernetes Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
   or use the following command:

   ```shell
   SERVER=registry.mafiasi.de
   USERNAME=agserver
   PW=foobar123
   
   kubectl create secret docker-registry --docker-server=$SERVER --docker-username=$USERNAME --docker-password=$PW --dry-run=client test -o json | jq '.data.".dockerconfigjson"' -r | base64 -d | jq
   ```
   
   This outputs a json structure that should be stored in a file like `dockerconfig-${SERVER}.secret.json`.

3. **Encrypt the file**

   ```shell
   sops --encrypt --in-place --input-type=json --output-type=json dockerconfig-${SERVER}.secret.json
   ```

4. **Add a Secret**

   Afterwards, a secret needs to be added via kustomize which contains the previously generated authentication data.

   For this, add an entry to the `secretGenerator` section like the following:

   ```yaml
    - name: $registry-creds
      type: kubernetes.io/dockerconfigjson
      options:
        disableNameSuffixHash: true
      files:
        - ".dockerconfigjson=dockerconfig-$registry.secret.json"
   ```
   
5. **Add a Deployment**

   Now, a deployment needs to be created which synchronizes the newly created secret.
   For that, copy one of the existing deployment manifests (e.g. [mafiasi-registry.deployment.yml](./manifests/mafiasi-registry.deployment.yml))
   and change the fields `metadata.name` to describe the new registry.
   Additionally, the field `metadata.labels.mafiasi.de/imagepullsecret-target` should be set to the name of the previously
   created secret.
   
   Also add the new deployment manifest to kustomize by adding it to the `resources` field in [kustomization.yml](./kustomization.yml).
