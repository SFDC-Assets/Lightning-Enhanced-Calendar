#!/bin/bash
#
#  Deletes all scratch orgs.
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
readonly tmpFile="$devHubOrgAlias".csv

sfdx data query \
    --query "SELECT Id FROM ScratchOrgInfo" \
    --result-format csv \
    --target-org "$devHubOrgAlias" > "$tmpFile"
echo "*** Deleting all scratch orgs ..."
sfdx force data delete bulk --file "$tmpFile" --sobject ScratchOrgInfo --wait 10 --target-org "$devHubOrgAlias"
rm -f "$tmpFile"