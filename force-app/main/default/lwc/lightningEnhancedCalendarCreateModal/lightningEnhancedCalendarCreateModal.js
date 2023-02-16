//  Javascript controller for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

import CREATE_NEW_CALENDAR_ENTRY_MODAL_HEADER from '@salesforce/label/c.LEC_Create_New_Calendar_Entry_Modal_Header';
import CALENDAR_ENTRY_TYPE from '@salesforce/label/c.LEC_Calendar_Entry_Type';
import PLEASE_SELECT_CALENDAR_ENTRY_TYPE from '@salesforce/label/c.LEC_Please_Select_Calendar_Entry_Type';
import SAVE from '@salesforce/label/c.LEC_Save';
import CANCEL from '@salesforce/label/c.LEC_Cancel';
import MUST_BE_EARLIER_THAN from '@salesforce/label/c.LEC_Must_Be_Earlier_Than';

export default class lightningEnhancedCalendarCreateModal extends LightningModal {
	@api objectProperties;
	@api startDate;
	@api endDate;

	labels = {
		CREATE_NEW_CALENDAR_ENTRY_MODAL_HEADER,
		PLEASE_SELECT_CALENDAR_ENTRY_TYPE,
		CALENDAR_ENTRY_TYPE,
		SAVE,
		CANCEL
	};

	@track objectList = [];
	get showObjectList() {
		return !this.selectedObject;
	}
	get showInputFields() {
		return this.selectedObject;
	}

	@track selectedObject;

	connectedCallback() {
		if (this.objectProperties.length === 1) {
			this.selectedObject = this.objectProperties[0];
		} else {
			this.objectList = [];
			this.objectProperties.forEach((obj) => {
				this.objectList.push({
					label: obj.objectLabel,
					value: obj.objectApiName
				});
			});
		}
	}

	handleObjectListSelect(event) {
		this.selectedObject = this.objectProperties.find((elem) => elem.objectApiName === event.detail.value);
	}

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
			status: 'cancel'
		});
	}

	handleSaveButton(event) {
		const allGood = [this.refs.title, this.refs.startDate, this.refs.endDate].reduce((validSoFar, inputField) => {
			inputField.reportValidity();
			return validSoFar && inputField.checkValidity();
		}, true);
		if (allGood && this.datesAreValid()) {
			this.close({
				status: 'create',
				objectApiName: this.selectedObject.objectApiName,
				nameFieldApiName: this.selectedObject.nameFieldApiName,
				startApiName: this.selectedObject.startApiName,
				endApiName: this.selectedObject.endApiName,
				name: this.refs.title.value,
				startDate: new Date(this.refs.startDate.value).toISOString(),
				endDate: new Date(this.refs.endDate.value).toISOString()
			});
		}
	}
}