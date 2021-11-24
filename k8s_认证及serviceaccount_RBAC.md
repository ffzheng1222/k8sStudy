

#  k8s认证及serviceaccount & RBAC



## k8s apiserver  request 请求模板

**在k8s上，一个客户端向apiserver发起请求，需要如下信息：**

```
1）username，uid，
2) group,
3) extra(额外信息)
4) API
5) request path,例如：http://127.0.0.1:8080/apis/apps/v1/namespaces/kube-system/d
6）HTTP request action，如get,post,put,delete,
7）Http request action，如 get,list,create,udate,patch,watch,proxy,redirect,delete,deletecollection
8） Rresource
9）Subresource
10）Namespace
11）API group
```



## 创建service account

```shell
# pod 使用serviceAccountName字段说明
[root@tony_tce:~]  kubectl explain pods.spec.serviceAccountName


# 创建最简单的 serviceaccount 对象
[root@tony_tce:~]  kubectl -n tony-test  create serviceaccount admin -o yaml --dry-run > tonysa.yaml


# [root@tony_tce:~] cat tonysa.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: null
  name: admin
  namespace: tony-test


#  查看tony-test下的 serviceaccount & 对应生成的secret对象 (sa自动就会多一个secret token)
[root@tony_tce:~]  kubectl  get   ServiceAccount  -n tony-test 
NAME      SECRETS   AGE
admin     1         137m
default   1         137m

[root@tony_tce:~]  kubectl describe sa admin -n tony-test
Name:                admin
Namespace:           tony-test
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   admin-token-nxp2p
Tokens:              admin-token-nxp2p
Events:              <none>

[root@tony_tce:~]  kubectl  get secret    -n tony-test
NAME                  TYPE                                  DATA   AGE
admin-token-nxp2p     kubernetes.io/service-account-token   3      139m
default-token-fskmj   kubernetes.io/service-account-token   3      140m

 
# pod配置清单把serviceaccount和pod绑定起来：
[root@tony_tce:~]  cat nginx-sa-test.yaml 
apiVersion: v1
kind: Pod
metadata: 
  annotations:
    tonyfan.com/created-by: "cluster admin"
  name: nginx
  labels: 
    app: nginx
  namespace: tony-test	
spec: 
  containers:
  - name: nginx
    image: nginx:alpine
    imagePullPolicy: IfNotPresent 
    ports: 
    - name: nginx-http 
      containerPort: 80
      protocol: TCP
  serviceAccountName: admin	  #绑定 tony-test namespaces下的admin serviceAccount对象
```



## 创建user account

 ==kubeconfig是客户端连接apiserver时使用的认证格式的配置文件，kubectl  config xxx操作的就是kubeconfig配置文件==

