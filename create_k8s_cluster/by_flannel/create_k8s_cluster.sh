#! /bin/bash



# configuration color show ...
GREEN='\e[0;32m'; YELLOW='\e[1;33m'; RED='\e[1;31m'; BLUE='\e[0;34m'; END='\e[0m';
RED(){ echo -e  "${RED}$1${END}"; }
GREEN(){ echo -e  "${GREEN}$1${END}"; }
YELLOW(){ echo -e  "${YELLOW}$1${END}"; }
BLUE() { echo -e  "${BLUE}$1${END}"; }


INSTALL_ROOT_PATH="$(cd `dirname $0` && pwd)"
KUBEADM_INSTALL_INFO="${INSTALL_ROOT_PATH}/kubeadm_install_info.log"
KUBENETERS_CLUSTER_NODELIST=("192.168.255.121"  "192.168.255.122")
KUBENETERS_CLUSTER_TOKEN=""



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


function install_k8s_cluster_master()
{
	kubeadm reset -f
	
	kubeadm_config=$(ls ${INSTALL_ROOT_PATH} | grep  'kubeadm.yaml')
	
	
	cat /dev/null > ${KUBEADM_INSTALL_INFO}
	if [[ ! -z ${kubeadm_config} ]]; then
		kubeadm init  --config  ${INSTALL_ROOT_PATH}/kubeadm.yaml 2>&1 | tee ${KUBEADM_INSTALL_INFO}
	fi
	
	if [[ -z $(cat ${KUBEADM_INSTALL_INFO} | egrep  "err|fail"  -i) ]]; then
		GREEN "kubernets cluster install finish ^_^"
	else
		RED "kubernets cluster install failed T_T"
		exit 1
	fi
	echo
}



function get_kubeadm_join_token()
{
	join_token_flags=$(cat ${KUBEADM_INSTALL_INFO} | grep  'kubeadm join' | grep  '\--token' | awk -F'\' '{print $1}')
	join_token_ca_cert_flags=$(cat ${KUBEADM_INSTALL_INFO} | grep  '\--discovery-token-ca-cert-hash')
	
	KUBENETERS_CLUSTER_TOKEN="${join_token_flags}  ${join_token_ca_cert_flags}"
	
	if [[ ! -z ${KUBENETERS_CLUSTER_TOKEN} ]]; then
		GREEN "kubernets cluster node join token is ok ^_^"
	else
		RED "kubernets cluster node join token is failed T_T"
	fi
	echo
}




function install_k8s_cluster_node()
{

	if [[ ! -z "$*" ]]; then
		KUBENETERS_CLUSTER_NODELIST=($*)
	fi
	
	get_kubeadm_join_token

	for ((i = 0; i < ${#KUBENETERS_CLUSTER_NODELIST[@]}; i++)); do
		k8s_cluster_node=${KUBENETERS_CLUSTER_NODELIST[i]}
		YELLOW "k8s node join: ${k8s_cluster_node}"
		
		if [[ ! -z $(echo ${k8s_cluster_node} | grep "[0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}[.][0-9]\{1,3\}") ]]; then
			YELLOW "ssh  ${k8s_cluster_node}  \"kubeadm reset -f\" "
			ssh  ${k8s_cluster_node}  "kubeadm reset -f"
			
			YELLOW "ssh  ${k8s_cluster_node}  \"${KUBENETERS_CLUSTER_TOKEN}\" "
			ssh  ${k8s_cluster_node}  "${KUBENETERS_CLUSTER_TOKEN}"
			scp /etc/kubernetes/admin.conf  root@${k8s_cluster_node}:/etc/kubernetes/admin.conf
		fi
	done

	if [[ ! -z $(kubectl get node) ]]; then
		GREEN "kubernets cluster insatll node finish ^_^"
	else
		RED "kubernets cluster insatll node failed T_T"
	fi
	echo
}



function install_k8s_cni()
{
	k8s_cni_config=$(ls ${INSTALL_ROOT_PATH} | grep  'kube-flannel.yml' )
	
	if [[ ! -z ${k8s_cni_config} ]]; then
		kubectl apply -f  ${INSTALL_ROOT_PATH}/kube-flannel.yml
		YELLOW "kubernets cluster cni install finish ^_^"
	fi
	
}



function main()
{
	# 判断当前环境kubeadm, kubectl, kubelet工具是否准备ok
	has_kube_tools

	# 安装kubernetes cluster master
	install_k8s_cluster_master
	
	# 安装kubernetes cluster node & 配置node节点admin.conf
	install_k8s_cluster_node  $*
	
	# 安装kube-flannel.yml 网络插件
	install_k8s_cni
	
	#显示k8s集群
	kubectl get node
}


# 需要传入的参数为, k8s 集群安装所需的node list
main $@
