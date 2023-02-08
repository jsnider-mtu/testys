#!/bin/bash

while [[ $# -gt 0 ]]; do
  case $1 in
    --east-values-file)
      export EASTVALFILE="$2"
      shift
      shift
      ;;
    --west-values-file)
      export WESTVALFILE="$2"
      shift
      shift
      ;;
    --helm-options)
      export HELMOPT="$2"
      shift
      shift
      ;;
    --aws-key)
      export AWS_ACCESS_KEY="$2"
      shift
      shift
      ;;
    --aws-secret)
      export AWS_SECRET_KEY="$2"
      shift
      shift
      ;;
    --release-name)
      export RELEASENAME="$2"
      shift
      shift
      ;;
    --namespace)
      export NAMESPACE="$2"
      shift
      shift
      ;;
    --chart-path)
      export CHARTPATH="$2"
      shift
      shift
      ;;
    --update-east-tag)
      export UPDATE_EAST_TAG="$2"
      shift
      shift
      ;;
    --update-west-tag)
      export UPDATE_WEST_TAG="$2"
      shift
      shift
      ;;
    --east-region)
      export EAST_REGION="$2"
      shift
      shift
      ;;
    --west-region)
      export WEST_REGION="$2"
      shift
      shift
      ;;
    *)
      echo "$1 is an unexpected argument"
      shift
      ;;
  esac
done

export TAG="$(yq e '.version' $CHARTPATH/Chart.yaml)"
if [[ ! -z $TAG ]]; then
  echo "Chart version $TAG found in Chart.yaml"
else
  echo "Chart version not found; exiting"
  exit 1
fi

echo -e "\nSetting up AWS keys"
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"

if [[ $UPDATE_EAST_TAG == "true" ]]; then
  echo -e "\nSetting image tag in east values file"
  sed -i'' "s/tag: 0\.0\.1$/tag: ${TAG}/" $EASTVALFILE
fi

if [[ $UPDATE_WEST_TAG == "true" ]]; then
  echo -e "\nSetting image tag in west values file"
  sed -i'' "s/tag: 0\.0\.1$/tag: ${TAG}/" $WESTVALFILE
fi

echo -e "\nAdding repos for dependency charts"
yq --indent 0 e '.dependencies | map(["helm", "repo", "add", .name, .repository] | join(" ")) | .[]' "$CHARTPATH/Chart.yaml" | sh --;

echo -e "\nPulling dependency charts"
helm dependency build $CHARTPATH

if [[ $EAST_REGION == "true" ]]; then
  echo -e "\nGrabbing the us-east-1 kubeconfig file"
  if [[ $TEAM == "SRE" ]]; then
    mkdir -p $HOME/.kube && aws secretsmanager --region us-east-1 get-secret-value --secret-id teleport-kubeconfig-sre --query 'SecretString' | tr -d '"'',''['']' | base64 -d > $HOME/.kube/config && chmod 700 $HOME/.kube/config
  else
    mkdir -p $HOME/.kube && aws secretsmanager --region us-east-1 get-secret-value --secret-id teleport-kubeconfig --query 'SecretString' | tr -d '"'',''['']' | base64 -d > $HOME/.kube/config && chmod 700 $HOME/.kube/config
  fi
  echo -e "\nHelm diff us-east-1"
  helm diff upgrade --install $RELEASENAME $CHARTPATH -f $EASTVALFILE $HELMOPT -n $NAMESPACE
fi

if [[ $WEST_REGION == "true" ]]; then
  echo -e "\nGrabbing the us-west-2 kubeconfig file"
  if [[ $TEAM == "SRE" ]]; then
    mkdir -p $HOME/.kube && aws secretsmanager --region us-west-2 get-secret-value --secret-id teleport-kubeconfig-sre --query 'SecretString' | tr -d '"'',''['']' | base64 -d > $HOME/.kube/config && chmod 700 $HOME/.kube/config
  else
    mkdir -p $HOME/.kube && aws secretsmanager --region us-west-2 get-secret-value --secret-id teleport-kubeconfig --query 'SecretString' | tr -d '"'',''['']' | base64 -d > $HOME/.kube/config && chmod 700 $HOME/.kube/config
  fi
  echo -e "\nHelm diff us-west-2"
  helm diff upgrade --install $RELEASENAME $CHARTPATH -f $WESTVALFILE $HELMOPT -n $NAMESPACE
fi
