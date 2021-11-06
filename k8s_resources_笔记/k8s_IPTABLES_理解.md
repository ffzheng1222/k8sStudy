# k8s IPTABLES 理解







### iptables 规则理解







#### iptables 之 四表五链



```

iptable 四表:	(具有相同功能的规则的集合叫做 "表" )

	filter表: 

		负责过滤功能,防火墙; 内核模块:iptables_filter



	nat表: 

		network address translation 网络地址转换功能; 内核模块:iptable_nat



	mangle表: 

		负责拆解报文,做出修改,并重新封装 的功能, 主要实现数据包的拆分-修改-封装动作; 内核模块:iptable_mangle



	raw表: 

		通过关闭nat表的追踪功能,从而实现加速防火墙过滤的表; 内核模块:iptable_raw

		连接追踪: 就是记录用户的操作,下次再来加速访问,体验好。但是大用量的情况下,花费大量资源来记录历史记录,

		    	导致其他用户在等待,导致防火墙的性能非常差



========================================================================================================

iptables五链: (多条规则串到一个链条上的时候、就形成了 "链" )

	PREROUTING:

		数据包进行路由决策前应用的规则,一般用于改变数据包的目标地址,不让别人知道我找的是谁(对进入的数据包进行预处理)



	INPUT: 

		数据包经由路由决策后,进入到本机处理时应用的规则,一般用于本机进程处理的数据包(数据包本机处理)



	FORWARD:

		数据包经由路由决策后,本机不做处理,仅仅是转发数据包时应用的规则(数据包本机转发)



	output:

		新建数据包经路由决策后,从本机输出时应用的规则,一般用于本机处理后的数据包(数据包本机发出)



	POSTROUTING:

		数据包从本机出去前,对数据包应用的规则,一般用于更改数据包的源地址信息,不让给别人知道我是谁(对输出的数据包进行预处理)



```



![image-20210127105414436](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210127105414436.png)



```

在下面常用场景中、报文的流向: 



到本机某进程的报文: PREROUTING --> INPUT



由本机转发的报文: PREROUTING --> FORWARD --> POSTROUTING



由本机的某进程发出报文(通常为响应报文): OUTPUT --> POSTROUTING

```







```

防火墙的作用就在于对经过的报文匹配 "规则" 、然后执行对应的 "动作"

每个经过这个 "链" 的报文、都要将这条 "链" 上的所有规则匹配一遍、如果有符合条件的规则、则执行规则对应的动作

```



![image-20210127105806215](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210127105806215.png)







#### iptable 之 表链关系



```

链的规则存放于哪些表中(从链到表的对应关系):

	PREROUTING 	的规则可以存在于: raw表、mangle表、nat表



	INPUT 	的规则可以存在于: mangle表、filter表、(centos7中还有nat表、centos6中没有)



	FORWARD 的规则可以存在于: mangle表、filter表



	OUTPUT 	的规则可以存在于: raw表mangle表、nat表、filter表



	POSTROUTING 的规则可以存在于: mangle表、nat表



======================================================================================================

表中的规则可以被哪些链使用(从表到链的对应关系): 

	raw     表中的规则可以被哪些链使用: PREROUTING、OUTPUT



	mangle  表中的规则可以被哪些链使用: PREROUTING、INPUT、FORWARD、OUTPUT、POSTROUTING



	nat     表中的规则可以被哪些链使用: PREROUTING、OUTPUT、POSTROUTING(centos7中还有INPUT、centos6中没有)



	filter  表中的规则可以被哪些链使用: INPUT、FORWARD、OUTPUT

	

```



![image-20210127114517321](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20210127114517321.png)



