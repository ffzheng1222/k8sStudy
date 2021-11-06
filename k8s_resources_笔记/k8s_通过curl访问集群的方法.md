# k8s通过curl访问集群的方法



```

#### 使用kube proxy代理apiserver  http: 8080端口访问



kubectl  proxy  --port  8080 &

```







curl   localhost:8080/api



```

[root@tony_tce:~]curl localhost:8080/api      

{

  "kind": "APIVersions",

  "versions": [

    "v1"

  ],

  "serverAddressByClientCIDRs": [

    {

      "clientCIDR": "0.0.0.0/0",

      "serverAddress": "192.168.255.10:6443"

    }

  ]

}

```



####   # 返回namespaces命名空间列表



curl   localhost:8080/api/v1/namespaces



####  # 返回pod列表



curl   localhost:8080/api/v1/pods



#### # 返回service列表		



curl   localhost:8080/api/v1/services



#### # 返回RC列表		



curl   localhost:8080/api/v1/replicationcontrollers



#### # 返回configmap列表



curl   localhost:8080/api/v1/configmaps



#### # 返回secret列表



curl   localhost:8080/api/v1/secrets



####  # 返回endpoints列表



curl   localhost:8080/api/v1/endpoints







#### # 指定访问某个pod



curl   localhost:8080/api/v1/namespaces/kube-system/pods/etcd-192.168.255.10







## 当前v1版本内部所有包含的resources 资源



```

[root@tony_tce:~]curl   localhost:8080/api/v1/  |grep   -w '"name": '  

      "name": "bindings",

      "name": "componentstatuses",

      "name": "configmaps",

      "name": "endpoints",

      "name": "events",

      "name": "limitranges",

      "name": "namespaces",

      "name": "namespaces/finalize",

      "name": "namespaces/status",

      "name": "nodes",

      "name": "nodes/proxy",

      "name": "nodes/status",

      "name": "persistentvolumeclaims",

      "name": "persistentvolumeclaims/status",

      "name": "persistentvolumes",

      "name": "persistentvolumes/status",

      "name": "pods",

      "name": "pods/attach",

      "name": "pods/binding",

      "name": "pods/eviction",

      "name": "pods/exec",

      "name": "pods/log",

      "name": "pods/portforward",

      "name": "pods/proxy",

      "name": "pods/status",

      "name": "podtemplates",

      "name": "replicationcontrollers",

      "name": "replicationcontrollers/scale",

      "name": "replicationcontrollers/status",

      "name": "resourcequotas",

      "name": "resourcequotas/status",

      "name": "secrets",

      "name": "serviceaccounts",

      "name": "serviceaccounts/token",

      "name": "services",

      "name": "services/proxy",

      "name": "services/status",





```







