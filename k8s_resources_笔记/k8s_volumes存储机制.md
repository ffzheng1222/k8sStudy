# k8s volumes存储机制



#### pv详解



```

定义: PersistentVolume (PV)是集群中由管理员提供或使用存储类动态提供的一块存储

特点: PV是与Volumes类似的卷插件，但其生命周期与使用PV的任何单个Pod无关



1. 存储能力：Capacity

	

2. 访问模式：Access Modes

    # ReadWriteOnce: RWO  单节点挂载，具备读写权限

    # ReadOnlyMany:  ROX  多节点挂载，具备只读权限 

    # ReadWriteMany: RWX  多节点挂载，具备读写权限

        

3. 回收策略 Reclaim Policy

	Retain (保留)：删除pvc后pv还存在并且标注为已释放，但是pv是不可用的。

			删除的步骤如下： (1)删除pv远端存储的数据不会被清理; (2)手动清理数据 (3)删除关联的存储资产

	Recycle (回收空间)：清理 pv 内的数据

	Delete (删除)：删除会针对pvc、pv 操作, 远端数据不会被清理。

```







#### pvc详解



```

定义: PersistentVolumeClaim (PVC) 是用户对存储的请求。



特点: 它类似于Pod；Pods消耗节点资源，而PVC消耗PV资源。

	  Pods可以请求特定级别的资源(CPU和内存)。而Claim可以请求特定的存储大小和访问模式(例如，它们可以挂载一次读写或多次只读)

```







#### pv & pvc的生命周期



```

1. Provisioning (资源供应)

	静态模式: 集群管理员手工创建许多PV，在定义PV时需要将后端存储的特性进行设置

	动态模式: 集群管理员无须手工创建PV，而是通过StorageClass的设置对后端存储进行描述，标记为某种类型。

			 此时要求PVC对存储的类型进行声明，系统将自动完成PV的创建及与PVC的绑定。

			 PVC可以声明Class为""，说明该PVC禁止使用动态模式。



2. Binding (资源绑定)

	在用户定义好PVC之后，系统将根据PVC对存储资源的请求（存储空间和访问模式）在已存在的PV中选择一个满足PVC要求的PV，

	一旦找到，就将该PV与用户定义的PVC进行绑定，kubectl查询pvc状态显示为Bound。

	特点：

		a. 如果在系统中没有满足PVC要求的PV，PVC则会无限期处于Pending状态

		b. PV一旦绑定到某个PVC上，就会被这个PVC独占，不能再与其他PVC进行绑定



3. Using (资源使用)

	声明Volume的类型为persistentVolumeClaim，在容器应用挂载了一个PVC后，就能被持续独占使用

	存储使用(using) & PVC保护(partition)



4. Releasing (资源释放)

	用户可以删除PVC，与该PVC绑定的PV将会被标记为“已释放”，但还不能立刻与其他PVC进行绑定，

	通过之前PVC写入的数据可能还被留在存储设备上，只有在清除之后该PV才能再次使用。



5. Reclaiming (资源回收)

	对于PV，管理员可以设定回收策略，用于设置与之绑定的PVC释放资源之后如何处理遗留数据的问题。

	只有PV的存储空间完成回收，才能供新的PVC绑定和使用

```



![image-20210124215607883](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124215607883.png)







#### StorageClass详解



```

Kubernetes提供了一套可以自动创建PV的机制, 即:Dynamic Provisioning. 而这个机制的核心在于:StorageClass这个API对象.



StorageClass对象会定义下面两部分内容:

	1. PV的属性, 比如存储类型,Volume的大小等.

	2. 创建这种PV需要用到的存储插件



	原理: 有了这两个信息之后, Kubernetes就能够根据用户提交的PVC, 找到一个对应的StorageClass, 

		 之后Kubernetes就会调用该StorageClass声明的存储插件, 进而创建出需要的PV可

```







#### pv_pvc_storageclass  工作原理



![image-20210124213555924](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124213555924.png)



![image-20210124213540969](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124213540969.png)



