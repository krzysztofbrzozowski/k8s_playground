# Contents:
- [To run locally the k8s](#to-run-locally-the-k8s)
- [sample_config_0](#↪-sample_config_0) <- some very very basic config
- [sample_config_1](#↪-sample_config_1) <- config contains Deployment object
- [sample_config_2](#↪-sample_config_2) <- config contains full app with ClousterIP and Deployments


## To run locally the k8s
On mac Mx use Docker Desktop and enable Kubernetes
![k8s_install](https://krzysztofbrzozowski.com/media/2025/01/13/k8s_install.png)

test installation
```bash
kubectl cluster-info
```
Answer:
```bash
Kubernetes control plane is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'
```

## ↪ sample_config_0
Contains sample config with app to run simple react app. App contains 2 objects: **pod** and **service**
Run it using
```
kubectl apply -f client-pod.yaml
kubectl apply -f client-node-port.yaml
```

Get config of group of objects
```
kubectl get pods
kubectl get services
```
![sample_config_0](https://krzysztofbrzozowski.com/media/2025/01/13/running_app.png)

## ↪ sample_config_1
This is modified sample_0, pod object has been changed to deploy object. Deployment is some kind of object which can tell to master to
create new pod. Later on deployment node will take handle of that pod. Basically Deployment is 'bucket' for pods.

Delete previous pod
```
kubectl delete -f <file.yaml>
kubectl delete -f sample_config_0/client-pod.yaml
```

Apply deployment (the same command as pod)
```
kubectl apply -f sample_config_1/client-deployment.yaml
```
Get pods/deployments status
```
kubectl get pods
kubectl get pods -o wide

kubectl get deployments

kubectl describe pods
kubectl describe deployments
```

App is running on the same **localhost:31515**

Note:
In Deployment object it is possible to change e.g. port. In Pod it is not allowed.

> [!IMPORTANT]
> In this section has been updated image of the pod AFTERWARDS
> ```
> kubectl set image <object-type>/<object-name> <container-name>=<new-image-to-use>
> kubectl set image deployment/client-deployment client=stephengrider/multi-client:v5
>
> kubectl get pods <- to see if pod is refreshed

> [!IMPORTANT]
> Pushing of the docker file to some registry can be done
> ```
> docker build -t <user>/<docker-image>:<tag>
> docker push <user>/<docker-image>:<tag>

## ↪ sample_config_2
This is full kubernetes stuctructure app
![k8s_atch](https://krzysztofbrzozowski.com/media/2025/01/17/kubernetes-arch.jpeg)
### Here 2 new objects has been introduced:
* **ClusterIP**: CluserIP is somehow different than NodePort in that way it **does not allow** traffic oudside of cluster
* **PersistentVolumeClaim**: This is the volume adevrismet which might be connected to the pod/pods. It does not have fixed voliume yet but will crete on the run (as far as I understood now). We have few access modes.
  ```
  ...
  accessModes:
  - ReadWriteOnce -> can be used by single node
  - ReadOnlyMany -> multiple nodes can read this volume
  - ReadWriteMany -> multiple nodes can read and write this volume
  ```
* **Secrets** Pseudo securely stores the scecrets (as for now I am thinking), because anybody can get the sectet using
  ```
  kubectl get secret pgpassword -o jsonpath="{.data.POSTGRES_PASSWORD}" | base64 --decode
  ```
  There must be some better way to secure that

### To run this deployment you need to remove previous Deployment and Servce
Delete deployment and service
```
kubectl delete deployment client-deployment
kubectl delete service client-node-port
```
Apply config from all the folder
```
kubectl apply -f <folder>
kubectl apply -f sample_config_2
```
> [!IMPORTANT]
> Some of the config has the error afer deployment
> ```
> client-deployment     3/3     3            3           102s
> postgres-deployment   0/1     1            0           102s
> redis-deployment      1/1     1            1           102s
> server-deployment     3/3     3            3           102s
> worker-deployment     1/1     1            1           102s
>
> client-deployment-54c49db587-jxkdw     1/1     Running   0              4m
> client-deployment-54c49db587-qxn5x     1/1     Running   0              4m
> client-deployment-54c49db587-v2lv2     1/1     Running   0              4m
> postgres-deployment-6dcb4dcbb4-k5x2p   0/1     Error     5 (101s ago)   4m
> redis-deployment-5cbb49bb65-xpssr      1/1     Running   0              4m
> server-deployment-85dc8866bd-k9cs8     1/1     Running   0              4m
> server-deployment-85dc8866bd-vwhmr     1/1     Running   0              4m
> server-deployment-85dc8866bd-x5zs4     1/1     Running   0              4m
> worker-deployment-6f7777d94f-vlkkf     1/1     Running   0              4m

### See the logs
```
kubectl logs <object-id_or_object_name>
kubectl logs postgres-deployment-6dcb4dcbb4-k5x2p
```
```
-> Error: Database is uninitialized and superuser password is not specified.
       You must specify POSTGRES_PASSWORD to a non-empty value for the
       superuser. For example, "-e POSTGRES_PASSWORD=password" on "docker run".
```

### See storage
```
kubectl get storageclass
kubectl describe storageclass
kubectl get pv       <- persitent volumes status
kubectl get pvc      <- persitent volume claims status
```

### Secrets
To deploy secrets it might be beneficiat to use imperative command instead of config with writtent passwords for that.
In that case we will have to run this commands locally and in prod as well
```
kubectl create secret generic <secret_name> --from-literal key=value
kubectl create secret generic pgpassword --from-literal POSTGRES_PASSWORD=12345
```
Get secrets
```
kubectl get secrets
kubectl get secret pgpassword -o jsonpath="{.data.POSTGRES_PASSWORD}" | base64 --decode
```

Edit secrets
```
kubectl edit secret pgpassword

or delete and add new one
kubectl delete secret pgpassword
kubectl create secret generic pgpassword --from-literal=POSTGRES_PASSWORD=12345
```
