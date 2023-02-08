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
      export AWS_ACCESS_KEY_ID="$2"
      shift
      shift
      ;;
    --aws-secret)
      export AWS_SECRET_ACCESS_KEY="$2"
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

export TAG=$(yq e '.version' $CHARTPATH/Chart.yaml)
