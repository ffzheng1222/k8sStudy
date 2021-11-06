# k8s pod的细节说明











#### pod的常用操作方法



 <!-- 假设那么namespaces 为 "test" -->



 kubectl  get pod  -ntest  podName



 kubectl  get pod  -ntest  podName -o yaml	`# 查看pod的yml详细配置`



 kubectl  get pod  -ntest  podName -o wide	`# 查看pod所调度的节点`



 kubectl  get pod  -ntest  podName  -o json



 kubectl  describe   pod  -ntest  podName	`# 查看pod的describe描述信息`



 kubectl  logs  podName  -ntest	`# 查看pod的日志与docker logs containerID类同`



 kubectl  edit  pod  -ntest  podName	`# 编辑pod的yaml配置信息`



 kubectl  delete pod  -ntest  podName	`# 删除pod`



 **kubectl  delete pod  -ntest  podName  --wait=false	`# 删除pod不等待其重建完成`**



 **kubectl  delete pod  -ntest  podName  --force --grace-period=0	`# 强制立即删除pod`**



 kubectl  exec  -ti  -ntest  podName  bash 	`# 进入到pod容器内部并执行bash执行`



 **kubectl  exec  -ti  -ntest  podName  -c  容器Name  bash   `# 指定进入pod内部的某个容器并执行bash指令`**







#### pod 的生命周期



	Pending：Pod 定义正确，提交到 Master，但其包含的容器镜像还未完全创建。通常处在 Master 对 Pod 的调度过程中。

	ContainerCreating：Pod 的调度完成，被分配到指定 Node 上。处于容器创建的过程中。通常是在拉取镜像的过程中。

	Running：Pod 包含的所有容器都已经成功创建，并且成功运行起来。

	Successed：Pod 中所有容器都成功结束，且不会被重启。这是 Pod 的一种最终状态。

	Failed：Pod 中所有容器都结束，但至少一个容器以失败状态结束。这也是 Pod 的一种最终状态。

	Unknown： 由于一些原因，Pod 的状态无法获取，通常是与 Pod 通信时出错导致的。







#### container容器的状态



一旦scheduler调度器将 Pod 分派给某个节点，kubelet 就通过容器运行时 开始为 Pod 创建容器。 



<!--容器的状态有三种：Waiting（等待）、Running（运行中）和 Terminated（已终止）-->



```

Waiting （等待）：

如果容器并不处在 Running 或 Terminated 状态之一，它就处在 Waiting 状态。 

处于 Waiting 状态的容器仍在运行它完成启动所需要的操作：例如，从某个容器镜像 仓库拉取容器镜像，或者向容器应用 Secret 数据等等。 当你使用 kubectl 来查询包含 Waiting 状态的容器的 Pod 时，你也会看到一个 Reason 字段，其中给出了容器处于等待状态的原因。



Running（运行中）：

Running 状态表明容器正在执行状态并且没有问题发生。 

如果配置了 postStart 回调，那么该回调已经执行且已完成



Terminated（已终止）：

Terminated 状态的容器已经开始执行并且或者正常结束或者因为某些原因失败。 

如果你使用 kubectl 来查询包含 Terminated 状态的容器的 Pod 时，你会看到 容器进入此状态的原因、退出代码以及容器执行期间的起止时间。如果容器配置了 preStop 回调，则该回调会在容器进入 Terminated 状态之前执行

```







#### pod的启动过程



![image-20210219113736234](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219113736234.png)



![image-20210125023921609](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210125023921609.png)







#### pod的终止过程



![image-20210124160412669](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124160412669.png)



