# k8s deployment 与 statefulset的区别







#### Deployment & StatefulSet  比较



![image-20210124211812766](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124211812766.png)







#### 访问方式



![image-20210124211206952](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124211206952.png)



![image-20210124211233020](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210124211233020.png)







#### 使用建议



```

1. 如果是不需额外数据依赖或者状态维护的部署，或者replicas是1，优先考虑使用Deployment



2. 如果单纯的要做数据持久化，防止pod宕掉重启数据丢失，那么使用pv/pvc就可以了



3. 如果要打通app之间的通信，而又不需要对外暴露，使用headlessService即可



4. 如果需要使用service的负载均衡，不要使用StatefulSet，尽量使用clusterIP类型，用serviceName做转发



5. 如果是有多replicas，且需要挂载多个pv且每个pv的数据是不同的，因为pod和pv之间是一一对应的，如果某个pod挂掉再重启，

   还需要连接之前的pv，不能连到别的pv上，考虑使用StatefulSet



6. 能不用StatefulSet，就不要用

```







