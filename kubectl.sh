#!/bin/bash

# qi ocloud-tcenter-mc-php
# di ocloud-tcenter-mc-php
# ei ocloud-tcenter-mc-php "cat /data/storage/supervisord.log"
# ei ocloud-tcenter-mc-php "grep {{ -R /tce/conf/config_template/"
# ei ocloud-tcenter-mc-php "grep {{ -R /tce/conf/config/"
# ei ocloud-tcenter-mc-php "sh /tce/healthchk.sh"
# ei ocloud-tcenter-mc-php "ps -ef"
# ei ocloud-tcenter-mc-php "netstat -nlp"
# ei ocloud-tcenter-mc-php "cat /tce/conf/config/tce.config.center/sdk.json"

template_image='
{{- .metadata.labels.app -}}
{{- range $index, $element := .spec.containers -}}
  {{print " "}} {{$index}} {{$element.image}}
{{ end }}'

function generate_query() {
    echo `echo $* | sed 's/\s/.*/g'`
}

# query_image_version print all match containers' image info
function query_image_version() {
    local query=`generate_query $*`
    for pod in `kubectl get pod -n tce -o wide | grep $query | awk '{print $1}'`
    do
        echo "kubectl get pod -n tce $pod --template='${template_image}'" | bash
    done
}

# restart_image restart all match containers
function restart_image() {
    local query=`generate_query $*`
    for pod in `kubectl get pod -n tce -o wide | grep $query | awk '{print $1}'`
    do
        echo "kubectl delete pod -n tce $pod " | bash
    done
}

# login_image login container if only one match, otherwise print all match containers
function login_image() {
    local query=`generate_query $*`
    local pods=`kubectl get pod -n tce -o wide | egrep $query | wc -l`
    if [ ${pods} -eq 1 ]; then
        local pod=`kubectl get pod -n tce -o wide | egrep $query | awk '{print $1}'`

        echo "login into ${pod}"
        kubectl -n tce exec -it ${pod} /bin/bash
    else
        kubectl get pod -n tce -o wide | egrep $query
    fi
}

# describe_image describe pod 
function describe_image() {
    local query=`generate_query $*`
    local pods=`kubectl get pod -n tce -o wide | egrep $query | wc -l`
    if [ ${pods} -eq 1 ]; then
        local pod=`kubectl get pod -n tce -o wide | egrep $query | awk '{print $1}'`
    else
        local pod=`kubectl get pod -n tce -o wide | egrep $query | head -n 1 | awk '{print $1}'`
    fi    
    echo "describe pod: ${pod}"
    kubectl describe pod ${pod} -n tce    
}

function exec_cmds() {
    local pods=`kubectl get pod -n tce -o wide | egrep $1 | wc -l`
    if [ ${pods} -eq 1 ]; then
        local pod=`kubectl get pod -n tce -o wide | egrep $1 | awk '{print $1}'`
    else
        local pod=`kubectl get pod -n tce -o wide | egrep $1 | head -n 1 | awk '{print $1}'`
    fi    
    echo "exec_cmds:${2} in pod:${pod}" 
    kubectl -n tce exec -it ${pod} -- bash -c "${2}"
}

alias li=login_image
alias qi=query_image_version
alias ri=restart_image
alias di=describe_image
alias ei=exec_cmds