```shell
# k8s集群证书默认存放位置：
[root@tony_tce:~]  cd /etc/kubernetes/pki/ && ls
-rw------- 1 root root 1679 11月 19 21:59 ca.key
-rw-r--r-- 1 root root 1066 11月 19 21:59 ca.crt
-rw------- 1 root root 1675 11月 19 21:59 apiserver.key
-rw-r--r-- 1 root root 1269 11月 19 21:59 apiserver.crt
-rw------- 1 root root 1679 11月 19 21:59 apiserver-kubelet-client.key
-rw-r--r-- 1 root root 1143 11月 19 21:59 apiserver-kubelet-client.crt
-rw------- 1 root root 1679 11月 19 21:59 front-proxy-ca.key
-rw-r--r-- 1 root root 1078 11月 19 21:59 front-proxy-ca.crt
-rw------- 1 root root 1675 11月 19 21:59 front-proxy-client.key
-rw-r--r-- 1 root root 1103 11月 19 21:59 front-proxy-client.crt
drwxr-xr-x 2 root root  162 11月 19 21:59 etcd
-rw------- 1 root root 1675 11月 19 21:59 apiserver-etcd-client.key
-rw-r--r-- 1 root root 1135 11月 19 21:59 apiserver-etcd-client.crt
-rw------- 1 root root  451 11月 19 21:59 sa.pub
-rw------- 1 root root 1675 11月 19 21:59 sa.key
-rw-r--r-- 1 root root   17 11月 24 19:29 ca.srl



# 生成私钥，私钥再通过k8s 集群的ca.crt签名认证 生成x509证书，进而访问k8s集群
# 1.制作一个私钥
[root@tony_tce:/etc/kubernetes/pki] 
(umask 077; openssl genrsa -out tonyfan.key 2048)

# 2.基于私钥生成一个证书 
[root@tony_tce:/etc/kubernetes/pki] 
openssl req -new -key tonyfan.key -out tonyfan.csr -subj "/CN=tonyfan"  # CN就是用户的账户名字
-subj: 替换或指定证书申请者的个人信息

# 3.基于证书通过k8s的ca.crt签名认证生成用户可访问k8s集群的x509证书文件tonyfan.crt 
[root@tony_tce:/etc/kubernetes/pki]
openssl  x509 -req -in tonyfan.csr -CA  ca.crt  -CAkey ca.key  -CAcreateserial -out tonyfan.crt -days 365  # 会自动生成Signature签名账号信息
Signature ok
subject=/CN=tonyfan
Getting CA Private Key

-days: 表示证书的过期时间 
x509: 生成x509格式证书

# 4. 查看x509证书内容
[root@tony_tce:/etc/kubernetes/pki] 
openssl x509 -in tonyfan.crt -text -noout
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number:
            e2:51:02:24:7c:73:9e:e1
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes	#证书签署人
        Validity	#有效期限
            Not Before: Nov 24 11:29:25 2021 GMT
            Not After : Nov 24 11:29:25 2022 GMT
        Subject: CN=tonyfan		#一会用这个账户登录k8s
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
					...
		Signature Algorithm: sha256WithRSAEncryption
			...

[root@tony_tce:/etc/kubernetes/pki]  ll -lrt 
-rw------- 1 root root 1679 11月 19 21:59 ca.key
-rw-r--r-- 1 root root 1066 11月 19 21:59 ca.crt
-rw------- 1 root root 1675 11月 19 21:59 apiserver.key
-rw-r--r-- 1 root root 1269 11月 19 21:59 apiserver.crt
-rw------- 1 root root 1679 11月 19 21:59 apiserver-kubelet-client.key
-rw-r--r-- 1 root root 1143 11月 19 21:59 apiserver-kubelet-client.crt
-rw------- 1 root root 1679 11月 19 21:59 front-proxy-ca.key
-rw-r--r-- 1 root root 1078 11月 19 21:59 front-proxy-ca.crt
-rw------- 1 root root 1675 11月 19 21:59 front-proxy-client.key
-rw-r--r-- 1 root root 1103 11月 19 21:59 front-proxy-client.crt
drwxr-xr-x 2 root root  162 11月 19 21:59 etcd
-rw------- 1 root root 1675 11月 19 21:59 apiserver-etcd-client.key
-rw-r--r-- 1 root root 1135 11月 19 21:59 apiserver-etcd-client.crt
-rw------- 1 root root  451 11月 19 21:59 sa.pub
-rw------- 1 root root 1675 11月 19 21:59 sa.key
-rw------- 1 root root 1675 11月 24 19:29 tonyfan.key
-rw-r--r-- 1 root root  887 11月 24 19:29 tonyfan.csr
-rw-r--r-- 1 root root  977 11月 24 19:29 tonyfan.crt
-rw-r--r-- 1 root root   17 11月 24 19:29 ca.srl


# 把自定义用户tonyfan账户信息添加到k8s集群中
[root@tony_tce:/etc/kubernetes/pki]
kubectl config set-credentials tonyfan --client-certificate=tonyfan.crt --client-key=tonyfan.key --embed-certs=true

embed-certs：表示把用户信息隐藏起来

# 设置context上下文，指定tonyfan用户访问k8s的哪个集群
[root@tony_tce:~]
kubectl config set-context tonyfan@kubernetes --cluster=kubernetes --user=tonyfan


# 查看用户的context信息 (即: kubeconfig配置信息)
[root@tony_tce:~]  kubectl  config  view
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://192.168.255.10:6443
  name: kubernetes
contexts:
- context:	 # context定义了哪个集群用哪个用户来访问
    cluster: kubernetes		# context指定的ks8集群名
    user: kubernetes-admin	# context指定k8s集群管理员用户名
  name: kubernetes-admin@kubernetes		# k8s集群管理员的contexts名
- context:
    cluster: kubernetes
    user: tonyfan
  name: tonyfan@kubernetes
current-context: kubernetes-admin@kubernetes	# 当前环境下正在使用的k8s contexts
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: tonyfan
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED


# 通过kubectl config use-context xxx 操作来切换当前不通用户的context
# 切换到 kubernetes-admin/tonyfan 用户登录k8s 
kubectl config use-context kubernetes-admin@kubernetes
kubectl config use-context tonyfan@kubernetes

```



