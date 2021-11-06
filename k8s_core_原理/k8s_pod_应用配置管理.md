# k8s pod 应用配置管理







### pod 配置管理



```

可变配置就用: ConfigMap

敏感信息是用: Secret

身份认证是用: ServiceAccount 这几个独立的资源来实现的

资源配置是用: Resources

安全管控是用: SecurityContext

前置校验是用: InitContainers 这几个在 spec 里面加的字段，来实现的这些配置管理

```



![image-20210219172117048](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219172117048.png)



### ConfigMap 资源



![image-20210219173319016](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219173319016.png)



![image-20210219172534500](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219172534500.png)







![image-20210219172554925](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219172554925.png)



![image-20210219172721373](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219172721373.png)



### Secret 资源



![image-20210219173516591](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219173516591.png)



![image-20210219173545970](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219173545970.png)



![image-20210219173621951](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219173621951.png)



![image-20210219175648582](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219175648582.png)



![image-20210219175702462](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219175702462.png)



### ServiceAccount 资源



![image-20210219175851660](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219175851660.png)



![image-20210219175917992](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219175917992.png)







### 容器资源配置管理



![image-20210219175956178](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219175956178.png)



### Pod Qos 质量管理资源



![image-20210219180009112](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219180009112.png)







### Sercurtity Context 安全管理资源



![image-20210219180032893](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219180032893.png)



### Init Container 资源



![image-20210219180113614](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210219180113614.png)



