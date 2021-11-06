# k8s service的理解







#### k8s  service  类型 & 作用



```

ClusterIP: 用于为集群内Pod访问时,提供的固定访问地址,默认是自动分配地址,可使用ClusterIP关键字指定固定IP  

		   (APIServer的向集群内部提供服务的Service)



NodePort: 用于为集群外部访问Service后面Pod提供访问接入端口

		  这种类型的service工作流程为:

　　　　　　Client----->NodeIP:NodePort----->ClusterIP:ServicePort----->PodIP:ContainerPort



LoadBalancer: 用于当K8s运行在一个云环境内时, 若该云环境支持LBaaS, 则此类型可自动触发创建

　　　　　　　　一个软件负载均衡器用于对Service做负载均衡调度

　　　　　　　　因为外部所有Client都访问一个NodeIP,该节点的压力将会很大, 而LoadBalancer则可解决这个问题。

　　　　	   而且它还直接动态监测后端Node是否被移除或新增了，然后动态更新调度的节点数



ExternalName: 用于将集群外部的服务引入到集群内部，在集群内部可直接访问来获取服务

			  它的值必须是 FQDN, 此FQDN为集群内部的FQDN, 即: ServiceName.Namespace.Domain.LTD.

　　　　　　	  然后CoreDNS接受到该FQDN后，能解析出一个CNAME记录, 该别名记录为真正互联网上的域名.

　　　　　    　如: www.test.com, 接着CoreDNS在向互联网上的根域DNS解析该域名，获得其真实互联网IP.

```







#### K8s Service原理介绍



```

1. kube-proxy都通过watch的方式监控着kube-APIServer写入etcd中关于Pod的最新状态信息,

   它一旦检查到一个Pod资源被删除了 或 新建，它将立即将这些变化，反应再iptables 或 ipvs规则中，

   以便iptables和ipvs在调度Clinet Pod请求到Server Pod时，不会出现Server Pod不存在的情况。



2. Service的externalName类型原理介绍:

   Pod---->SVC[externalName]------[SNAT]----->宿主机的物理网卡------>物理网关----->Internat上提供服务的服务器.



　 K8s中资源的全局FQDN格式:

　 Service_NAME.NameSpace_NAME.Domain.LTD.

　 Domain.LTD.=svc.cluster.local.　　　　 #这是默认k8s集群的域名。



　 注意: Service是externelName类型时, externalName必须是域名,而且此域名必须能被CoreDNS或CoreDNS能通过

　　　　 互联网上的根DNS解析出A记录.

```







#### ks8 service 工作方式



 主要有两种：  iptables模型 & ipvs模型



```

iptables模型:

此工作方式是直接由内核中的iptables规则，接受Client Pod的请求，并处理完成后，直接转发给指定ServerPod.

```



![image-20210124202442913](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124202442913.png)



```

ipvs模型:

它是直接有内核中的ipvs规则来接受Client Pod请求，并处理该请求,再有内核封包后，直接发给指定的Server Pod .

```



![image-20210124202616047](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124202616047.png)







#### headless service(无头service)



```

headless service: 是指没有ClusterIP的service, 它仅有一个service name 这个服务名解析得到的不是

				  service的集群IP，而是Pod的IP, 当其它人访问该service时，将直接获得Pod的IP,进行直接访问。



headless使用场景

1. 自主选择权，有时候client想自己来决定使用哪个Real Server，可以通过查询DNS来获取Real Server的信息。

2. Headless Service的对应的每一个Endpoints，即每一个Pod，都会有对应的DNS域名；这样Pod之间就能互相访问，集群也能单独访问pod

   每一个pod的DNS域名形式：<pod_name>.<headless_service>.<pod_namespaces>.svc.cluster.local

```







