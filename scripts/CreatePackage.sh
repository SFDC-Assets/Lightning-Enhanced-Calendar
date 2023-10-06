#!/bin/bash
#
#  Creates a new package in the dev hub.
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

readonly devHubOrgAlias=$(jq --raw-output .defaultdevhubusername < .sfdx/sfdx-config.json) || {
    echo "Make sure that \"jq\" is installed and that \"defaultdevhubusername\" is defined in .sfdx/sfdx-config.json." >&2
    exit 1
}

sf package create \
    --package-type "Unlocked" \
    --no-namespace \
    --name "Lightning Enhanced Calendar" \
    --description "This package contains code and metadata for a Salesforce Lightning Web Component that displays, creates, updates, and deletes records of arbitrary object types in a calendar." \
    --path "force-app" \
    --target-dev-hub "$devHubOrgAlias"