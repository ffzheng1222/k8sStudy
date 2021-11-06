# k8s go-template使用方法







### 基本语法



```shell

# go-template语法整体风格类似handlebars模板引擎语法,通过 {{}} 来访问变量



模板: kubectl get po -o go-template=xxx

```







#### 变量



```shell

# 1. 通过引用变量名称来访问该变量

{{ foo }}



# 2. 变量也同样可以被定义和引用

{{ $address := "123 Main St." }}

{{ $address }}

```







#### 函数



```shell

# 1. go template支持非常多的函数,这里不再详细介绍,

仅介绍与获取kubernetes资源对象相关的range就像Go一样，Go模板中大量的使用了range来遍历map，array或者slice





# 示例1 通过使用上下文

{{ range array }}

    {{ . }}

{{ end }}



# 示例2 通过声明value变量的名称

{{ range $element := array }}

    {{ $element }}

{{ end }}



#示例3 通过同时声明key和value变量名称

{{ range $index, $element := array }}

    {{ $index }}

    {{ $element }}

{{ end }

```







#### 实用场景



```shell

# 解析secret所有非空的加密字段

-o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}} {{end}}{{"\n"}}{{end}}'



# 获取pod所有的容器image镜像

-o go-template='{{ range .spec.containers }}{{.image}}{{"\n"}}{{end}}'



# 获取pod所有的 volumes

-o go-template='{{range .spec.volumes}}{{if .hostPath}}{{"host volumes Name: "}}{{.name}}{{"\n"}}{{"host volumes path: "}}{{.hostPath.path}}{{"\n"}}{{end}}{{end}}'





#  获取pod所有的 volumeMounts

-o go-template='{{range .spec.containers}}{{"Container Name: "}}{{.name}}{{"\n"}}{{range .volumeMounts}}{{"volumeMounts Name: "}}{{.name}}{{"\n"}}{{"volumeMounts path: "}}{{.mountPath}}{{"\n"}}{{end}}{{end}}'





# 获取pod上次终止时容器的状态

-o go-template='{{range.status.containerStatuses}}{{"Container Name: "}}{{.name}}{{"\r\nLastState: "}}{{.lastState}}{{end}}'

```







