//  Javascript controller for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

import { api } from 'lwc';
import LightningModal from 'lightning/modal';

import GET_INFORMATION_MODAL_HEADER from '@salesforce/label/c.LEC_Get_Information_Modal_Header';
import GO_TO_CALENDAR_ENTRY from '@salesforce/label/c.LEC_Go_To_Calendar_Entry';
import CANCEL from '@salesforce/label/c.LEC_Cancel';
import CLOSE from '@salesforce/label/c.LEC_Close';
import DELETE from '@salesforce/label/c.LEC_Delete';
import ARE_YOU_SURE from '@salesforce/label/c.LEC_Are_You_Sure';

export default class LightningEnhancedCalendarInfoModal extends LightningModal {
	@api eventTitle;
	@api eventTitleLabel;
	@api startLabel;
	@api endLabel;
	@api startDate;
	@api endDate;

	labels = {
		GET_INFORMATION_MODAL_HEADER,
		CANCEL,
		CLOSE,
		GO_TO_CALENDAR_ENTRY,
		DELETE,
		ARE_YOU_SURE
	};

	showConfirmationDialog = false;

    handleDeleteButton(event) {
		this.showConfirmationDialog = true;
    }

	handleConfirmDeleteButton(event) {
        this.close({
			status: 'delete'
		});
	}

	handleGoToCalendarEntryButton(event) {
		this.close({
			status: 'go-to-record'
		});
	}
    
    handleCloseButton(event) {
		this.close({
			status: 'close'
		});
	}
}