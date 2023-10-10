#!/bin/bash
#
#  Creates a new scratch org and populates it with sample data.
#
#  Copyright (c) 2023, salesforce.com, inc.
#  All rights reserved.
#  SPDX-License-Identifier: GPL-2.0-only
#  For full license text, see the LICENSE file in the repo root or https://opensource.org/license/gpl-2-0
#
#  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
#  Contact: john.meyer@salesforce.com

readonly orgAlias="Lightning Enhanced Calendar"
readonly devHubUserName=$(jq --raw-output .defaultdevhubusername < .sfdx/sfdx-config.json) || {
    echo "Make sure that \"jq\" is installed and that \"defaultdevhubusername\" is defined in .sfdx/sfdx-config.json." >&2
    exit 1
}

echo "*** Creating scratch org ..."
sf org create scratch \
    --definition-file config/project-scratch-def.json \
    --no-namespace \
    --target-dev-hub "$devHubUserName" \
    --set-default \
    --alias "$orgAlias" \
    --duration-days 30 || exit 1
echo "*** Pushing metadata to scratch org ..."
sf project deploy start || exit 1
echo "*** Assigning permission sets to your user ..."
sf force user permset assign --perm-set-name "Lightning_Enhanced_Calendar" --perm-set-name "Lightning_Enhanced_Calendar_Tester"
echo "*** Generating password for your user ..."
sf force user password generate
echo "*** Setting time zone for your user ..."
sf data record update --sobject User --where "Name='User User'" --values "TimeZoneSidKey='America/New_York'"
echo "*** Enabling debug mode for your user  ..."
sf data record update --sobject User --where "Name='User User'" --values "UserPreferencesUserDebugModePref='true'"
echo "*** Creating sample data ..."
sf apex run --file "scripts/apex/SampleData.apex" --target-org "$orgAlias"
echo "*** Opening scratch org ..."
sf org open