# tce  dns 理解







#### pajero 注册域名信息记录



```

curl -X GET http://127.0.0.1:30150/api/v1alpha1/service/instances | python -m json.tool > /tmp/tony_pajero.txt

```







#### tce dns 功能



```

功能描述：

TCS 在部署完毕后，默认会存在coredns、cluster-dns、global-dns这3个DNS相关的pod：



coredns：

	是容器集群自带的用于解析kubernetes原生svc的域名如kubernetes.default.svc.cluster.local



cluster-dns：开启了kubernetes插件用于取代前述默认的coredns并且提供集群内部自定义服务的解析



global-dns： 则提供暴露给其他集群或者全局的自定义域名服务的解析

```







#### tce dns 解析策略



```

coredns的解析策略是由 deployment 的dnsPolicy字段来声明



dnsPolicy一共有四种解析策略: None、Default、ClusterFirst、ClusterFirstWithHostNet



None: 

	表示空的DNS设置这种方式一般用于想要自定义 DNS 配置的场景，

	而且，往往需要和 dnsConfig 配合一起使用达到自定义 DNS 的目的。



Default:

	kubelet 来决定使用何种 DNS 策略。而 kubelet 默认的方式，就是使用宿主机的 /etc/resolv.conf

	kubelet 也可以灵活来配置使用什么文件来进行DNS策略的，

	使用 kubelet 的参数：–resolv-conf=/etc/resolv.conf 来决定你的DNS解析文件地址

	

ClusterFirst:

	表示 POD 内的 DNS 使用集群中配置的 DNS 服务，使用 Kubernetes 中 kubedns 或 coredns 服务进行域名解析

	如果解析不成功，才会使用宿主机的 DNS 配置进行解析



ClusterFirstWithHostNet:

	pod启用 HOST 模式，表示这个 POD 中的所有容器，都要使用宿主机的 /etc/resolv.conf 配置进行DNS查询，

	但如果你想使用了 HOST 模式，还继续使用 Kubernetes 的DNS服务，那就将 dnsPolicy 设置为 ClusterFirstWithHostNet





========================================================================================================



[root@tcs-10-200-1-133 ~]# kubectl  get deployments   -nkube-system | grep dns

coredns                    	2/2     2            2           115d

coredns-cluster-dns         3/3     3            3           115d

coredns-global-dns          3/3     3            3           115d



[root@tcs-10-200-1-133 ~]# kubectl  get deployments -nkube-system coredns-cluster-dns -o yaml  | grep dnsPolicy

      dnsPolicy: Default





[root@tcs-10-200-1-133 ~]# kubectl  get deployments -nkube-system coredns-global-dns -o yaml  | grep dnsPolicy

      dnsPolicy: Default





说明: coredns-cluster-dns、coredns-global-dns 的dnsPolicy都是采用Default模式，即默认让节点上的kubelet进程自己选择dns解析策略， 一般地 kubelet进程会选择宿主机内部的 /etc/resolv.conf 来作为dns本地缓存解析

```







#### tce dns域名解析过程分析



