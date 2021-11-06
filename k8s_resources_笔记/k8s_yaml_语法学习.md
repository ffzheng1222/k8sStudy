# k8s yaml 语法学习



#### k8s yaml字段类型总结：



```yaml

string: 字符串类型

integer: 整数类型

boolean: bool类型 <true/false>

Object: 对象类型, 内部包含其他数据类型, 下辖字段换行缩进表示

map[string]string: 映射类型, key: value, 下辖字段换行缩进表示

* []string: 字符串数组类型, 下辖字段换行同级'- '表示	

* []Object: 对象数组类型, 下辖字段换行同级'- '表示



-required-: 表示此字段为必须字段

```







#### pod  yaml  编写规则



```yaml

apiVersion  <string>    #resource所处版本

kind        <string>    #resource类型

metadata  <Object>          #resource的元数据信息

  name         <string>     #resource 名称

  labels       <map[string]string>      #resource 标签用于被selector匹配

  annotations  <map[string]string>      #resource 自定义注解, 以key: value形式被外部使用

  namespace    <string>                 #resource 所处的命名空间

  ownerReferences      <[]Object>       #resource 的上层依赖

spec  <Object>  #resource的预期状态

  containers <[]Object> -required-  # pod 运行的container 列表

    name <string> -required-        # container 名称

    args        <[]string>          # container 执行带入的参数

    command     <[]string>          # container 执行CMD命令

    env         <[]Object>          # 设置到container容器内部的env环境变量

    image       <string>            # container 的镜像地址

    imagePullPolicy      <string>   # container 镜像拉取策略 (Always, Never, IfNotPresent)

    livenessProbe       <Object>    # container 的存活性探针

      exec <Object>

        command      <[]string>

      httpGet      <Object>

        port <string> -required-

        host <string>

        path <string>

        scheme       <string>

      tcpSocket    <Object>

        port <string> -required-

        host <string>

    readinessProbe       <Object>  # container 的就绪性探针

    ports   <[]Object>         # container 的映射端口

      containerPort       <integer> -required-

      hostPort            <integer>  # container要在主机上公开的端口号, 如果指定了HostNetwork，则必须匹配		     

      protocol            <string>

    volumeMounts    <[]Object>           # 设置container 挂载volume存储卷的挂载点

      name <string> -required-           # 设置container内部挂载volumes的name唯一匹配标识

      mountPath     <string> -required-  # 设置name指定的volumes存储卷挂载到container的目录path

      readOnly      <boolean>            # 设置container内部name指定volumes存储卷的挂载点的读写权限

  initContainers       <[]Object>   # pod 业务运行正式运行之前需运行的初始化container列表

  hostNetwork  <boolean>            # 请求Pod的主机网络, 使用主机的网络名称空间。如果设置了此选项，则必须指定将使用的端口。默认为false。

  nodeName     <string>             # 将pod调度到特定节点上的请求(节点资源足够为前提)

  nodeSelector <map[string]string>  # 必须与节点的标签相匹配才能在其上调度pod容器

  tolerations  <[]Object>           # 设置pod的容忍性调度(匹配node节点上的污点 taints)

  affinity     <Object>             # 设置pod的亲和反亲和性调度

  volumes      <[]Object>     # 设置pod挂载的存储卷volume

    name <string> -required-  # name是被container容器volumeMounts挂载的唯一标识

    configMap    <Object>     # configMap  key:value形式

    secret       <Object>     # secret   敏感加密的key:value形式

    emptyDir     <Object>     # emptyDir 挂载的宿主机上的一个空目录  

    hostPath     <Object>     # hostPath 挂载到宿主机指定目录，使用本地存储

    persistentVolumeClaim        <Object>   # PVC共享存储

    nfs  <Object>             # nfs网络存储

```



#### pod yaml  编写模板



```yaml

apiVersion: v1

kind: Pod

metadata: 

  name: nginx

  labels: 

    app: nginx

  namespace: tony-test

spec: 

  containers:

  - name: nginx

    image: nginx:alpine

    imagePullPolicy: IfNotPresent   

    livenessProbe:

        failureThreshold: 3

        httpGet:

          path: /healthz

          port: http

          scheme: HTTP

    readinessProbe:

        failureThreshold: 3

        httpGet:

          path: /healthz

          port: http

          scheme: HTTP

    ports: 

    - containerPort: 80

      hostPort: 80     

      protocol: TCP

    volumeMounts: 

    - name: nginx-log

      mountPath: /data/tony_log 

  hostNetwork: true

  volumes: 

  - hostPath: 

      path: /data/tony/log

      type: DirectoryOrCreate

    name: nginx-log

```







