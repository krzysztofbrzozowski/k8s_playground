Here is basic example of custom cluster creation based on VMs

## On local machine I have created 3 VMs based on Ubuntu Server (ARM arch):
```
- k8s_master        <- 192.168.232.140
- k8s_node_0        <- 192.168.232.141
- k8s_node_1        <- 192.168.232.142
```

> [!TIP]
> Since I am running VMs using vamware fusion for mac I observed issue
> that during typing sudo, system is very slow
> ```
> echo -e '127.0.0.1\t' $(hostnamectl | grep -i "static hostname:" | cut -f2- -d:) | sudo tee -a /etc/hosts
> ```
> solved the issue

### Install few supporting packages
```
sudo apt-get install apt-transport-https gnupg ca-certificates curl software-properties-common inetutils-traceroute neovim
```

## Dockere related stuff
### Install docker ->  https://docs.docker.com/engine/install/ubuntu/
Clear everything
```
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

Install docker
```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Add $USER to docker group
```
sudo usermod -aG docker $USER
```

Test if docker running fine
```
docker run hello-world
```

## Kubernete related stuff
### Disable swap
```
sudo swapoff -a
sudo sed -i '/\/swap.img/s/^/#/' /etc/fstab
```

## Load kernel modules (if not loaded yet)
```
lsmod | grep overlay
lsmod | grep br_netfilter

sudo modprobe overlay
sudo modprobe br_netfilter
```

Load it at system start
```
sudo bash -c 'cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF'
```

## Enable IP forward and apply that
```
sudo bash -c 'cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward=1
EOF'
sudo sysctl --system
```

## Configure containerd
```
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null 2>&1 
cat /etc/containerd/config.toml
```

Change "SystemdCgroup" to true
...
ShimGroup = ""
SystemdCgroup = true
...

Restart and verify the containerd status
```
sudo systemctl status containerd
sudo systemctl restart containerd
```

