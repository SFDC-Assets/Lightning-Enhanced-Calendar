//  Javascript controller for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: GPL-2.0-only
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/license/gpl-2-0
//
//  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; version 2.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
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