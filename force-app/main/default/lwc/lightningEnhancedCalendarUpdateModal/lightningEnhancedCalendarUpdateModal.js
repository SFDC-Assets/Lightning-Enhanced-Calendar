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

import UPDATE_CALENDAR_ENTRY_MODAL_HEADER from '@salesforce/label/c.LEC_Update_Calendar_Entry_Modal_Header';
import SAVE from '@salesforce/label/c.LEC_Save';
import CANCEL from '@salesforce/label/c.LEC_Cancel';
import MUST_BE_EARLIER_THAN from '@salesforce/label/c.LEC_Must_Be_Earlier_Than';

export default class LightningEnhancedCalendarUpdateModal extends LightningModal {
	@api selectedObject;
	@api eventTitle;
	@api startDate;
	@api endDate;

	labels = {
		UPDATE_CALENDAR_ENTRY_MODAL_HEADER,
		SAVE,
		CANCEL
	};
	
	handleDateChange() {
		this.refs.startDate.setCustomValidity('');
		this.refs.endDate.setCustomValidity('');
	}

	datesAreValid() {
		if (Date.parse(this.refs.startDate.value) >= Date.parse(this.refs.endDate.value)) {
			this.refs.startDate.setCustomValidity(
				`${this.selectedObject.startLabel} ${MUST_BE_EARLIER_THAN} ${this.selectedObject.endLabel}`
			);
			this.refs.startDate.reportValidity();
			this.refs.endDate.setCustomValidity(
				`${this.selectedObject.startLabel} ${MUST_BE_EARLIER_THAN} ${this.selectedObject.endLabel}`
			);
			this.refs.endDate.reportValidity();
			return false;
		} else {
			return true;
		}
	}

	handleCancelButton(event) {
		this.close({
			status: 'cancel',
			startDate: this.startDate,
			endDate: this.endDate
		});
	}

	handleUpdateButton(event) {
		const allGood = [this.refs.title, this.refs.startDate, this.refs.endDate].reduce((validSoFar, inputField) => {
			inputField.reportValidity();
			return validSoFar && inputField.checkValidity();
		}, true);
		if (allGood && this.datesAreValid()) {
			this.close({
				status: 'update',
				startDate: new Date(this.refs.startDate.value).toISOString(),
				endDate: new Date(this.refs.endDate.value).toISOString()
			});
		}
	}
}