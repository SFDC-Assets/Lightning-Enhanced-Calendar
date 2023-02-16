//  Javascript controller for the Update Record Dynamic Interaction Tester for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

import { LightningElement, api } from 'lwc';

export default class LightningEnhancedCalendarUpdateRecordDynamicInteraction extends LightningElement {
    @api kind;
    @api recordId;
    @api objectApiName;
    @api startApiName;
    @api endApiName;
    @api start;
    @api end;
}