```

[root@tcs-10-200-1-133 ~]# kubectl  get svc -nkube-system 

NAME                        TYPE           CLUSTER-IP

kube-dns                    ClusterIP      192.168.192.10 

coredns-global-dns          NodePort       192.168.192.11

coredns-global-dns-lb-tcp   LoadBalancer   192.168.241.42

coredns-global-dns-lb-udp   LoadBalancer   192.168.192.46





========================================================================================================



[root@tcs-10-200-1-133 ~]# kubectl  get svc -nkube-system   coredns-global-dns 

NAME                 TYPE       CLUSTER-IP

coredns-global-dns   NodePort   192.168.192.11





[root@tcs-10-200-1-133 ~]# kubectl  get svc -nkube-system   coredns-global-dns -o yaml | grep selector -A1

  selector:

    app.kubernetes.io/name: global-dns





[root@tcs-10-200-1-133 ~]# kubectl  get pod  -nkube-system -l 'app.kubernetes.io/name=global-dns'

NAME                                 READY   STATUS    RESTARTS   AGE

coredns-global-dns-d4b566b5f-5wths   1/1     Running   0          34d

coredns-global-dns-d4b566b5f-6q4hm   1/1     Running   0          17d

coredns-global-dns-d4b566b5f-v2h7j   1/1     Running   0          17d







========================================================================================================



[root@tcs-10-200-1-133 ~]# kubectl  get svc -nkube-system kube-dns 

NAME       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE

kube-dns   ClusterIP   192.168.192.10   <none>        53/UDP,53/TCP,9153/TCP   115d







[root@tcs-10-200-1-133 ~]# kubectl  get svc -nkube-system   kube-dns -oyaml | grep selector -A1

  selector:

    k8s-app: cluster-dns		



# k8s原生的coredns svc的selector被改写为k8s-app：cluster-dns

# 而k8s-app=cluster-dns标签匹配的是集群内cluster-dns pod





[root@tcs-10-200-1-133 ~]# kubectl  get  pod -nkube-system -l 'k8s-app=cluster-dns'

NAME                                   READY   STATUS    RESTARTS   AGE

coredns-cluster-dns-7b49cb5cc6-hvfgp   1/1     Running   0          34d

coredns-cluster-dns-7b49cb5cc6-p2sbm   1/1     Running   0          34d

coredns-cluster-dns-7b49cb5cc6-qtfrb   1/1     Running   0          18d





========================================================================================================

容器内（dnsPolicy为ClusterFirst或ClusterFirstWithHostNet）



DNS调用链为：

	192.168.192.10 kube-dns svc -> cluster-dns pods -> global-dns svc -> 

	global-dns pods -> 如果有配upstream则forward到外部域名服务器



而生产节点则使用global-dns对外暴露的服务（NodePort和LoadBalancer），一般用的是集群计算节点node1 IP和node2 IP，所以它们只能查到global-dns中有的underlay服务，不能查到容器集群内部服务的解析

```







#### tce dns域名解析总结



```

[root@tcs-10-200-1-133 ~]# kubectl  get svc -nkube-system 

NAME                        TYPE           CLUSTER-IP

kube-dns                    ClusterIP      192.168.192.10 

coredns-global-dns          NodePort       192.168.192.11



========================================================================================================



对于 coredns-cluster-dns 而言，<请求域名> 凡是到达cluster-dns pod， 会做如下处理



1. 首先经过cluster-dns pod所在宿主机的/data/infra.tce.io/clusterdns/coredns.data

   做本地dns缓存解析

   



[root@tcs-10-200-0-6 ~]# kubectl get cm -nkube-system coredns-cluster-dns -o yaml | grep forward

      forward . 192.168.192.11



2. 若解析不通过，则 forward 到 192.168.192.11 (coredns-global-dns) ,

   即 <请求域名> 会被转发给 global-dns 的svc处理





3. pod内部定义的search域

[root@tcloud-tke-static-749c896487-rnfh6 /]# cat  /etc/resolv.conf  

nameserver 192.168.192.10

search tce.svc.cluster.local svc.cluster.local cluster.local

options ndots:5 single-request-reopen timeout:1





cluster-dns总结：

	1. 针对k8s集群内部的svc --> svc的ClusterIP

		a. cluster-dns pod内部的coredns容器进程会作为dns service运行

		b. 将svc名称与容器内的/etc/resolv.conf的search域做结合，组成完整的svc域名

		c. 将组合完成后完整的svc域名作为dns client解析请求发给dns service解析

		d. coredns通过集成的多种插件(cache缓存记录)对dns client请求解析



	2. 针对k8s集群内部的自定义域名解析

		a. cluster-dns pod内部的coredns容器进程会作为dns service运行

		b. 直接会交由cluster-dns pod挂载到本地dns缓存记录

           (/data/infra.tce.io/clusterdns/coredns.data.cluster)解析

        c. cluster-dns pod的宿主机/data/infra.tce.io/clusterdns/coredns.data.cluster

        	记录信息来自于pajero自定义域名注册中心下发

    

    3. 如果k8s集群内部的自定义域名解析失败

    	域名解析请求会被forward到global dns的svc(192.168.192.11) --> global dns pod

    	走global dns域名解析流程





========================================================================================================



对于 coredns-global-dns 而言，<请求域名> 凡是到达global-dns pod， 会做如下处理



<请求域名>直接经过global-dns pod所在宿主机的/data/infra.tce.io/globaldns/coredns.data

做本地dns缓存解析





global-dns总结 (underlay)：

	1. 针对k8s集群外部的自定义域名解析

		a. global-dns pod内部的coredns容器进程会作为dns service运行

		b. 直接会交由global-dns pod挂载到本地dns缓存记录

           (/data/infra.tce.io/globaldns/coredns.data.global)解析

        c. cluster-dns pod的宿主机/data/infra.tce.io/globaldns/coredns.data.global

        	记录信息来自于pajero自定义域名注册中心下发



```







