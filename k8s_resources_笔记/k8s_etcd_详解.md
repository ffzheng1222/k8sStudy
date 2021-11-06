# k8s  etcd  详解



#### etcd的组成部分



```

http server/grpc server:

	主要处理client的操作请求以及节点之间的数据同步和心跳保持



raft状态机:

	通过raft一致性协议的实现来保证api server的命令具体实现

	

wal存储:

	负责具体的数据保持存储操作

	entry: 负责实际的日志数据存储

	snapsort: 是对日志数据的状态存储以防止过多的数据存在

```







#### 查询当前etcd集群中的所有节点: 



```sh

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list



显示下列结果: 

8e26ead5138d3770, started, 192.168.255.10, https://192.168.255.10:2380, https://192.168.255.10:2379

```







#### 移除etcd集群异常的节点



```sh

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member remove 8e26ead5138d3770



显示下列结果:

Removed member 8e26ead5138d3770 from cluster

```







#### 添加新节点到etcd集群



```sh

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member add ${etcd_name} --peer-urls=https://${etcd_name}:2380



显示下列结果:

Member 2be1eb8f84b7f63e added to cluster ef37ad9dc622a7c4

```







#### 检查etcd集群节点的健康状况



```sh

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key  endpoint health



显示下列结果:

192.168.255.10:2379 is healthy: successfully committed proposal: took = 724.457µs

```







#### 查询k8s etcd集群中数据的方法



```shell

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key    get /  --prefix  --keys-only | grep pod



显示下列结果:

/registry/pods/kube-system/coredns-7f89b7bc75-bmxbq

/registry/pods/kube-system/etcd-192.168.255.10

/registry/pods/kube-system/kube-apiserver-192.168.255.10

/registry/pods/kube-system/kube-controller-manager-192.168.255.10

/registry/pods/kube-system/kube-flannel-ds-2jzld

/registry/pods/kube-system/kube-proxy-ghsvp

/registry/pods/kube-system/kube-scheduler-192.168.255.10

/registry/podsecuritypolicy/psp.flannel.unprivileged

...



========================================================================================================

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key  get /registry/pods/kube-system/kube-proxy-ghsvp



显示下列结果:

etcd集群中这个key(/registry/pods/kube-system/kube-proxy-ghsvp) 对应的value值，信息是protocol buffer序列化后的数据



```







#### etcd集群内置快照



```sh

ETCDCTL_API=3 etcdctl --endpoints=192.168.255.10:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save snapshotdb



显示下列结果:

Snapshot saved at snapshotdb



========================================================================================================

ETCDCTL_API=3 etcdctl --write-out=table snapshot status snapshotdb

显示下列结果:

+----------+----------+------------+------------+

|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |

+----------+----------+------------+------------+

| 3d7ecaf7 |   288023 |       1047 |      18 MB |

+----------+----------+------------+------------+

```







