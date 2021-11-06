# k8s ingress的理解







#### ks8 Ingress Controller 工作原理



```

k8s  ingress 主要工作组件： ingress Controller, ingress, service



ingress Controller：

	主要负责干活处理ingress流量动态转发功能

	通过ingress 资源动态注入upstream转发配置信息到ingress Controller pod容器内部承载流量转发工作的nginx配置文件中，

	并触发nginx重读配置文件, 实现动态更新upstream



ingress：

	ingress通过定义backend为后端Service，从而与后端的Service取得联系，并获取Service的Endpoints列表，

	从而得到它所监控的Pod列表



service：Service：

	负责实时监控Pod的变化，并反应在自己的Endpoints中，同时作为ingress的backend为后端转发服务

```



![image-20210124204336790](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124204336790.png)



