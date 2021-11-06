# k8s 控制器模式







### 控制循环描述



![image-20210219144850402](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219144850402.png)



```

控制型模式:

	最核心的就是控制循环的概念。在控制循环中包括了控制器control，被控制的system系统，

	以及能够观测系统的传感器sensor，三个逻辑组件。



操作逻辑:

	1. 外界通过修改资源 spec 来控制资源，控制器比较资源 spec 和 status，从而计算一个 diff

	2. diff 最后会用来决定执行对系统进行什么样的控制操作，控制操作会使得系统产生新的输出，并被传感器以资源 status 形式上报

	3. 控制器的各个组件将都会是独立自主地运行，不断使系统向 spec 表示终态趋近

```







### 控制循环 之 Sensor & controller



![image-20210219145646427](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219145646427.png)



```

控制循环中逻辑的传感器主要由 Reflector、Informer、Indexer 三个组件构成



主要控制逻辑:

	1. Reflector 通过 List 和 Watch K8s server 来获取资源的数据

	2. List 用来在 Controller 重启以及 Watch 中断的情况下，进行系统资源的全量更新; 

	   Watch 则在多次 List 之间进行增量的资源更新

	3. Reflector 在获取新的资源数据后，会在 Delta 队列中塞入一个包括资源对象信息本身以及资源对象事件类型的 Delta 记录，		   Delta 队列中可以保证同一个对象在队列中仅有一条记录，从而避免 Reflector 重新 List 和 Watch 的时候产生重复的记录

	4. Informer 组件不断地从 Delta 队列中弹出 delta 记录，然后把资源对象交给 indexer，让 indexer 把资源记录在一个缓存中，	   缓存在默认设置下是用资源的命名空间来做索引的，并且可以被 Controller Manager 或多个 Controller 所共享

```



![image-20210219150207236](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219150207236.png)



```

控制循环中的控制器组件主要由事件处理函数以及 worker 组成，事件处理函数之间会相互关注资源的新增、更新、删除的事件，

并根据控制器的逻辑去决定是否需要处理



主要控制逻辑:

	1. 对需要处理的事件，会把事件关联资源的命名空间以及名字塞入一个工作队列中，并且由后续的 worker 池中的一个 Worker 来处理，工作队列会对存储的对象进行去重，从而避免多个 Woker 处理同一个资源的情况。

	2. Worker 在处理资源对象时，一般需要用资源的名字来重新获得最新的资源数据，用来创建或者更新资源对象，或者调用其他的外部服务，Worker 如果处理失败的时候，一般情况下会把资源的名字重新加入到工作队列中，从而方便之后进行重试。

```







### 控制循环例子 pod 副本扩容



```

ReplicaSet 是一个用来描述无状态应用的扩缩容行为的资源， 

ReplicaSet controler 通过监听 ReplicaSet 资源来维持应用希望的状态数量

```



![image-20210219151000088](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219151000088.png)







![image-20210219151132468](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219151132468.png)







![image-20210219151156779](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219151156779.png)







### 控制器模式总结



#### 1. 两种 API 设计方法



```

两种API设计方法包括：命令式API & 声明式API



Kubernetes 控制器模式依赖声明式的 API

```



![image-20210219151654395](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219151654395.png)







#### 2. 命令式 API 的问题



![image-20210219151732162](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219151732162.png)







#### 3. 控制器模式总结



```

1. Kubernetes 所采用的控制器模式，是由声明式 API 驱动的。确切来说，是基于对 Kubernetes 资源对象的修改来驱动的；

3. Kubernetes 资源之后，是关注该资源的控制器。这些控制器将异步的控制系统向设置的终态驱近；

4. 这些控制器是自主运行的，使得系统的自动化和无人值守成为可能；

5. 因为 Kubernetes 的控制器和资源都是可以自定义的，因此可以方便的扩展控制器模式。特别是对于有状态应用，我们往往通过自定义资源和控制器的方式，来自动化运维操作。这个也就是后续会介绍的 operator 的场景。

```



![image-20210219154350893](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219154350893.png)



