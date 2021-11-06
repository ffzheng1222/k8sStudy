# k8s 集群基础配置



#### kubectl使用table键自动补全方法



```

yum install -y bash-completion



locate bash_completion



将git-completion.bash 添加到 ~/.bashrc



source /etc/bash_completion.d/git-completion.bash	

```







#### k8s core 配置文件存放位置



**/etc/kubernetes/  &   /etc/kubernetes/manifests/**



```

[root@tony_tce:~] ls /etc/kubernetes/

admin.conf  basic_auth_file  controller-manager.conf  kube-flannel.yml  kubelet.conf  manifests  pki  scheduler.conf

```



```

[root@tony_tce:~]ls /etc/kubernetes/manifests/

etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml

```







#### etcd库默认存放位置



**/var/lib/etcd/**



```sh

[root@tony_tce:~]kubectl  get pod  -nkube-system  etcd-192.168.255.10  -o yaml  |grep  -w '\- hostPath' -A 3 

  - hostPath:

    path: /etc/kubernetes/pki/etcd

    type: DirectoryOrCreate

    name: etcd-certs

  - hostPath:

    path: /var/lib/etcd

    type: DirectoryOrCreate



=========================================================================================================



[root@tony_tce:~]ls /var/lib/etcd/

member

```







#### kube-apiserver默认端口



https 默认安全访问端口6443    http访问默认8080端口



```shell

[root@tony_tce:~]kubectl get pod -nkube-system kube-apiserver-192.168.255.10 -o yaml  |grep -w "secure-port"

    - --secure-port=6443

```







#### kubelet 配置文件修改



**/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf**



```

[root@tony_tce:~]cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf



# Note: This dropin only works with kubeadm and kubelet v1.11+



[Service]

Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"

Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"



# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically



EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env



# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use



# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.



EnvironmentFile=-/etc/sysconfig/kubelet

ExecStart=

ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS

```







#### flannel 自定义配置信息



**/etc/cni/net.d**



https://my.oschina.net/u/4172827/blog/3082785/



```

[root@tony_tce:~]cat /etc/cni/net.d/10-flannel.conflist  

{

  "name": "cbr0",

  "cniVersion": "0.3.1",

  "plugins": [

    {

      "type": "flannel",

      "delegate": {

        "hairpinMode": true,

        "isDefaultGateway": true

      }

    },

    {

      "type": "portmap",

      "capabilities": {

        "portMappings": true

      }

    }

  ]

}

[root@tony_tce:~]

[root@tony_tce:~]

[root@tony_tce:~]cat /etc/cni/net.d/10-mynet.conf  

{

        "cniVersion": "0.2.0",

        "name": "mynet",

        "type": "bridge",

        "bridge": "cni0",

        "isGateway": true,

        "ipMasq": true,

        "ipam": {

                "type": "host-local",

                "subnet": "10.244.0.0/16",

                "routes": [

                        { "dst": "0.0.0.0/0" }

                ]

        }

}

[root@tony_tce:~]

[root@tony_tce:~]

[root@tony_tce:~]cat /etc/cni/net.d/99-loopback.conf  

{

        10-mynet.conf "cniVersion": "0.2.0",

        10-mynet.conf "name": "lo",

        10-mynet.conf "type": "loopback"

}

```







#### node节点使用kubectl的方法



```

将 /etc/kubernetes/admin.conf 拷贝到node节点的 /etc/kubernetes/admin.conf



export KUBECONFIG=/etc/kubernetes/admin.conf

```







#### kubernets 的认证 & 授权方式



```

认证方式:

	客户端证书认证、 静态Token认证、 Servie Account Tokens认证

	

授权方式:

	RBAC授权

```







#### kubernets 的准入控制



```

原则上: 对kubernets api的请求过程中，顺序为 先经过认证 & 授权 --> 执行准入操作 --> 操作目标对象



准入控制组件:

	AlwaysAdmit: 允许所有的请求

	AlwaysDeny: 禁止所有的请求，多用于测试环境

	Service Account: 它将ServiceAccount实现了自动化

	LimitRanger: 它会观察所有的请求，确保没有违反已经定义好的约束条件

	NamespacesExists: 它会观察所有的请求，如果请求尝试创建一个不存在的namespace，则这个请求会被拒绝

```







#### Helm官网链接



```

https://helm.sh/zh/docs/intro/quickstart/

```