## RBAC（基于角色的访问控制）

 ==rbac:role based ac，也就是我们把用户加入角色里面，这样用户就具有角色的权限了==

 ==在k8s中，一切皆对象==

 ==Object_URL: /apis/<GROUP>/<VERSION>/namespaces/<NAMESPACE_NAME>/<KIND>[OJJECT_ID]==

![image-20211124230637315](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20211124230637315.png)



**RBAC是通过rolebinding把user绑定到role上的。**

**1. role是基于namespace设定的，也就是这说这个user只能访问指定namespace下的pod资源**

```shell
# 1. 在tony-test namespaces创建role对象
[root@tony_tce:~]
kubectl -n tony-test  create role pods-reader --verb=get,list,watch --resource=pods  -o yaml --dry-run

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: pods-reader
  namespace: tony-test
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
  

[root@tony_tce:~] 
kubectl -n tony-test  create role pods-reader --verb=get,list,watch --resource=pods 


# 在tony-test namespaces查看role对象
[root@tony_tce:~]  kubectl get role -n tony-test  
NAME          CREATED AT
pods-reader   2021-11-24T11:07:48Z

[root@tony_tce:~]kubectl   describe    role -n tony-test  
Name:         pods-reader
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods       []                 []              [get list watch]


# 2. 在tony-test创建rolebinding对象 同时绑定 tonyfan用户
[root@tony_tce:~]
kubectl -n tony-test  create rolebinding tonyfan-read-pods --role=pods-reader --user=tonyfan -o yaml --dry-run

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: tonyfan-read-pods
  namespace: tony-test
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pods-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: tonyfan
  
[root@tony_tce:~]
kubectl -n tony-test  create rolebinding tonyfan-read-pods --role=pods-reader --user=tonyfan


# 在tony-test namespaces查看rolebinding对象
[root@tony_tce:~]  kubectl get rolebinding  -n tony-test 
NAME                ROLE               AGE
tonyfan-read-pods   Role/pods-reader   5s


[root@tony_tce:~]  kubectl describe rolebinding  -n tony-test 
Name:         tonyfan-read-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pods-reader
Subjects:
  Kind  Name     Namespace
  ----  ----     ---------
  User  tonyfan 	#绑定user accunt
  
  
 # 3. 使用user account查看pod资源
[root@tony_tce:~]  kubectl  config use-context  tonyfan@kubernetes 
Switched to context "tonyfan@kubernetes".

[root@tony_tce:~]  kubectl  get pod -n tony-test
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          4h47m

[root@tony_tce:~]  kubectl  get   role
Error from server (Forbidden): roles.rbac.authorization.k8s.io is forbidden: User "tonyfan" cannot list resource "roles" in API group "rbac.authorization.k8s.io" in the namespace "default"

```





**2. 如果把user通过clusterrolebind绑定到clusterrole上后，那么这个user就突破了namespace的限制，而拥有了集群级别的权限，即这个用户可以访问这个集群下所有namespace下的pod了**

