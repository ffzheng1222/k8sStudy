#!/bin/bash
set -euE -o functrace 
set -o pipefail

error() { echo -e "\033[31mE\e[0m$(date --rfc-3339=s)\t${FUNCNAME[1]}:$2] exit code $1, cmd='$3'"; }
trap 'error $? ${LINENO} "$(eval echo ${BASH_COMMAND})"' ERR

rootDIR=${rootDIR:="/root/wyc"}
cleanv1() {
    kubectl -n tcs-system scale deploy tce-cloud-provider --replicas=1
    kubectl -n ssm scale deploy mongo-operator --replicas=0
    kubectl -n service-operators scale deploy mongo-mongo-operator --replicas=1

    [[ "$(kubectl -n service-brokers get mongo oam-mongodb-wyc -ojson | jq -r .metadata.labels)" != "null" ]] && 
    kubectl -n service-brokers patch mongo oam-mongodb-wyc --type='json' -p='[{"op":"remove", "path":"/metadata/labels"}]'
    kubectl -n tce delete servicebindings.servicecatalog.k8s.io mongodb-ops-cmdb-wyc || echo 
    kubectl -n tce delete serviceinstances.servicecatalog.k8s.io oam-mongodb-wyc || echo 
}

cleanv2() {
    kubectl -n tcs-system scale deploy tce-cloud-provider --replicas=1
    kubectl -n ssm scale deploy mongo-operator --replicas=1
    kubectl -n service-operators scale deploy mongo-mongo-operator --replicas=0

    [[ "$(kubectl -n sso get mongo tce-mongodb-wyc -ojson | jq -r .metadata.labels)" != "null" ]] && 
    kubectl -n sso patch mongo tce-mongodb-wyc --type='json' -p='[{"op":"remove", "path":"/metadata/labels"}]' || echo 
    kubectl -n sso patch mongo tce-mongodb-wyc --type='json' -p='[{"op":"remove", "path":"/metadata/finalizers"}]' || echo 
    kubectl -n sso delete mongo tce-mongodb-wyc || echo 
}

upv1() {
    kubectl -n tcs-system scale deploy tce-cloud-provider --replicas=1
    kubectl -n ssm scale deploy mongo-operator --replicas=0
    kubectl -n service-operators scale deploy mongo-mongo-operator --replicas=1

    kubectl apply -f /root/wyc/mongo/oam-mongodb-base.si.yml
    while true; do kubectl -n service-brokers get mongo oam-mongodb-wyc && kubectl apply -f /root/wyc/mongo/oam-mongodb-wyc.yml && break || sleep 5; done
    cmd='status=$(kubectl -n service-brokers get mongo oam-mongodb-wyc -ojson | jq -r .status.phase )'
    while true; do eval $cmd && [[ "${status}" == "Ready" ]] && break || (echo "cr ${status} != Ready" && sleep 5); done
    cmd='status=$(kubectl -n tce get serviceinstances.servicecatalog.k8s.io oam-mongodb-wyc -ojson | jq -r .status.lastConditionState)'
    while true; do eval $cmd && [[ "${status}" == "Ready" ]] && break || (echo "si ${status} != Ready" && sleep 5); done
    kubectl apply -f /root/wyc/mongo/mongodb-ops-cmdb.sb.yml
    cmd='status=$(kubectl -n tce get servicebindings.servicecatalog.k8s.io mongodb-ops-cmdb-wyc -ojson | jq -r .status.lastConditionState)'
    while true; do eval $cmd && [[ "${status}" == "Ready" ]] && break || (echo "sb ${status} != Ready" && sleep 5); done

}

checkv1() {
    while true; do (kubectl -n service-brokers get pod,pvc,sts,ss,mongo,svc | grep wyc) && sleep 5 && continue || echo "v1 cleaned" && break; done
}

checkv2() {
    while true; do (kubectl -n sso             get pod,pvc,sts,ss,mongo,svc | grep wyc) && sleep 5 && continue || echo "v2 cleaned" && break; done
}

checkv1user() {
    echo use cmdb
    echo show users
    kubectl -n service-brokers exec -ti service/mongos-oammongodbwyc -- mongo --port 27017 -u 4omt2 -p dehnm056 --authenticationDatabase admin
}

checkv2user() {
    echo use cmdb
    echo show users
    kubectl -n sso    exec -ti service/mongos-tcemongodbwyc -c mongo -- mongo --port 27017 -u 4omt2 -p dehnm056 --authenticationDatabase admin
}

upgrade() {
    kubectl get ss web -ojson | jq  ' .metadata.labels += {"infra.tce.io/cr-freeze": "true"} ' | kubectl replace -f -
    kubectl -n ssm scale deploy mongo-operator --replicas=1
    /root/wyc/ssmctl upgrade -c mongo -y /data/upgrade/ssm -p wyc
}

declare -F
printf "
a.sh checkv1     检查 TCE360/TCS1.0 mongo 实例状态
a.sh checkv1user 检查 TCE360/TCS1.0 mongo 实例用户
a.sh checkv2     检查 TCE380/TCS2.0 mongo 实例状态
a.sh checkv2user 检查 TCE380/TCS2.0 mongo 实例用户
a.sh cleanv1     清理 TCE360/TCS1.0 mongo 实例
a.sh cleanv2     清理 TCE380/TCS2.0 mongo 实例
a.sh upgrade     升级 TCE360/TCS1.0 mongo 实例到 TCE380/TCS2.0
a.sh upv1        拉起 TCE360/TCS1.0 mongo 实例
"
for i in $@
do
    echo $i && eval $i
done

# /root/wyc/ssmctl upgrade -c mongo -y /data/upgrade/ssm -p wyc