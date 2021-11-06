# k8s 核心组件的工作原理



![image-20210125014359637](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125014359637.png)







## API Server  工作原理



#### api server 的启动组件



```sh

kube-apiserver



[root@tony_tce:~] kubectl  get pod -A |grep kube-apiserver

kube-system   kube-apiserver-192.168.255.10            1/1     Running   3          5h15m



[root@tony_tce:~] netstat  -tlunp |grep kube-apiserve 

tcp6       0      0 :::6443                 :::*                    LISTEN      41802/kube-apiserve 

```







#### API Server的核心功能



```

提供kubernets各类资源对象(如pod、RC、service、pv/pvc等)的增、删、改、查以及 watch 等http rest接口，

成为集群内各个模块之间数据交互和通信的中心枢纽，是整个系统的数据总线



特点：

	a. 是集群管理的API入口

	b. 是资源配额控制的入口

	c. 提供了完备的集群安全机制

```



​	



#### API Server与k8s各功能模块交互



```

1. 与ETCD进程交互场景

   场景1: 集群内各个功能模块通过API Server将信息存入ETCD，当需要获取和操作这些数据时，

   		 则通过API Server提供的rest接口(get、list、watch方法)调用来实现，进而实现各模块之间的信息交互



========================================================================================================

2. kubelet进程与API Server交互场景

   场景1: 每个node节点上运行的kubelet进程每隔一个时间周期，就会调用一次API Server的rest接口报告自身的状态，

   		 API Server接收到这些信息后，会将节点状态信息更新到etcd中



   场景2: kubelet也通过API Server的watch接口监听etcd库中pod的信息，如果监听到新的pod副本被调度绑定到本节点，

   		 则执行pod对应的容器创建和启动逻辑; 如果监听到pod对象被删除，则删除本节点上相应的pod容器; 

   		 如果监听到修改pod的信息，则会相应的修改本节点的pod容器



========================================================================================================

3. kube-controller-manager进程与API Server交互场景

   场景1: kube-controller-manager 中的 Node Controller模块通过API Server提供的watch接口，

   		 实时监控Node的信息，并做相应的处理



========================================================================================================

4. kube-scheduler进程与API Server交互场景

   场景1: 当Scheduler通过API Server的watch接口监听到新建pod副本信息后，它会检索所有符合该pod要求的NOde节点列表，

		 开始执行pod调度逻辑，根据调度逻辑选择最优的node，调度成功后将pod绑定到目标节点上  

```







## Controller Manager  工作原理



#### Controller Manager的核心功能



```

Controller Manager作为集群内部的管理控制中心，主要负责集群内的node、pod副本、服务端点endpoint、命名空间mnamespace、

服务账号serviceaccount、资源定额resourcequota等的管理工作; 

当某个node意外宕机时，Controller Manager会及时的发现此故障并执行自动化修复流程，确保集群始终处于预期的工作状态

```







#### Controller Manager的几个重要Controller说明



```

1. Replication Controller

	核心作用: 确保在任何时候集群中的一个RC所关联的pod副本数量始终保持在预设值。

	

	主要职责:

		a. 确保当前集群中有且仅有N个pod实例，N是RC中定义的pod副本数量

		b. 通过调整RC的spec.replicas属性值来实现系统扩缩容 或者 通过kubectl scale xxx命令行手动实现扩缩容

		c. 通过改变RC中的pod模板(主要镜像版本)来实现系统的滚动升级

	

	典型使用场景：

		弹性伸缩	滚动升级	滚动更新

		

========================================================================================================

2. Node Controller

	核心作用: 实时监控集群中node的健康状态 (就绪Ready、未就绪NoReady、未知Unknown)

	

	主要职责:

		a. Controller Manager在启动时必须设置--cluster-cidr参数，保证每个node节点都生成一个CIDR地址

		b. 通过API Server的rest接口从etcd逐个读取节点信息，多次尝试修改nodeSttausMap中的节点信息，

     	   将该节点信息和Node Controller的nodeSttausMap中保存的节点信息做比较

     	   	  如果判断出没有收到节点kubelet信息: 节点处于未知Unknown状态

		c. 逐个读取节点信息，如果节点状态变为 "未就绪NoReady" 状态，则将节点加入待删除队列，

		   进而删除etcd中的节点信息，并删除和该节点相关的pod等资源的信息



========================================================================================================

3. Service Controller 与 Endpoint Controller

	核心作用: 

		Service Controller: 负责生成和维护所有service对象的控制器

		Endpoint Controller: 负责生成和维护所有Endpoint对象的控制器

	

	主要职责:

		Service Controller:

			...待补充

		Endpoint Controller:

			a. 负责监听service和对应的pod副本的变化，如果检测到service被删除，则删除和该service同名的endpoint对象;

			   如果检测到新的service备创建或修改，则根据该service信息获得相关的pod列表，然后创建或修改其对应的endpoint

			   对象; 如果检测到pod的事件，则更新它所对应的service和endpoint对象(增加、删除、修改对应的endpoint条目)

			b. endpoint对象作用于node节点上的kube-proxy进程，kube-proxy通过其实现service的负责均衡功能



```



