#!/bin/bash
#
# Copyright 2016 IBM Corp. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the “License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Load configuration variables
source local.env

# Capture the namespace where actions will be created
WSK='wsk' # Set if not in your $PATH
CURRENT_NAMESPACE=`$WSK property get --namespace | sed -n -e 's/^whisk namespace//p' | tr -d '\t '`
echo "Current namespace is $CURRENT_NAMESPACE."

function install() {
  echo "Binding package"
  $WSK package bind /whisk.system/cloudant "$CLOUDANT_INSTANCE" \
    --param username "$CLOUDANT_USERNAME" \
    --param password "$CLOUDANT_PASSWORD" \
    --param host "$CLOUDANT_USERNAME.cloudant.com"

  echo "Creating triggers"
  $WSK trigger create new-check-deposit \
    --param dbname "incoming-checks" \
    --feed "$CLOUDANT_INSTANCE/changes"

  echo "Creating actions"
  $WSK action create process-check actions/process-check.js \
    --param CLOUDANT_USERNAME "$CLOUDANT_USERNAME" \
    --param CLOUDANT_PASSWORD "$CLOUDANT_PASSWORD" \
    --param CURRENT_NAMESPACE "$CURRENT_NAMESPACE"

  $WSK action create cloudant-sequence \
    --sequence /$CURRENT_NAMESPACE/$CLOUDANT_INSTANCE/read,process-check

  docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD"
  sh -c "cd dockerSkeleton && ./buildAndPush.sh $DOCKER_USERNAME/parse-image"
  $WSK action create --docker parse-image $DOCKER_USERNAME/parse-image

  echo "Enabling rule"
  $WSK rule create deposit-check new-check-deposit cloudant-sequence
}

function uninstall() {
  $WSK rule disable deposit-check
  $WSK rule delete deposit-check
  $WSK trigger delete new-check-deposit
  $WSK action delete process-check
  $WSK action delete parse-image
  $WSK action delete cloudant-sequence
  $WSK package delete "$CLOUDANT_INSTANCE"
}

function showenv() {
  echo CLOUDANT_INSTANCE=$CLOUDANT_INSTANCE
  echo CLOUDANT_USERNAME=$CLOUDANT_USERNAME
  echo CLOUDANT_PASSWORD=$CLOUDANT_PASSWORD
  echo DOCKER_USERNAME=$DOCKER_USERNAME
  echo DOCKER_PASSWORD=$DOCKER_PASSWORD
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--env" )
showenv
;;
* )
usage
;;
esac
