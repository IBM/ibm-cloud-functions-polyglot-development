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

echo $1 > params.json

# Cloudant credentials and the _id of the attachment/document to download.
CLOUDANT_USERNAME=`cat params.json | jq -r '.CLOUDANT_USERNAME'`
CLOUDANT_PASSWORD=`cat params.json | jq -r '.CLOUDANT_PASSWORD'`
CLOUDANT_DATABASE=`cat params.json | jq -r '.CLOUDANT_DATABASE'`
IMAGE_ID=`cat params.json | jq -r '.IMAGE_ID'`

# Download the image from Cloudant.
curl -s -X GET -o imgData \
"https://$CLOUDANT_USERNAME:$CLOUDANT_PASSWORD@$CLOUDANT_USERNAME.cloudant.com/$CLOUDANT_DATABASE/$IMAGE_ID/$IMAGE_ID?attachments=true&include_docs=true"

# Extract the account number and routing number as text by parsing for MICR font values.
tesseract imgData imgData.txt -l mcr2 >/dev/null 2>&1

# This matcher works with two of the checks we're using as samples for the PoC.
declare -a values=($(grep -Eo "\[[[0-9]+" imgData.txt.txt | sed -e 's/\[//g'))

# Extract the two values.
ROUTING=${values[0]}
ACCOUNT=${values[1]}

# Return JSON formatted values.
echo "{ \"result\": {\"routing\": \"$ROUTING\", \"account\": \"$ACCOUNT\"} }"
