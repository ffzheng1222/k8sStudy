# k8s deployment 编排原理







### Deployment：管理部署发布的控制器



```

1. 首先，Deployment 定义了一种 Pod 期望数量，比如说应用 A，我们期望 Pod 数量是四个，

   那么这样的话，controller 就会持续维持 Pod 数量为期望的数量。当我们与 Pod 出现了网络问题或者宿主机问题的话，

   controller 能帮我们恢复，也就是新扩出来对应的 Pod，来保证可用的 Pod 数量与期望数量一致

   

2. 配置 Pod 发布方式，也就是说 controller 会按照用户给定的策略来更新 Pod，而且更新过程中，

   也可以设定不可用 Pod 数量在多少范围内

 

3. 如果更新过程中发生问题的话，即所谓“一键”回滚;

   也就是说你通过一条命令或者一行修改能够将 Deployment 下面所有 Pod 更新为某一个旧版本

```







#### Deployment 状态查看



![image-20210219155026302](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219155026302.png)







#### Deployment 更新镜像更新



```sh

kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.9.1

```



![image-20210219155234718](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219155234718.png)







#### Deployment 快速回滚



```sh

# 回滚到deployment的上一个版本

kubectl rollout undo deployment.v1.apps/nginx-deployment



# 回滚到deployment到某一个版本，在回滚之前需要先查询版本列表

kubectl rollout histtory deploymentv1.apps/nginx-deployment

kubectl rollout undo deployment.v1.apps/nginx-deployment --to-revision=2

```



![image-20210219155404284](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219155404284.png)







#### Deployment status 状态信息轮转



![image-20210219160018387](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219160018387.png)











### Deployment 架构设计



#### Deployment 管理模式



```

Deployment 创建 ReplicaSet，而 ReplicaSet 创建 Pod。他们的 OwnerRef 其实都对应了其控制器的资源

```



![image-20210219160230521](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219160230521.png)







#### Deployment & Reployment 控制器



```

Deployment控制器的主要控制逻辑:

	1. 首先，我们所有的控制器都是通过 Informer 中的 Event 做一些 Handler 和 Watch。

	   这个地方 Deployment 控制器，其实是关注 Deployment 和 ReplicaSet 中的 event，收到事件后会加入到队列中。

	2. 而 Deployment controller 从队列中取出来之后，它的逻辑会判断 Check Paused，

	   这个 Paused 其实是 Deployment 是否需要新的发布，如果 Paused 设置为 true 的话，

	   就表示这个 Deployment 只会做一个数量上的维持，不会做新的发布。

	

	3. 如果 Check paused 为 Yes 也就是 true 的话，那么只会做 Sync replicas。也就是说把 replicas sync 同步到对应的 	   ReplicaSet 中，最后再 Update Deployment status，那么 controller 这一次的 ReplicaSet 就结束了。

	4. 如果 paused 为 false 的话，它就会做 Rollout，也就是通过 Create 或者是 Rolling 的方式来做更新，

	   更新的方式其实也是通过 Create/Update/Delete 这种 ReplicaSet 来做实现的。

```



![image-20210219160431252](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219160431252.png)



```

ReplicaSet控制器的主要控制逻辑:

	1. 当 Deployment 分配 ReplicaSet 之后，ReplicaSet 控制器本身也是从 Informer 中 watch 一些事件，

	   这些事件包含了 ReplicaSet 和 Pod 的事件。

	2. 从队列中取出之后，ReplicaSet controller 的逻辑很简单，就只管理副本数。

	   也就是说如果 controller 发现 replicas 比 Pod 数量大的话，就会扩容，而如果发现实际数量超过期望数量的话，就会删除 Pod

```



![image-20210219160448178](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219160448178.png)







### Deployment spec特殊字段解释



```

MinReadySeconds

	Deployment 会根据 Pod ready 来看 Pod 是否可用，但是如果我们设置了 MinReadySeconds 之后，

	比如设置为 30 秒，那 Deployment 就一定会等到 Pod ready 超过 30 秒之后才认为 Pod 是 available 的。

	Pod available 的前提条件是 Pod ready，但是 ready 的 Pod 不一定是 available 的，

	它一定要超过 MinReadySeconds 之后，才会判断为 available；

 

revisionHistoryLimit

	保留历史 revision，即保留历史 ReplicaSet 的数量，默认值为 10 个。

	这里可以设置为一个或两个，如果回滚可能性比较大的话，可以设置数量超过 10

 

paused

	paused 是标识，Deployment 只做数量维持，不做新的发布，这里在 Debug 场景可能会用到；

 

progressDeadlineSeconds

	前面提到当 Deployment 处于扩容或者发布状态时，它的 condition 会处于一个 processing 的状态，processing 可以设置一个超	 时时间。如果超过超时时间还处于 processing，那么 controller 将认为这个 Pod 会进入 failed 的状态。

	



MaxUnavailable

	滚动过程中最多有多少个 Pod 不可用；

MaxSurge

	滚动过程中最多存在多少个 Pod 超过预期 replicas 数量。

```