### Install k8s kubelet kubeadm kubectl (1.32)
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
sudo chmod 644 /etc/apt/keyrings/k8s.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/k8s.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Create copies of master node
> [!TIP] IP Adressses in vmware fusion is not cleaniest solution and can be assinged randomly
> To solve that add one additional line in /etc/netplan/50-cloud-init.yaml
> ![fix-dxcp-lease](https://krzysztofbrzozowski.com/media/2025/02/03/screenshot-2025-02-03-at-230344.png)
> ```
> dhcp-identifier: mac

> [!TIP] For proxmox config and network devices you can use static IP assining
> Edit the file
> ```bash
> nvim /etc/netplan/50-cloud-init.yaml
> ```
> ```bash
> network:
>   version: 2
>   ethernets:
>     ens18:
>       addresses:
>         - 192.168.1.200/24
>       nameservers:
>         addresses:
>           - 192.168.1.1
>       routes:
>         - to: default
>           via: 192.168.1.1

Copy installed and configured VM (If you are using vamware). Rename only hostname
```
sudo hostnamectl set-hostname k8snodex
```

Change the isps ->
```
sudo nvim /etc/netplan/50-cloud-init.yaml
sudo netplan apply
```

In vmware fix entry 127.0.0.1 actually point to correct hostname
```
change entry in /etc/hosts
```

### Init the cluster
```
sudo kubeadm init --pod-network-cidr 192.168.232.0/24 --control-plane-endpoint "192.168.232.140:6443" --upload-certs -v=5
sudo kubeadm init --pod-network-cidr 192.168.1.0/24 --control-plane-endpoint "192.168.1.201:6443" --upload-certs -v=5
```

> [!CAUTION]
> Never provide ceritificates, even SHA1 of it

Output:
```
...
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes running the following command on each as root:

  kubeadm join 192.168.232.140:6443 --token yfmdjc.xyz \
        --discovery-token-ca-cert-hash sha256:xyz \
        --control-plane --certificate-key xyz

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.232.140:6443 --token yfmdjc.xyz \
        --discovery-token-ca-cert-hash sha256:xyz 
```

### Apply kubeconfig
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
## Verification
### 1st verification
```
user@k8smaster:~$ kubectl get nodes
NAME        STATUS     ROLES           AGE   VERSION
k8smaster   NotReady   control-plane   11m   v1.32.1
```

### 2nd verification after connecting to control-node -> kubeadm join 192.168.232.140:6443...
```
user@k8smaster:~$ kubectl get nodes
NAME        STATUS     ROLES           AGE   VERSION
k8smaster   NotReady   control-plane   15m   v1.32.1
k8snode0    NotReady   <none>          39s   v1.32.1
k8snode1    NotReady   <none>          25s   v1.32.1
```

### 3rd verification
```
user@k8smaster:~$ kubectl get pods -A
NAMESPACE     NAME                                READY   STATUS    RESTARTS   AGE
kube-system   coredns-668d6bf9bc-h825s            0/1     Pending   0          17m
kube-system   coredns-668d6bf9bc-t2sdl            0/1     Pending   0          17m
kube-system   etcd-k8smaster                      1/1     Running   0          17m
kube-system   kube-apiserver-k8smaster            1/1     Running   0          17m
kube-system   kube-controller-manager-k8smaster   1/1     Running   0          17m
kube-system   kube-proxy-5rb54                    1/1     Running   0          2m34s
kube-system   kube-proxy-cnsm2                    1/1     Running   0          2m48s
kube-system   kube-proxy-nthqx                    1/1     Running   0          17m
kube-system   kube-scheduler-k8smaster            1/1     Running   0          17m
```

That means CNI is not implemented

### Install Helm
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

which helm
```

### Install Cilium and veridy (only on master node)
```
helm repo add cilium https://helm.cilium.io/
```
```
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

```
user@k8smaster:~$ cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             1 errors
 \__/¯¯\__/    Operator:           disabled
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

Containers:            cilium             
                       cilium-operator    
Cluster Pods:          0/2 managed by Cilium
Helm chart version:    
Errors:                cilium    cilium    daemonsets.apps "cilium" not found
status check failed: [daemonsets.apps "cilium" not found, unable to retrieve ConfigMap "cilium-config": configmaps "cilium-config" not found]
```

### Install Cilium
```
helm install cilium cilium/cilium --version 1.16.6 \
  --namespace kube-system
```

### 4th verify
```
user@k8smaster:~$ kubectl get nodes
NAME        STATUS   ROLES           AGE   VERSION
k8smaster   Ready    control-plane   30m   v1.32.1
k8snode0    Ready    <none>          15m   v1.32.1
k8snode1    Ready    <none>          15m   v1.32.1
```

!Depreciated
> [!WARNING]
> Of course it is not working out of the box
> ![kubeadm_error](https://krzysztofbrzozowski.com/media/2025/01/28/error_kubeadm_init.png)

## What I did?
Updated containerd to new version
```
wget https://github.com/containerd/containerd/releases/download/v2.0.2/containerd-2.0.2-linux-arm64.tar.gz
sudo tar Cxzvf /usr/local containerd-2.0.2-linux-arm64.tar.gz
sudo reboot
containerd --version
```

> [!CAUTION]
> Looks like this solution is not working out of the box on top of containerd 1.75

> [!TIP]
> Use conatinerd intalled during docker installationa do the following
> ```
> sudo systemctl restart containerd
> ...
> disabled_plugins = ["cri"] 
> ...
> sudo sed -i 's/^\(disabled_plugins = \["cri"\]\)$/# \1/' /etc/containerd/config.toml
> remove that and
> sudo systemctl restart containerd
> ```
> After that it is possible to initialize node on master

# Run cluster automatically using script
```
./run_k8s_vms.sh --start

or

./run_k8s_vms.sh --stop
```

## In nodes 0 and 1 join the master node
```
kubeadm join 192.168.232.131:6443 --token jl411s.xyz \
        --discovery-token-ca-cert-hash sha256:xyz
```

## Verify nodes
```
kubectl get nodes
```
> [!CAUTION]
> Probably you will see some error
> ```
> E0201 23:59:20.289496   41956 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
> E0201 23:59:20.290790   41956 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
> E0201 23:59:20.292123   41956 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
> E0201 23:59:20.293531   41956 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
> E0201 23:59:20.294841   41956 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"http://localhost:8080/api?timeout=32s\": dial tcp 127.0.0.1:8080: connect: connection refused"
> The connection to the server localhost:8080 was refused - did you specify the right host or port?

> [!TIP]
> Then run this command
> ```
> mkdir -p $HOME/.kube
> sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
> sudo chown $(id -u):$(id -g) $HOME/.kube/config
> 
> ```
> kubectl get nodes
> NAME        STATUS     ROLES           AGE     VERSION
> k8smaster   NotReady   control-plane   7m41s   v1.31.5
> k8snode0    NotReady   <none>          6m12s   v1.31.5
> k8snode1    NotReady   <none>          6m11s   v1.31.5

## Install networking solution for containers