#### deployment  yaml  编写规则



```yaml

apiVersion  <string>    #resource所处版本

kind        <string>    #resource类型

metadata  <Object>          #resource的元数据信息

  name         <string>     #resource deployment名称

  labels       <map[string]string>      #resource 标签用于被selector匹配

  annotations  <map[string]string>      #resource 自定义注解, 以key: value等形式被外部使用

  namespace    <string>                 #resource 所处的命名空间

  finalizers   <[]string>               #resource 保护模式

  ownerReferences      <[]Object>       #resource 的上层依赖

spec  <Object>  #resource的预期状态

  selector     <Object> -required-          

    matchLabels  <map[string]string>		#通过此label选择器来匹配deployment管辖内pod的label

  replicas     <integer>                    #设置deployment管辖内pod副本数

  template     <Object> -required-          #设置deployment管辖内pod的模板定义

    metadata     <Object>                   #设置deployment管辖内pod的resource元数据信息

      annotations  <map[string]string>      #resource 自定义注解, 以key: value等形式被外部使用

      labels       <map[string]string>      #设置deployment管辖内pod的label标签       

    spec <Object> 

      containers <[]Object> -required-  # pod 运行的container 列表

        name <string> -required-        # container 名称

        args        <[]string>          # container 执行带入的参数

        command     <[]string>          # container 执行CMD命令

        env         <[]Object>          # 设置到container容器内部的env环境变量

        image       <string>            # container 的镜像地址

        imagePullPolicy      <string>   # container 镜像拉取策略 (Always, Never, IfNotPresent)

        livenessProbe        <Object>   # pod container 的存活性探针 (ready pending uknow terminate)

        readinessProbe       <Object>   # container 的就绪性探针

          exec <Object>

            command      <[]string>

          httpGet      <Object>

            port <string> -required-

            host <string>

            path <string>

            scheme       <string>

          tcpSocket    <Object>

            port <string> -required-

            host <string>

        ports   <[]Object>         # container 的映射端口

          containerPort       <integer> -required-	# pod内部容器的服务端口

          hostPort            <integer>  # container要在主机上公开的端口号, 如果指定了HostNetwork，则必须匹配

          protocol            <string>

        volumeMounts    <[]Object>           # 设置container 挂载volume存储卷的挂载点

          name <string> -required-           # 设置container内部挂载volumes的name唯一匹配标识

          mountPath     <string> -required-  # 设置name指定的volumes存储卷挂载到contssainer的目录path

          readOnly      <boolean>            # 设置container内部name指定volumes存储卷的挂载点的读写权限

      initContainers       <[]Object>   # pod 业务运行正式运行之前需运行的初始化container列表

      hostNetwork  <boolean>            # 请求Pod的主机网络, 使用主机的网络名称空间。如果设置了此选项，则必须指定将使用的端口。默认为false。 

      nodeSelector <map[string]string>  # 必须与节点的标签相匹配才能在其上调度pod容器

      schedulerName    <string>         # 如果指定，则将由指定的调度程序调度pod

      tolerations  <[]Object>           # 设置pod的容忍性调度(匹配node节点上的污点 taints)

      affinity     <Object>             # 设置pod的亲和反亲和性调度

      volumes      <[]Object>     # 设置pod挂载的存储卷volume

        name <string> -required-  # name是被container容器volumeMounts挂载的唯一标识

        configMap    <Object>     # configMap  key:value形式

        secret       <Object>     # secret   敏感加密的key:value形式

        emptyDir     <Object>     # emptyDir 挂载的宿主机上的一个空目录  

        hostPath     <Object>     # hostPath 挂载到宿主机指定目录，使用本地存储

        persistentVolumeClaim        <Object>   # PVC共享存储

        nfs  <Object>             # nfs网络存储

```



#### deployment  yaml  编写模板



