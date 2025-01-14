# Contents:
- [To run locally the k8s](#to-run-locally-the-k8s)
- [sample_config_0](#sample_config_0) <- some very very basic config
- [sample_config_1](#sample_config_1) <- config contains Deployment object


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

## sample_config_0
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

## sample_config_1
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