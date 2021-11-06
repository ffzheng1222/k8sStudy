# k8s Job & DaemonSet 编排原理



### Job资源管理



#### Job管理任务的控制器作用



![image-20210219162124233](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219162124233.png)







#### Job 特殊知识点



```

Job 里面，主要重点关注的一个是 restartPolicy 重启策略和 backoffLimit 重试次数限制。



restartPolicy

	在 Job 里面我们可以设置 Never、OnFailure、Always 这三种重试策略。

	在希望 Job 需要重新运行的时候，我们可以用 Never；希望在失败的时候再运行，再重试可以用 OnFailure；

	或者不论什么情况下都重新运行时 Alway。

backoffLimit

	Job 在运行的时候不可能去无限的重试，所以我们需要一个参数来控制重试的次数。



======================================================================================================

Job表示状态的信息:

	AGE: 的含义是指这个 Pod 从当前时间算起，减去它当时创建的时间。这个时长主要用来告诉你 Pod 的历史、Pod 距今创建了多长时间。	  DURATION: 主要来看我们 Job 里面的实际业务到底运行了多长时间，当我们的性能调优的时候，这个参数会非常的有用。

	COMPLETIONS: 主要来看我们任务里面这个 Pod 一共有几个，然后它其中完成了多少个状态，会在这个字段里面做显

	



======================================================================================================

并行运行Job

主要看两个参数：一个是 completions，一个是 parallelism



completions

	用来指定副本 Pod 队列执行次数

parallelism	

	表示这个并行执行的个数。所谓并行执行的次数，其实就是一个管道或者缓冲器中缓冲队列的大小

```







#### Job 特殊spec字段



```

schedule

	schedule 这个字段主要是设置时间格式，它的时间格式和 Linux 的 crontime 是一样的，

	所以直接根据 Linux 的 crontime 书写格式来书写就可以了。

	举个例子： */1 指每分钟去执行一下 Job，这个 Job 需要做的事情就是打印出大约时间，

	然后打印出“Hello from the kubernetes cluster” 这一句话；



startingDeadlineSeconds

	每次运行 Job 的时候，它最长可以等多长时间，有时这个 Job 可能运行很长时间也不会启动。所以这时，

	如果超过较长时间的话，CronJob 就会停止这个 Job；



concurrencyPolicy

	就是说是否允许并行运行。所谓的并行运行就是，比如说我每分钟执行一次，但是这个 Job 可能运行的时间特别长，

	假如两分钟才能运行成功，也就是第二个 Job 要到时间需要去运行的时候，上一个 Job 还没完成。

	如果这个 policy 设置为 true 的话，那么不管你前面的 Job 是否运行完成，每分钟都会去执行；

	如果是 false，它就会等上一个 Job 运行完成之后才会运行下一个；



JobsHistoryLimit

	这个就是每一次 CronJob 运行完之后，它都会遗留上一个 Job 的运行历史、查看时间。

	当然这个额不能是无限的，所以需要设置一下历史存留数，一般可以设置默认 10 个或 100 个都可以，

	这主要取决于每个人集群不同，然后根据每个人的集群数来确定这个时间。

```







#### Job控制器原理



![image-20210219170420608](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219170420608.png)



### DaemonSet资源管理



#### DaemonSet守护进程控制器作用



```

DaemonSet 也是 Kubernetes 提供的一个 default controller，它实际是做一个守护进程的控制器，它能帮我们做到以下几件事情：



. 首先能保证集群内的每一个节点都运行一组相同的 pod

. 同时还能根据节点的状态保证新加入的节点自动创建对应的 pod

. 在移除节点的时候，能删除对应的 pod

. 而且它会跟踪每个 pod 的状态，当这个 pod 出现异常、Crash 掉了，会及时地去 recovery 这个状态





======================================================================================================

DaemonSet 适用场景



1. 集群存储进程：glusterd 、 ceph

2. 日志收集进程：fluentd 、 logstash

3. 需要在每个节点运行的监控收集器	

```







#### DaemonSet 资源更新策略



```

DaemonSet 和 deployment 特别像，它也有两种更新策略：一个是 RollingUpdate，另一个是 OnDelete。



RollingUpdate 

	其实比较好理解，就是会一个一个的更新。先更新第一个 pod，然后老的 pod 被移除，

	通过健康检查之后再去见第二个 pod，这样对于业务上来说会比较平滑地升级，不会中断；



OnDelete 

	其实也是一个很好的更新策略，就是模板更新之后，pod 不会有任何变化，需要我们手动控制。

	我们去删除某一个节点对应的 pod，它就会重建，不删除的话它就不会重建，

	这样的话对于一些我们需要手动控制的特殊需求也会有特别好的作用。

```



![image-20210219171223221](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219171223221.png)







####  DaemonSet 控制器原理



```

DaemonSet 的控制器原理:

	1. DaemonSet 其实和 Job controller 做的差不多：两者都需要根据 watch 这个 API Server 的状态。

	现在 DaemonSet 和 Job controller 唯一的不同点在于，DaemonsetSet Controller需要去 watch node 的状态，

	但其实这个 node 的状态还是通过 API Server 传递到 ETCD 上。

	

	2. 当有 node 状态节点发生变化时，它会通过一个内存消息队列发进来，然后DaemonSet controller 会去 watch 这个状态，

	   看一下各个节点上是都有对应的 Pod，如果没有的话就去创建。当然它会去做一个对比，

	   如果有的话，它会比较一下版本，然后加上刚才提到的是否去做 RollingUpdate？ 

	   如果没有的话就会重新创建，Ondelete 删除 pod 的时候也会去做 check 它做一遍检查，是否去更新，或者去创建对应的 pod。



	3. 当然最后的时候，如果全部更新完了之后，它会把整个 DaemonSet 的状态去更新到 API Server 上，完成最后全部的更新。

```



![image-20210219171546511](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219171546511.png)







