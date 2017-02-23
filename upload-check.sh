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

# Generate timestamp so that this is unique.
TRANSACTION_ID=$(date +%s)

# Encode the deposit to account and amount in the image name for simplicity.
CHECK_IMAGE_ID="12345679^19.99^$TRANSACTION_ID.jpg"
CHECK_IMAGE_NAME="12345679^19.99^.jpg"

# Save the image as a document and attachment in Cloudant.
curl -H "Content-Type: image/jpg" -X PUT --data-binary @images/$CHECK_IMAGE_NAME -u $CLOUDANT_USERNAME:$CLOUDANT_PASSWORD "https://$CLOUDANT_USERNAME.cloudant.com/incoming-checks/$CHECK_IMAGE_ID/$CHECK_IMAGE_ID"
