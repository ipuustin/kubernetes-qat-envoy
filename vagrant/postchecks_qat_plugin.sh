#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2019 Intel Corporation
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o xtrace
set -o errexit

echo "QAT plugin validation"

echo "Ensuring that envoy-qat:devel docker image exists..."
if [[ -z $(sudo docker images | grep envoy-qat | grep devel) ]]; then
    echo "envoy-qat:devel docker image doesn't exists"
    exit 1
fi

echo "Verifying intel-qat2-plugin daemonset is available..."
plugin_daemonset=$( kubectl get daemonset | grep intel-qat2-plugin)
if [[ $plugin_daemonset ]]; then
   if [[ $(echo $plugin_daemonset | awk '{print $2}') != $(echo $plugin_daemonset | awk '{print $6}') ]]; then
      echo "Ther Intel QAT daemonset plugin is not available yet"
      exit 1
   fi
else
    echo "The Intel QAT daemonset plugin is not created"
    exit 1
fi

echo "Ensuring that the intel-qat2-plugin pod has registered the devices..."
for plugin_pod in $(kubectl get pods | grep intel-qat2 | awk '{print $1}'); do
     if [[ -z $(kubectl logs $plugin_pod | grep "Start server for") ]]; then
        echo "The Intel QAT daemonset has not started properly"
        exit 1
     fi
     if [[ -z $(kubectl logs $plugin_pod | grep "Device plugin for") ]]; then
        echo "The QAT devices weren't registered properly"
        exit 1
     fi
done

echo -e " \nPost-checks for qat plugin complete! "
