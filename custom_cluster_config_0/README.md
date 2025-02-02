Here is basic example of custom cluster creation based on VMs

## On local machine I have created 3 VMs based on Ubuntu Server (ARM arch):
```
- k8s_master        <- 192.168.232.131
- k8s_node_0        <- 192.168.232.132
- k8s_node_1        <- 192.168.232.133
```

> [!TIP]
> Since I am running VMs using vamware fusion for mac I observed issue
> that during typing sudo, system is very slow
> ```
> echo -e '127.0.0.1\t' $(hostnamectl | grep -i "static hostname:" | cut -f2- -d:) | sudo tee -a /etc/hosts
> ```
> solved the issie

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

### Install kubelet kubeadm kubectl
```
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```

### Init the cluster
```
sudo kubeadm init
```

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
> cat /etc/containerd/config.toml
> 
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