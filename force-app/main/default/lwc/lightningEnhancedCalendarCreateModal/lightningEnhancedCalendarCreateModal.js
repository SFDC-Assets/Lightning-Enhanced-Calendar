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

	labels = {
		CREATE_NEW_CALENDAR_ENTRY_MODAL_HEADER,
		PLEASE_SELECT_CALENDAR_ENTRY_TYPE,
		CALENDAR_ENTRY_TYPE,
		SAVE,
		CANCEL
	};

	@track objectList = [];
	@track selectedObject;

	connectedCallback() {
		this.objectProperties.forEach((obj) => {
			this.objectList.push({
				label: obj.objectLabel,
				value: obj.objectApiName
			});
		});
	}

	handleObjectListSelect(event) {
		this.selectedObject = this.objectProperties.find((elem) => elem.objectApiName === event.detail.value);
	}

	handleCancelButton(event) {
		this.close({
			status: 'cancel'
		});
	}

	handleSaveButton(event) {
		this.close({
			status: 'create',
			objectApiName: this.selectedObject.objectApiName,
			nameFieldApiName: this.selectedObject.nameFieldApiName,
			startApiName: this.selectedObject.startApiName,
			endApiName: this.selectedObject.endApiName
		});
	}
}
