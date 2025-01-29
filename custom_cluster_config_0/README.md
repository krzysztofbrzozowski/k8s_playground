Here is basic example of custom cluster creation based on VMs

## On local machine I have created 3 VMs based on Ubuntu Server (ARM arch):
```
- k8s_master        <- 10.211.55.10
- k8s_worker_0      <- 10.211.55.8
- k8s_worker_1      <- 10.211.55.9
```

Set up process
### Disable swap
```
sudo swapoff -a
sudo sed -i '/\/swap.img/s/^/#/' /etc/fstab
```

### Install docker
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

> [!ERROR]
> Looks like this solution is not working out of the box on top of containerd 1.75

> ![TIP]
> Use conatinerd intalled during docker installationa do the following
> ```
> cat /etc/containerd/config.toml
> 
> ...
> disabled_plugins = ["cri"] 
> ...
> 
> remove that and
> sudo systemctl restart containerd
> ```
> After that it is possible to initialize node on master

