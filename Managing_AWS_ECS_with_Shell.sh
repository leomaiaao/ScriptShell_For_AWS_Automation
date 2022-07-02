#!/bin/bash
#VALIDATE INPUTS
#THIS SCRIPT IS CAPABLE OF STARTING OR STOP THE AMOUNT O TASKS NEEDED
if [ $# -ne 1 ];then
  echo "USE $0 CLUSTER_NAME" && exit 1;
fi
#DECLARE VARIABLES
CLUSTER_NAME=$1
DESIRED_COUNT=0;
CLUSTER_ARN=`aws ecs describe-clusters --clusters $CLUSTER_NAME  | jq '.clusters[].clusterArn' -r`
#VALIDATE IF CLUSTER EXISTS
if [ -z $CLUSTER_ARN ];then
  echo "CLUSTER NOT FOUND IN CURRENT AWS CONFIGURE" && exit 1;
fi
#INICIALIZE OR STOP TASKS
echo "DO YOU WANT TO START OR STOP SERVICES? (ONLY START AND STOP WILL BE ACCEPTED)";
read SERVICE_STATUS;
if [ "$SERVICE_STATUS" == "START" ];then
echo "DO YOU WANT TO START ALL SERVICES? YES or NO";
    read SERVICE_STATUS;
    if [ "$SERVICE_STATUS" == "YES" ];then
          SERVICEARNSARRAY=(`aws ecs list-services --cluster $CLUSTER_NAME | jq '.serviceArns[]' -r | cut -d '/' -f 3`)
            echo "STARTING all ${#SERVICEARNSARRAY[@]} services from cluster $CLUSTER_NAME";
            DESIRED_COUNT=1;
            for SERVICE in ${SERVICEARNSARRAY[@]}
              do
              echo "$SERVICE STARTED";
              aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE --desired-count $DESIRED_COUNT --force-new-deployment >> output.txt 
              done
    elif [ "$SERVICE_STATUS" == "NO" ]; then
        echo "WRITE THE NAME(S) OF THE SERVICE(S) TO BE STARTED SEPARATED BY SPACE";
        read SERVICES;
        DESIRED_COUNT=1;
        for SERVICE in $SERVICES
        do
        echo "--------------------------------------------"
        echo "     $SERVICE"
        echo "     The current desired count is: $(aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE | jq '.service.desiredCount' -r)"
        echo "     The current running count is: $(aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE | jq '.service.runningCount' -r)"
        aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE --desired-count $DESIRED_COUNT --force-new-deployment >> output.txt
        echo "     The desired count will be: 1"
        echo "--------------------------------------------"
        done
    fi
elif [ "$SERVICE_STATUS" == "STOP" ]; then
    echo "DO YOU WANT TO STOP ALL SERVICES? YES or NO";
    read SERVICE_STATUS;
    if [ "$SERVICE_STATUS" == "YES" ];then
          SERVICEARNSARRAY=(`aws ecs list-services --cluster $CLUSTER_NAME | jq '.serviceArns[]' -r | cut -d '/' -f 3`)
            echo "Stopping all ${#SERVICEARNSARRAY[@]} services from cluster $CLUSTER_NAME";
            for SERVICE in ${SERVICEARNSARRAY[@]}
              do
              echo "$SERVICE STOPPED";
              aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE --desired-count $DESIRED_COUNT --force-new-deployment >> output.txt 
              done
    elif [ "$SERVICE_STATUS" == "NO" ]; then
        echo "WRITE THE NAME(S) OF THE SERVICE(S) TO BE STOPPED SEPARATED BY SPACE";
        read SERVICES;
        for SERVICE in $SERVICES
        do
        echo "--------------------------------------------"
        echo "     $SERVICE"
        echo "     The current desired count was: $(aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE | jq '.service.desiredCount' -r)"
        echo "     The current running count is: $(aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE | jq '.service.runningCount' -r)"
        aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE --desired-count $DESIRED_COUNT --force-new-deployment >> output.txt
        echo "     The desired count will be 0"
        echo "--------------------------------------------"
        done
    fi
fi