![image-20210125022950430](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125022950430.png)







## Scheduler  工作原理



#### Scheduler 的核心功能



```

kube-schduler在整个系统中承担着 "承上启下" 的作用。

	承上: 负责接收Controller Manager创建的新pod，为其安排一个落脚的目标node  

	启下: 指安置工作完成后，目标node上的kubelet进程将接管pod的后继工作

```



![image-20210125021126595](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125021126595.png)







#### Scheduler 的调度流程



```go

将待调度的pod (API新建的pod、kube-controller-namager为弥补副本不足而创建的pod等) 

按照特定的调度算法和调度策略绑定到集群中的某个合适的node上，并将绑定信息写入到etcd中



========================================================================================================

整个调度过程中一共涉及三个对象: 待调度pod列表、可以node列表、调度算法和策略

整合起来就是，通过调度算法和策略，调度所有处于待调度pod列表中的pod从node列表中选择一个最合适的node安排其适居



========================================================================================================

整个调度流程分为两个阶段:

1. 预选策略(Predicates):

	输入是所有节点，输出是满足预选条件的节点。kube-scheduler根据预选策略过滤掉不满足策略的Nodes。

	例如，如果某节点的资源不足或者不满足预选策略的条件如“Node的label必须与Pod的Selector一致”时则无法通过预选

2. 优选策略(Priorities): 

	输入是预选阶段筛选出的节点，优选会根据优先策略为通过预选的Nodes进行打分排名，选择得分最高的Node。

	例如，资源越富裕、负载越小的Node可能具有越高的排名



========================================================================================================

调度流水线 (Schedule Pipeline) 主要有三个阶段：Scheduler Thread，Wait Thread，Bind Thread。

	Scheduler Thread 阶段: 从如下的架构图可以看到 Schduler Thread 会经历 

	Pre Filter -> Filter -> Post Filter-> Score -> Reserve，可以简单理解为 Filter -> Score -> Reserve

```







![image-20210125020659855](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125020659855.png)







#### Scheduler 的调度流水线



```

调度流水线 (Schedule Pipeline) 主要有三个阶段：

	Scheduler Thread、 Wait Thread、Bind Thread

	Scheduler Thread阶段: 

		从如下的架构图可以看到 Schduler Thread 会经历 

		Pre Filter -> Filter -> Post Filter-> Score -> Reserve，可以简单理解为 Filter -> Score -> Reserve

	Wait Thread阶段: 

		这个阶段可以用来等待 Pod 关联的资源的 Ready 等待，例如等待 PVC 的 PV 创建成功，

		或者 Gang 调度中等待关联的 Pod 调度成功等等

	Bind Thread阶段: 

		用于将 Pod 和 Node 的关联持久化 Kube APIServer

```



![image-20210125022008164](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125022008164.png)







#### Scheduler 的调度策略



```

一: 预选策略

1. NoDiskConflict

判断备选Pod的gcePersistentDisk或AWSElasticBlockStore和备选的节点中已存在的Pod是否存在冲突。



2.PodFitsResources

判断备选节点的资源是否满足备选Pod的需求。



3.PodSelectorMathes

判断备选节点是否包含备选Pod的标签选择器指定的标签。



4.PodFitsHost

判断备选Pod的spec.nodeName域所指定的节点名称和备选节点的名称是否一致。如果一致，则返回true,否则返回false.



5.CheckNodeLabelPresence

如果用户在配置文件中指定了该策略，则scheduler会通过RegisterCustomFitPredicate方法注册该策略。



6.CheckServiceAffinity

该策略用于判断备选节点是否包含策略指定的标签，或包含和备选Pod在相同Service和Namespace下的Pod所在节点的标签列表。 

如果存在，则返回true,否则返回false.



7.PodFitsPorts

判断备选Pod所用的端口列表中的端口是否在被选中已被占用，如果被占用则返回false，否则返回true



========================================================================================================

二: 优选策略



1.LeastRequestedPriority

从备选节点列表中选出资源消耗最小的节点。



2.CalculateNodeLabelPriority

该策略用于判断策略列出的标签在备选节点中存在时，是否选择该备选节点。



3.BalancedResourceAllocation

从备选节点列表中选出各项资源使用率最均衡的节点。

```







## kubelet 工作原理



#### kubelet  的核心功能



```

节点管理: 

	1. kubelet通过设置--register-node启动参数来决定是否向API Server注册自己

	2. 定时向API Server发送节点的新消息，API Server接收到这些新消息后会将此信息写入到etcd

	3. kubelet通过设置--node-status-update-frequency启动参数来决定多长时间向API Server报告节点状态

	

========================================================================================================

pod管理: (负责pod的生命周期管理)

	1. apiserver：通过 API Server 监听 etcd 目录获取数据

	2. File：启动参数 --config 指定的配置目录下的文件

	3. 通过 url 从网络上某个地址来获取信息

```



![image-20210125023049698](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125023049698.png)







#### kubelet管理pod的具体细节



