# k8s jsonpth 使用方法







### 参考jsonpath例子



```shell

{

  "kind": "List",

  "items":[

    {

      "kind":"None",

      "metadata":{"name":"127.0.0.1"},

      "status":{

        "capacity":{"cpu":"4"},

        "addresses":[{"type": "LegacyHostIP", "address":"127.0.0.1"}]

      }

    },

    {

      "kind":"None",

      "metadata":{"name":"127.0.0.2"},

      "status":{

        "capacity":{"cpu":"8"},

        "addresses":[

          {"type": "LegacyHostIP", "address":"127.0.0.2"},

          {"type": "another", "address":"127.0.0.3"}

        ]

      }

    }

  ],

  "users":[

    {

      "name": "myself",

      "user": {}

    },

    {

      "name": "e2e",

      "user": {"username": "admin", "password": "secret"}

    }

  ]

}

```



| Function          | Description               | Example                                                      | Result                                          |

| ----------------- | ------------------------- | ------------------------------------------------------------ | ----------------------------------------------- |

| text              | the plain text            | kind is {.kind}                                              | kind is List                                    |

| @                 | the current object        | {@}                                                          | the same as input                               |

| . or []           | child operator            | {.kind} or {[‘kind’]}                                        | List                                            |

| ..                | recursive descent         | {..name}                                                     | 127.0.0.1 127.0.0.2 myself e2e                  |

| *                 | wildcard. Get all objects | {.items[*].metadata.name}                                    | [127.0.0.1 127.0.0.2]                           |

| [start:end :step] | subscript operator        | {.users[0].name}                                             | myself                                          |

| [,]               | union operator            | {.items[*][‘metadata.name’, ‘status.capacity’]}              | 127.0.0.1 127.0.0.2 map[cpu:4] map[cpu:8]       |

| ?()               | filter                    | {.users[?(@.name==“e2e”)].user.password}                     | secret                                          |

| range, end        | iterate list              | {range .items[*]}[{.metadata.name}, {.status.capacity}] {end} | [127.0.0.1, map[cpu:4]] [127.0.0.2, map[cpu:8]] |

| “                 | quote interpreted string  | {range .items[*]}{.metadata.name}{’\t’}{end}                 | 127.0.0.1 127.0.0.2                             |











#### 实用场景



```shell

kubectl get pods -o json

kubectl get pods -o=jsonpath='{@}'

kubectl get pods -o=jsonpath='{.items[0]}'

kubectl get pods -o=jsonpath='{.items[0].metadata.name}'

kubectl get pods -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.startTime}{"\n"}{end}'

```







