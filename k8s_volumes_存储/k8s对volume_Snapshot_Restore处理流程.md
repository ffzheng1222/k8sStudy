# k8s对volume Snapshot/Restore处理流程







![image-20210901115409427](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210901115409427.png)







#### 创建 Snapshot volume的流程



```

user 提交创建snapshot需求，通过kube-apiserver将snapshot定义信息存储到etcd  -->

csi-snapshottor controller 通过 kube-apiserver watch 到etcd中待创建snapshot的需求  -->

调用云存储厂商volume driver plugin(csi-controller-server)  -->  

远端存储介质Cloud Storage Vendor  -->  CreateSnapshot  -->  

触发csi-snapshottor创建VolumeSnapshotContent对象，并将其余VolumeSnapshot对象做bound关联

```







#### 从Snapshot volume中恢复PV数据的流程



```

user 提交声明指定restore的pvc需求，通过kube-apiserver将restore pvc定义信息存储到etcd  -->

csi-provisioner controller 通过 kube-apiserver watch 到etcd中待创建restore pvc的需求  -->

调用云存储厂商volume driver plugin(csi-controller-server)  -->

远端存储介质Cloud Storage Vendor  -->  CreateVolume(snapshot ID)  -->

csi-provisioner controller根据之前csi-controller-serve 创建的Volume信息，创建新的pv对象并同步snapshot中的pv数据  -->

最后调用PV controller将new PV对象与restore PVC对象做bond关联

```