```

kubelet通过apiserver watch监听etcd，所有的针对pod的操作将会被kubelet监听到



如果发现有新绑定到本节点的pod，则按照pod清单要求创建该pod



如果发现删除本节点的pod，则删除相应的pod，并通过Docker client删除pod中的容器



如果发现本地的pod被修改，则kubelet会做出相应的修改，比如删除pod中的某个容器时，则通过Docker client删除该容器



kubelet读取监听到的信息，如果是创建和修改pod任务，则做如下处理

	1. 为该pod创建一个数据目录

	2. 通过API Server读取etcd中存放的该pod清单

	3. 为该pod挂载外部卷 (External Volum)

	4. 下载pod所用的Secret

	5. 检查已经运行在节点中的pod，如果该pod没有容器或pause容器没有起启动，则先停止pod内所有容器进程; 

	   如果在pod有需要删除的容器，则先删除这些容器

	6. 用 "kubernets/pause" 镜像为每个pod创建一个容器

	7. 为pod中每个容器做如下处理

		a. 计算hash值，用容器名字查询对应docker容器hash之，如果找到容器，hash值不同，

		   则停止docker中容器进程，并停止与之关联的pause容器的进程。若相同，不做处理。

		b. 如果容器被终止了，没有指定restartPolicy，不做任何处理

		c. 调用docker client下载容器镜像，调用docker client运行容器



```







#### kubelet 容器健康检查



```

通过两类探针来检查容器健康状态:



LivenessProbe探针:

	用于判断容器是否健康。如果不健康kubelet删除该容器，并根据重启策略做相应处理;

	如果没有设置livenessProbe，认为返回的值用为是Success



ReadnessProbe探针: 

	用于判断容器是否启动完成，且准备接受请求。如果检查失败，pod状态将被修改。



LivenessProbe包含三种实现方式

	1. ExecAction：在容器内部执行一个命令，如果该命令退出状态码为0，表示健康

	2. TCPSocketAction：通过容器的IP地址和端口号指定TCP检查，如果端口能被访问，表示健康。

	3. HTTPGetAction: 通过容器的IP地址和端口号以及路径调用HTTP Get方法，如果响应码大于等于200且小于等于400，表示健康。

```







## kube-proxy 工作原理



![image-20210125031108134](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125031108134.png)







#### kube-proxy  的核心功能



```

在每个Node上都会运行一个kube-proxy服务进程，这个进程可以看做service的透明代理和负载均衡器。



其核心功能: 将某个service的访问请求转发到后端的某个Pod上。

对每一个TCP类型的service，kube-proxy都会在本地Node上建立一个socketserver来负责接收请求，然后均匀发送到后端某个Pod端口上。这个过程默认采用Round Robin负载均衡算法



========================================================================================================

service的clusterIP和Nodeport概念是proxy通过Iptables的NAT转换实现的。

proxy在运行过程中动态创建于service相关的Iptables规则，

这些规则实现了Cluster IP及NodePort的请求流量重定向到proxy进程上对应服务的代理端口的功能



换句话: 也就是说，访问service的请求，都会被节点机的Iptables规则重定向到kube-proxy监听service服务代理端口

```







![image-20210125030249410](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125030249410.png)







#### kube-proxy的工作细节



```

1. kube-proxy通过查询和监听API server中service和endpoint的变化，为每个service都建立了一个服务代理对象。

   服务代理对象是proxy程序内部的一种数据结构，它包括一个用于监听此服务请求的socketserver，

   socketserver的端口是随机选择的一个本地空闲端口



2. kube-proxy内部也创建了一个负载均衡器-LoadBalancer，

   LoadBalancer上保存了service到对应的后端endpoint列表的动态转发路由表

   

3. 针对发生变化的service列表，proxy会逐个处理，具体处理流程如下

	(1). 如果该service没有设置Cluster IP，则不做任何处理，否则获取该service的所有端口定义列表（spec.ports域）

	(2). 逐个读取服务端口定义列表中的端口信息，根据端口名称，service名称和namespace判断本地是否已经存在对应的服务代理对象，

		 如果不存在则新建，若存在并且service端口被修改过，则先删除Iptables中和该service端口相关的规则，关闭服务代理对象，

		 然后走新建流程，也就是为该service端口分配服务代理对象并为创建相关的Iptables规则。

	(3). 更新负载均衡器组件中对应service的转发地址列表，对于新建的service，确定转发时的会话保持策略。

	(4). 对于已删除的service则进行清理。

```







#### kube-proxy 与 iptable规则



```

proxy在启动时和坚挺到service或endpoint变化后，会在本机的Iptables的NAT表中添加4条规则链



1. KUBE-PORTALS-CONTAINER: 从容器中通过service Cluster IP和端口号访问service的请求。



2. KUBE-PORTALS-HOST: 从主机通过service Cluster IP和端口号访问service的请求。



3. KUBE-NODEPORT-CONTAINER: 从容器中通过service的NodePort端口号访问service的请求。



4. KUBE-NODEPORT-HOST: 从主机通过service的NodePort端口号访问service的请求。



此外，kube-proxy在Iptables上为每个service创建由Cluster IP+service端口到kube-proxy所在主机IP+service代理服务所监听的端口的转发规则

```