```yaml

apiVersion: apps/v1

kind: Deployment

metadata: 

  name: tomcat-deploy

  namespace: tony

spec: 

  selector:

    matchLabels:

      app: tomcat

  replicas: 2

  template:

    metadata: 

      labels: 

        app: tomcat

        module: deploy_test

    spec: 

      containers: 

      - name: tomcat

        #command: ["/bin/sh"]

        #args: ["-c","while true;do echo hello;sleep 1;done"]

        args: 

        - -c

        - /usr/tomcat/bin/startup.sh && while true; do echo "Hello tony ^_^" && sleep 2; done

        command: 

        - /bin/sh

        image: cheewai/tomcat

        imagePullPolicy: IfNotPresent

        livenessProbe:

          exec:

            command:

            - sh

            - /tce/healthchk.sh

        ports: 

        - containerPort: 8080

          name: tomcat-port

          hostPort: 8080   

          protocol: TCP

        readinessProbe: 

          exec: 

            command:

            - /bin/sh

            - /tce/healthchk.sh

        volumeMounts: 

        - name: tomcat-log

          mountPath: /data

        - name: tomcat-tce

          mountPath: /tce

      hostNetwork: true

      volumes: 

      - hostPath: 

           path: /data/tce

           type: DirectoryOrCreate

        name: tomcat-tce

      - hostPath: 

           path: /data/tomcat/log

           type: DirectoryOrCreate

        name: tomcat-log

```







#### service  yaml  编写规则



```yaml

apiVersion  <string>    #resource所处版本

kind        <string>    #resource类型

metadata  <Object>          #resource的元数据信息

  name         <string>     #resource deployment名称

  labels       <map[string]string>      #resource 标签用于被selector匹配

  annotations  <map[string]string>      #resource 自定义注解, 以key: value等形式被外部使用

  namespace    <string>                 #resource 所处的命名空间

  finalizers   <[]string>               #resource 保护模式

  ownerReferences      <[]Object>       #resource 的上层依赖

spec  <Object>  #resource的预期状态

  selector     <map[string]string>      # service关联后端pod的标签选择器       

  type <string>                         # service的类型 ( ExternalName, ClusterIP, NodePort, LoadBalancer )

  clusterIP    <string>                 # 设置指定的service clusterIP (None: 表示headless service)

  ports        <[]Object>

    port <integer> -required-           # 通过service暴露出来的端口号

    targetPort   <string>               # 后端pod映射出来的容器端口

    nodePort     <integer>              # 如果service的type为NodePort类型, 那么此字段表示nodePort的端口号

    protocol     <string>               # service端口通信协议

    name <string>                       # 给service暴露出来的端口设置名称

```



#### service  yaml  编写模板



```yaml

apiVersion: v1

kind: Service

metadata: 

  name: tomcat-service

  labels: 

    app-svc: tomcat-svc

  namespace: tony

spec: 

  selector: 

    app: tomcat

  type: ClusterIP

  ports: 

  - port: 8080

    name: tomcat-svc-port

    targetPort: 8080

    protocol: TCP

```







#### statefulset  yaml  编写模板



```yaml

apiVersion: apps/v1

kind: StatefulSet

metadata: 

  name: mongo

  namespace: tony

spec: 

  serviceName: "mongo"

  selector:    

    matchLabels: 

      role: mongo

  replicas: 3

  template: 

    metadata: 

      labels:

        role: mongo

    spec: 

      terminationGracePeriodSeconds: 10

      containers: 

      - name: mongo

        command: 

        - mongo

        - "--replSet"

        - rs0

        - "--smallfiles"

        - "--noprealloc"

        image: mongo

        ports: 

        - containerPort: 27017

        volumeMounts: 

        - name: mongo-persistent-storage

          mountPath: /data/db

      - name: mongo-sidecar

        image: cvallance/mongo-k8s-sidecar

        env: 

        - name: MONGO_SIDECAR_POD_LABELS

          value: "role=mongo, environment=test"

        - name: KUBERNETES_MONGO_SERVICE_NAME

          value: "mongo"

  volumeClaimTemplates: 

  - metadata: 

      name: mongo-persistent-storage

      annotations: 

        volume.beta.kubernetes.io/storage-class: "tony-fast"

    spec: 

      accessModes: 

      - "ReadWriteOnce"

      resources: 

        requests: 

          storage: 100M

```







#### PVC （persistentvolumeclaims） yaml 编写规则



