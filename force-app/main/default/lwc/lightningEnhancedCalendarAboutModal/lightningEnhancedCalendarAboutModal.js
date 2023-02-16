//  Javascript controller for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

import LightningModal from 'lightning/modal';

import CLOSE from '@salesforce/label/c.LEC_Close';

export default class LightningEnhancedCalendarAboutModal extends LightningModal {

    labels = {
        CLOSE
    };

    handleCloseButton(event) {
        this.close();
    }
}