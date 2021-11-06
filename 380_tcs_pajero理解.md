# tce  pajero 理解







#### pajero 查询所有服务注册信息



```

curl -X GET http://127.0.0.1:30150/api/v1alpha1/service/instances | python -m json.tool > /tmp/tony_pajero.txt

```







#### pajero 根据条件查询服



```

根据 域名Host 为条件过滤

curl -X GET http://127.0.0.1:30150/api/v1alpha1/service/instances?host=undefined.service.tcenter | python -m json.tool





根据 serviceID 为条件过滤

curl -X GET http://127.0.0.1:30150/api/v1alpha1/service/instances?serviceID=product-tsf-mock.oss-consul | python -m json.tool



```