```yaml

apiVersion  <string>    #resource所处版本

kind        <string>    #resource类型

metadata  <Object>          #resource的元数据信息

  name         <string>     #resource deployment名称

  labels       <map[string]string>      #resource 标签用于被selector匹配

  namespace    <string>                 #resource 所处的命名空间

  finalizers   <[]string>               #resource 保护模式

  ownerReferences      <[]Object>       #resource 的上层依赖

spec  <Object>  #resource的预期状态

		# ReadWriteOnce: RWO  单节点挂载，具备读写权限

        # ReadOnlyMany: ROX   多节点挂载，具备只读权限 

        # ReadWriteMany: RWX  多节点挂载，具备读写权限

  accessModes  <[]string>           # 指定此pvc存储卷应具有的所需访问模式

  resources    <Object>             # 表示此pvc存储卷应具有的最小资源

  	requests     <map[string]string>

  	limits       <map[string]string>

  selector     <Object>             # 标签选择器, 用来匹配挂载其对应pod的标签

  	matchLabels  <map[string]string> 

  	matchExpressions     <[]Object>

  storageClassName     <string>     # 声明所需的StorageClass的名称

  volumeMode   <string>             # 指明storageClass的存储卷类型

  volumeName   <string>             # 指明关联引用PV的name名字

```



#### PVC （persistentvolumeclaims） yaml 编写模板



```yaml

apiVersion: v1

kind: PersistentVolumeClaim

metadata: 

  name: tony-local-pvc

  namespace: tony

spec: 

  accessModes: 

  - ReadWriteMany

  resources: 

    requests: 

      storage: 50M

  selector: 

    matchLabels: 

      release: "stable"

  storageClassName: tony-local-storage 

  volumeName: tony-local-pv

  volumeMode: Filesystem

```







#### PV  (persistentvolumes） yaml   编写规则



```yaml

apiVersion  <string>    #resource所处版本

kind        <string>    #resource类型

metadata  <Object>          #resource的元数据信息

  name         <string>     #resource deployment名称

  labels       <map[string]string>      #resource 标签用于被selector匹配

  namespace    <string>                 #resource 所处的命名空间

  finalizers   <[]string>               #resource 保护模式

  ownerReferences      <[]Object>       #resource 的上层依赖

spec  <Object>  #resource的预期状态

	    # ReadWriteOnce: RWO  单节点挂载，具备读写权限

        # ReadOnlyMany: ROX   多节点挂载，具备只读权限 

        # ReadWriteMany: RWX  多节点挂载，具备读写权限

  accessModes  <[]string>           # 指定此pvc存储卷应具有的所需访问模式

  capacity     <map[string]string>  # pv持久卷申请的资源总量

  nfs  <Object>                     # 表示主机上的NFS网络文件系统

    path <string> -required-

    server       <string> -required-

    readOnly     <boolean>

  cephfs       <Object>             # 表示共享Pod生命周期的主机上的Ceph FS挂载

    monitors     <[]string> -required-

    path <string>

    readOnly     <boolean>

  glusterfs    <Object>             # 表示连接到主机的Glusterfs卷

    endpoints    <string> -required-

    path <string> -required-

    readOnly     <boolean>

    endpointsNamespace   <string>

  hostPath     <Object>             # 表示使用主机上的目录

    path <string> -required-

    type <string>

  storageClassName     <string>     # 声明所需的StorageClass的名称

  volumeMode   <string>             # 指明storageClass的存储卷类型

```



#### PV  (persistentvolumes） yaml   编写模板



```yaml

apiVersion: v1

kind: PersistentVolume

metadata: 

  name: tony-local-pv

  namespace: tony

spec: 

  accessModes: 

  - ReadWriteMany

  capacity: 

    storage: 50M

  local:

    path: /data/storage/mem_space

  storageClassName: tony-local-storage

  volumeMode: Filesystem

  persistentVolumeReclaimPolicy: Delete

  nodeAffinity:

    required:

      nodeSelectorTerms:

      - matchExpressions:

        - key: kubernetes.io/hostname 

          operator: In

          values:

          - 192.168.255.121

```







#### storageclasses   yaml   编写模板



```yaml

apiVersion: storage.k8s.io/v1

kind: StorageClass

metadata:

  name: tony-local-storage

provisioner: kubernetes.io/no-provisioner

volumeBindingMode: WaitForFirstConsumer

```







#### pod 运用pv  pvc   storageclasses示例  



```yaml

[root@tony_tce:~/tony_data/k8s_manifests/pv_pvc_storage]cat nginx_pvc.yaml  

apiVersion: v1

kind: Pod

metadata: 

  name: nginx

  labels: 

    app: nginx

  namespace: tony

spec: 

  containers:

  - name: nginx

    image: nginx:alpine

    imagePullPolicy: IfNotPresent 

    ports: 

    - containerPort: 80

      hostPort: 80

      protocol: TCP

    volumeMounts: 

    - name: nginx-storage

      mountPath: /data/storage/log

  hostNetwork: true

  volumes: 

  - persistentVolumeClaim: 

      claimName: tony-local-pvc

    name: nginx-storage

```







