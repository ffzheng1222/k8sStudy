# k8s 对 PV+PVC体系的完整处理流程 







![image-20210901012345365](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210901012345365.png)







### 动态PV创建&绑定流程



```

user提交pvc定义 --> 

kube-apiserver将pvc定义信息存储到etcd --> 

csi-provisioner通过kube-apiserver watch到etcd中pvc的创建请求  -->  

通过csi-controller-server调用远端存储介质创建pvc定义的对应pv对象  -->  

kube-controller-manager组件中的PV controller将对应的pv与pvc做bond关联

```



### pod挂载并应用pv/pvc流程



```

user提交pod使用pvc存储定义 --> 

kube-apiserver将pod定义信息存储到etcd --> 

kube-scheduler通过watch etcd中pod的创建信息，选择合适的node节点为pod调度,并将调度信息保存到etcd  -->  

kube-controller-manager组件中的AD controller会通过watch etcd中pod将被调度到的node节点信息 以及 pod定义中所有使用的pvc信息生成对应的volumeattachments对象  -->  

触发csi-attacher组件进行attach操作(attach操作：通过csi-controller-server调用远端的pv存储挂载到k8s node节点)  -->  kubelet组件中的volum-plugin根据pod定义到的所有pv信息以及attached结果，调用node节点上运行的csi-node-server完成将pv mount到pod内部

```















![image-20210901021349783](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210901021349783.png)



```

阶段1 (create阶段): pv创建 & pvc绑定



阶段2 (attach阶段): pv attach到node节点



阶段3 (mount 阶段): pv mount到pod内部使用

```