```shell
# 1. 创建 clusterrole 对象
[root@tony_tce:~]
kubectl create clusterrole tony-cluster-reader --verb=get,list,watch --resource=pods -o yaml --dry-run

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: tony-cluster-reader
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
  
[root@tony_tce:~]
kubectl create clusterrole tony-cluster-reader --verb=get,list,watch --resource=pods 

# 查看 clusterrole 对象
[root@tony_tce:~]  kubectl  get  clusterrole  |grep  tony
tony-cluster-reader           							2021-11-24T11:36:09Z

[root@tony_tce:~]  kubectl  describe   clusterrole  tony-cluster-reader 
Name:         tony-cluster-reader
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods       []                 []              [get list watch]


# 2. 创建 clusterrolebinding 对象
[root@tony_tce:~]
kubectl create clusterrolebinding tonyfan-read-all-pods --clusterrole=tony-cluster-reader --user=tonyfan -o yaml --dry-run
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  name: tonyfan-read-all-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tony-cluster-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: tonyfan

[root@tony_tce:~]
kubectl create clusterrolebinding tonyfan-read-all-pods --clusterrole=tony-cluster-reader --user=tonyfan

# 查看 clusterrolebinding 对象
[root@tony_tce:~]  kubectl  get  clusterrolebinding  | grep  tony
tonyfan-read-all-pods       ClusterRole/tony-cluster-reader 		3h55m

[root@tony_tce:~]  kubectl  describe   clusterrolebinding  tonyfan-read-all-pods 
Name:         tonyfan-read-all-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  tony-cluster-reader
Subjects:
  Kind  Name     Namespace
  ----  ----     ---------
  User  tonyfan  #绑定的user account


 # 3. 使用user account查看pod资源
[root@tony_tce:~]  kubectl  config    use-context  tonyfan@kubernetes 	#切换到tonyfan account
Switched to context "tonyfan@kubernetes".

[root@tony_tce:~]  kubectl   get pod  -n kube-system 
NAME                                 READY   STATUS    RESTARTS   AGE
coredns-7f89b7bc75-gmhtz             0/1     Running   9          5h15m
coredns-7f89b7bc75-wp55g             0/1     Running   9          5h15m
etcd-k8s-master                      1/1     Running   0          33h
kube-apiserver-k8s-master            1/1     Running   0          33h
kube-controller-manager-k8s-master   1/1     Running   1          33h
kube-flannel-ds-amd64-8stp5          1/1     Running   0          33h
kube-flannel-ds-amd64-bw2md          1/1     Running   0          33h
kube-flannel-ds-amd64-gfs9k          1/1     Running   0          33h
kube-proxy-f6xf9                     1/1     Running   0          33h
kube-proxy-h8lmh                     1/1     Running   0          33h
kube-proxy-zgwxh                     1/1     Running   0          33h
kube-scheduler-k8s-master            1/1     Running   1          33h

[root@tony_tce:~]kubectl   get  svc   -n kube-system 
Error from server (Forbidden): services is forbidden: User "tonyfan" cannot list resource "services" in API group "" in the namespace "kube-system"
[root@tony_tce:~]

```





**3. 如果把user通过rolebinding去绑定到clusterrole上。而rolebinding只限制在namespace中，所以user1也只限定在namespace中，而不是整个集群中**

```shell
# 1. 创建 clusterrole 对象
[root@tony_tce:~]
kubectl create clusterrole ns-tony-cluster-reader --verb=get,list,watch --resource=pods -o yaml --dry-run

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: ns-tony-cluster-reader
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
  
[root@tony_tce:~]
kubectl  create  clusterrole  ns-tony-cluster-reader --verb=get,list,watch --resource=pods 

# 查看 clusterrole 对象
[root@tony_tce:~]  kubectl  get  clusterrole  |grep  tony
ns-tony-cluster-reader           							2021-11-24T11:36:09Z

[root@tony_tce:~]  kubectl  describe   clusterrole  ns-tony-cluster-reader 
Name:         ns-tony-cluster-reader
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods       []                 []              [get list watch]
  

# 2. 在tony-test创建rolebinding对象 同时绑定 tonyfan用户
[root@tony_tce:~]
kubectl -n tony-test  create rolebinding  ns-tony-cluster-reader --role=pods-reader --user=tonyfan -o yaml --dry-run

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: ns-tony-cluster-reader
  namespace: tony-test
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pods-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: tonyfan

[root@tony_tce:~]
kubectl -n tony-test  create rolebinding  ns-tony-cluster-reader --role=pods-reader --user=tonyfan


# 在tony-test namespaces查看rolebinding对象
[root@tony_tce:~]  kubectl get rolebinding  -n tony-test 
NAME                     ROLE               AGE
ns-tony-cluster-reader   Role/pods-reader   100s


[root@tony_tce:~] kubectl describe  rolebinding  -n tony-test 
Name:         ns-tony-cluster-reader
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pods-reader
Subjects:
  Kind  Name     Namespace
  ----  ----     ---------
  User  tonyfan 	#绑定user accunt


 # 3. 使用user account查看pod资源
[root@tony_tce:~]  kubectl  config   use-context  tonyfan@kubernetes 
Switched to context "tonyfan@kubernetes".

[root@tony_tce:~]  kubectl  get   pod   -n tony-test
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          5h10m

[root@tony_tce:~]  kubectl  get   pod    -n  kube-system 
Error from server (Forbidden): pods is forbidden: User "tonyfan" cannot list resource "pods" in API group "" in the namespace "kube-system"

```

