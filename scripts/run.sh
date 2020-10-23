#!/bin/bash

source ./utils.sh

usage () {
  echo "Usage:"
  echo "run.sh API_KEY CLUSTER_NAME"
}

# Checks status of Subscription given as first parameter
# Returns 0 if Subscription's CSV is created else returns 1
checkCSV() {
   local -r status=$(oc get csv $1 -o=jsonpath="{.status.phase}")
   if [[ $? -eq 0 ]]; then
     if [ "$status" = "Succeeded" ]; then
        echo "CSV $1 is up"
        return 0
     else
        echo "CSV $1 is not ready"
        return 1
     fi
   else
     echo "Command to get  CSV $1 status failed"
     return 1
   fi

}

# Per OpenShift 4.5 docs, the Knative serving CRD status can be queried via the following command:
# oc get knativeserving.operator.knative.dev/knative-serving -n knative-serving --template='{{range .status.conditions}}{{printf "%s=%s\n" .type .status}}{{end}}'
#
# If the  CRD is ready the output looks like this:
#   DependenciesInstalled=True
#   DeploymentsAvailable=True
#   InstallSucceeded=True
#   Ready=True
#   VersionMigrationEligible=True
#
# This function issues the CRD status command and looks for output with 5 separate lines each ending with "=True"
# It returns 0 if it finds these 5 lines or 1 otherwise (output doesn't match or status command fails)
checkCRD() {
   local -i -r expected_complete=5
   local -i actual_complete=0
   local -r status=$(oc get knativeserving.operator.knative.dev/knative-serving -n knative-serving --template='{{range .status.conditions}}{{printf "%s=%s\n" .type .status}}{{end}}')
   if [[ $? -eq 0 ]]; then
     while IFS= read -r line
     do
       if [[ "$line" == *=True ]]; then
          let "actual_complete+=1"
       fi
     done <<< "$status"
   fi
   if [ "$actual_complete" -eq "$expected_complete" ]; then
     echo "CRD is ready  $actual_complete"
     return 0
   else
     echo "CRD is not ready $actual_complete"
     return 1
   fi
}

if [ "$#" -ne 2 ]
then
    usage
    exit 1
fi

ibmcloud login --apikey $1 -r us-south
if [[ $? -ne 0 ]]; then
   echo "Fatal error: login via ibmcloud cli"
   exit 1
fi

sleep 2

ibmcloud oc cluster config  --cluster $2
if [[ $? -ne 0 ]]; then
   echo "Fatal error: cannot setup cluster access via ibmcloud cli config command"
   exit 1
fi

MASTER_URL=`ibmcloud oc cluster get  --cluster $2 | grep "Master URL:" | awk '{print $3}'`

if [[ $? -ne 0 ]]; then
   echo "Fatal error: cannot get OpenShift Master API endpoint via ibmcloud cli"
   exit 1
fi

oc login -u apikey -p $1 $MASTER_URL
if [[ $? -ne 0 ]]; then
   echo "Fatal error: cannot login in to cluster via oc cli"
   exit 1
fi

CREATE_PROJECT_MSG=`oc create namespace knative-serving 2>&1`
if [[ $? -ne 0 ]]; then
   echo $CREATE_PROJECT_MSG | grep "(AlreadyExists)" > /dev/null
   if [[ $? -ne 0 ]]; then
      echo "Fatal error: creating knative-serving namespace"
      echo $CREATE_PROJECT_MSG
      exit 1
   else
      echo "Warning: knative-serving namespace already exists"
   fi
fi


echo "Creating subscription to serverless operator ..."
cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serverless-operator
  namespace: openshift-operators
spec:
  channel: '4.5'
  installPlanApproval: Automatic
  name: serverless-operator
  source:  redhat-operators
  sourceNamespace: openshift-marketplace
EOF

if [[ $? -ne 0 ]]; then
   echo "Fatal error: cannot create Subscription to serverless-operator"
   exit 1
fi

sleep 5

# Get the CSV from the Subscription details
csv=`oc get Subscription serverless-operator -o=jsonpath='{.status.currentCSV}' -n openshift-operators`

# Check every 20 sec for 3 min to see if CSV is successful
retry 9 checkCSV $csv
if [ $? -ne 0 ]; then
    echo "Error: timed out waiting for Subscription"
    exit 1
fi

echo "Creating Knative Serving CRD ..."
cat <<EOF | oc create -f -
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
    name: knative-serving
    namespace: knative-serving
EOF

# Check every 20 sec for 5 min to see if CRD was created  successfully
retry 15 checkCRD
if [ $? -ne 0 ]; then
    echo "Error: timed out waiting for Knative Serving CRD"
    exit 1
else
  echo "Knative Serving install completed successfully"
  exit 0
fi
