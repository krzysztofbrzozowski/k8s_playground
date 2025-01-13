# Contents:
- [To run locally the k8s](#to-run-locally-the-k8s)
- [sample_config_0](#sample_config_0)


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
