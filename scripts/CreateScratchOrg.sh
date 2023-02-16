#!/bin/bash
#
#  Creates a new scratch org and populates it with sample data.
#
#  Copyright (c) 2023, salesforce.com, inc.
#  All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause
#  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
#
#  Contact: john.meyer@salesforce.com

readonly orgAlias=$(jq --raw-output .defaultusername < .sfdx/sfdx-config.json) || {
    echo "Make sure that \"jq\" is installed and that \"defaultusername\" is defined in .sfdx/sfdx-config.json." >&2
    exit 1
}
readonly devHubUserName=$(jq --raw-output .defaultdevhubusername < .sfdx/sfdx-config.json) || {
    echo "Make sure that \"jq\" is installed and that \"defaultdevhubusername\" is defined in .sfdx/sfdx-config.json." >&2
    exit 1
}

echo "*** Creating scratch org ..."
sfdx force:org:create \
    --definitionfile config/project-scratch-def.json \
    --type scratch \
    --nonamespace \
    --target-dev-hub "$devHubUserName" \
    --setdefaultusername \
    --setalias "$orgAlias" \
    --durationdays 30 || exit 1
echo "*** Pushing metadata to scratch org ..."
sfdx force:source:push || exit 1
echo "*** Assigning permission sets to your user ..."
sfdx force:user:permset:assign --perm-set-name "Lightning_Enhanced_Calendar"
sfdx force:user:permset:assign --perm-set-name "Lightning_Enhanced_Calendar_Tester"
echo "*** Generating password for your user ..."
sfdx force:user:password:generate --target-org "$orgAlias"
echo "*** Setting time zone for your user ..."
sfdx data record update --sobject User --where "Name='User User'" --values "TimeZoneSidKey='America/New_York'"
#echo "*** Enabling debug mode for your user  ..."
#sfdx data record update --sobject User --where "Name='User User'" --values "UserPreferencesUserDebugModePref='true'"
echo "*** Creating sample data ..."
sfdx force:apex:execute --apexcodefile "scripts/apex/SampleData.apex" --targetusername "$orgAlias"
echo "*** Opening scratch org ..."
sfdx force:org:open