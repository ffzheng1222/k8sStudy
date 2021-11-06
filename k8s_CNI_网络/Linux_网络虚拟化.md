# Linux 网络虚拟化







### 网络虚拟化基石：







#### network namespace 概念描述



```wiki

network namespace：



Linux底层虚拟网络隔离技术的基本实现，作用是隔离Linux系统的网络设备，以及ip地址, 端口, 路由表, 防火墙规则等网络资源。

每一个网络的namespace都有自己的网络设备(如ip地址, 端口范围, 路由表, 防火墙规则,/proc/net目录等)。

```







#### network namespace 基本操作



```shell

===> network namespace的增删改查功能已经集成到了 Linux的 IP工具的netns子命令中



# 创建一个名为 netns_tony 的network namespace

ip netns add netns_tony



# 查看系统存在哪些 network namespace

ip netns list



# 删除指定的 network namespace

# 注意：此命令仅仅是移除了该network namespace对应的挂载点，只要里面还有进程在运行着，那么该network namespace便会一直存在

ip netns  delete   netns_tony   



# 使用 ip netns exec 命令进行网络查询/配置工作

ip netns  exec  netns_tony ip link list



# 进入 netns1 这个network namespace， ping 127.0.0.1

ip netns exec netns_tony  ping 127.0.0.1   #会返回：connect: Network is unreachable



# 配置netns1 这个network namespace，将lo设备状态设置为up

ip netns exec netns_tony  ip link set dev lo up

ip netns exec netns_tony  ping 127.0.0.1   #ping 正常

```







### veth pair



#### 虚拟设备对 veth pair



```basic

# 特别重要

在 veth pair 设备上，任意一端 (RX) 接收的数据都会在另一端 (TX) 发送出去，veth pair 在转发过程中不会修改数据包的内容

```



```shell

====> network namespace 配置虚拟对 veth pair



# 创建一对虚拟以太网卡 veth0/veth1 (默认创建在了 / network namespace)

ip link  add veth0 type veth peer name veth1



# 将一对虚拟以太网卡中一端移动到不同的network namespace

ip link  set veth1 netns netns_tony

# 将/ network namespace中的veth0 移动到 netns_tony network namespace

ip link  set veth0 netns netns_tony

# 将netns_tony network namespace中的veth0 移动到 / network namespace

ip  netns exec netns_tony  ip link set veth0  netns  1





# 给/ network namespace中的veth0绑定ip 并且 将状态设置为up

ifconfig  veth0 10.1.1.1/24 up

# 给netns_tony network namespace中的veth1绑定ip 并且 将状态设置为up

ip netns  exec netns_tony ifconfig veth1 10.1.1.2/24 up



# 查看/ network namespace中的veth0网络设备信息

ifconfig  veth0

# 查看netns_tony network namespace中的veth1网络设备信息

ip netns  exec netns_tony ifconfig veth1





# 通过虚拟设备对veth pair,从/ network namespace中的veth0 ping通到 netns_tony network namespace中的veth1

ping 10.1.1.2

# 通过虚拟设备对veth pair,从netns_tony network namespace中的veth1 ping通到 / network namespace中的veth0

ip netns  exec netns_tony ping 10.1.1.1



```



![net_ns虚拟设备对配置](https://github.com/ffzheng1222/k8sStudy/blob/master/png/image-20211106903132129.png)







#### 容器与host  veth pair的基础关系



```shell

###	方法1 ###

# 在目标容器内部查看

cat /sys/class/net/eth0/iflink

# 然后在容器所落的主机上遍历 /sys/class/net 下面的全部目录的ifindex的值 和 容器内部eth查出来的iflink 相同

for net_file in `ls /sys/class/net`; do echo "====> ${net_file}" && cat /sys/class/net/${net_file}/ifindex; done





###	方法2 ###

# 在目标容器内部执行下面命令

ip link show eth0

# 然后在容器所落的主机上执行，47 为目标容器内etho接口对应的index

ip link show | grep 47 -w





###	方法3 ###

# 在network namespace内执行 ethtool -S <veth 设备一端>

ip netns exec netns_tony ethtool  -S  veth1 |grep peer_ifindex

# 然后在 / network namespace 中执行下面命令，4为上一步的输出

ip addr |grep  '4:' -w

```







### Linux bridge



#### bridge 网桥基本概念



```shell

1. 网桥是二层网络设备，两个端口分别有一条独立的交换信道，不共享一条背板总线



2. Linux bridge 的行为像是一台虚拟的网络交换机，任意的真是物理设备(例如eth0) 和 虚拟设备 (例如 veth pair & tap设备) 都可以连接到 Linux bridge上



3. 普通的网络设备只有两端，数据从一端进入，从另一端出去

   比如: 物理网卡从外面网络中收到的数据会转发给内核协议栈，而从内核协议栈过来的数据会转发到外面的物理网络中

  

4. Linux bridge 有多个端口，数据可以从任何端口进来，进来之后从哪个端口出去 (取决于目的MAC地址), 原理和物理交换机类似



5. Linux bridge 网桥不能跨主机连接网络设备

```











