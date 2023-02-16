#!/bin/bash
#
#  Creates a new package in the dev hub.
#
#  Copyright (c) 2023, salesforce.com, inc.
#  All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause
#  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
#
#  Contact: john.meyer@salesforce.com

readonly devHubOrgAlias=$(jq --raw-output .defaultdevhubusername < .sfdx/sfdx-config.json) || {
    echo "Make sure that \"jq\" is installed and that \"defaultdevhubusername\" is defined in .sfdx/sfdx-config.json." >&2
    exit 1
}

sfdx package create \
    --package-type "Unlocked" \
    --no-namespace \
    --name "Lightning Enhanced Calendar" \
    --description "This package contains code and metadata for a Salesforce Lightning Web Component that displays, creates, updates, and deletes records of arbitrary object types in a calendar." \
    --path "force-app" \
    --target-hub-org "$devHubOrgAlias"