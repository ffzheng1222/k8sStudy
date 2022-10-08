#! /bin/bash


# configuration color show ...
GREEN='\e[0;32m'; YELLOW='\e[1;33m'; RED='\e[1;31m'; BLUE='\e[0;34m'; END='\e[0m';
RED(){ echo -e  "${RED}$1${END}"; }
GREEN(){ echo -e  "${GREEN}$1${END}"; }
YELLOW(){ echo -e  "${YELLOW}$1${END}"; }
BLUE() { echo -e  "${BLUE}$1${END}"; }


function has_kube_tools()
{
	KUBEADM_TOOL=$(which kubeadm)
	KUBECTL_TOOL=$(which kubectl)
	KUBELET_TOOL=$(which kubelet)

	is_kubeadm=$(echo ${KUBEADM_TOOL} | grep no)
	is_kubectl=$(echo ${KUBECTL_TOOL} | grep no)
	is_kubelet=$(echo ${KUBELET_TOOL} | grep no)

	if [[ -z ${is_kubeadm} ]] && [[ -z ${is_kubectl} ]] && [[ -z ${is_kubelet} ]]; then
		GREEN "kubernets cluster install tools is ok ^_^"
	fi
	echo
}



function config_kernel_info()
{
	cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
	cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
	sysctl -p /etc/sysctl.d/k8s.conf
	
	yum -y install ipset ipvsadm
	cat > /etc/sysconfig/modules/ipvs.modules <<EOF
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
EOF
	kernel_version=$(uname -r | cut -d- -f1)
	echo $kernel_version

	if [[ `expr $kernel_version \> 4.19` -eq 1 ]]
    then
        modprobe -- nf_conntrack
    else
        modprobe -- nf_conntrack_ipv4
	fi

	chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack
}


function init_k8s_system()
{
	# check ping node
	ping -c2 k8s-master; ping -c2 k8s-node1; ping -c2 k8s-node2
	
	# stop firewalld & close selinux & off swap
	systemctl stop firewalld && systemctl disable firewalld && systemctl status firewalld
	setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	swapoff -a && sed -i 's/.*swap.*/#&/g' /etc/fstab
	
	# config yum & install some linux tools
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup_${startTime_s}
	wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
	yum clean all && yum makecache && yum install nslookup wget net-tools telnet tree nmap sysstat lrzsz dos2unix bind-utils -y
	systemctl restart crond
	
	# config kernel argus (net LB ipset ipvsadm)
	config_kernel_info	
}


function install_containerd()
{
	cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

EOF

	wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
	yum install -y containerd.io
	cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

	sudo modprobe overlay
	sudo modprobe br_netfilter

	cat << EOF >> /etc/crictl.yaml
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
EOF

	#sudo sysctl --system
	systemctl daemon-reload
	systemctl enable containerd --now
	systemctl restart containerd
	#systemctl status containerd

	mkdir -p /etc/containerd
	containerd config default | sudo tee /etc/containerd/config.toml
	sed -ri 's#SystemdCgroup = false#SystemdCgroup = true#' /etc/containerd/config.toml
	sed -ri 's#k8s.gcr.io\/pause:3.6#registry.aliyuncs.com\/google_containers\/pause:3.7#' /etc/containerd/config.toml
	sed -ri 's#https:\/\/registry-1.docker.io#https:\/\/registry.aliyuncs.com#' /etc/containerd/config.toml
	sed -ri 's#net.ipv4.ip_forward = 0#net.ipv4.ip_forward = 1#' /etc/sysctl.d/99-sysctl.conf
	sudo sysctl --system
	systemctl daemon-reload
	sudo systemctl enable containerd && systemctl restart containerd

	echo 1 > /proc/sys/net/ipv4/ip_forward
}


function install_depend_server()
{
	# install containerd
	install_containerd
	
	# install k8s depend server (kubeadm kubelet kubectl)
	yum -y install kubeadm-1.24.0 kubelet-1.24.0 kubectl-1.24.0 --disableexcludes=kubernetes
	systemctl enable --now kubelet
	crictl config runtime-endpoint /run/containerd/containerd.sock
	
	kubeadm config images list
	kubeadm config print init-defaults > default-init.yaml
}


function crictl_pull_image()
{
	k8s_role_name=${1}
	
	if [[ ${k8s_role_name} == "master" ]]; then
		# pull image
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.24.0
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.24.0
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.24.0
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.24.0
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.7
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.5.3-0
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.6 

		# tag image
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.24.0 k8s.gcr.io/kube-apiserver:v1.24.0
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.24.0 k8s.gcr.io/kube-controller-manager:v1.24.0
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.24.0 k8s.gcr.io/kube-scheduler:v1.24.0
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.24.0 k8s.gcr.io/kube-proxy:v1.24.0
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.7 k8s.gcr.io/pause:3.7
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.5.3-0 k8s.gcr.io/etcd:3.5.3-0
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.6 k8s.gcr.io/coredns/coredns:v1.8.6
	
	elif [[ ${k8s_role_name} == "node" ]]; then
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.24.0
		crictl pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.7

		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.24.0 k8s.gcr.io/kube-proxy:v1.24.0
		ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.7 k8s.gcr.io/pause:3.
	fi 

	ctr -n k8s.io i ls -q
	crictl images
	crictl ps -a
}


function main()
{
	k8s_role_name=${1}
	YELLOW "echo init_k8s_system.sh  argus:${k8s_role_name}"

	# 初始化k8s集群所有节点的系统环境
	init_k8s_system
	
	# 安装k8s集群安装依赖服务
	install_depend_server
	
	# 判断当前环境kubeadm, kubectl, kubelet工具是否准备ok
	has_kube_tools
	
	if [[ ${k8s_role_name} == "master" ]]; then
		# 通过 crictl pull master node 集群安装必要镜像
		crictl_pull_image  "master"
	elif [[ ${k8s_role_name} == "node" ]]; then
		crictl_pull_image  "node"
	fi
}


main $@
