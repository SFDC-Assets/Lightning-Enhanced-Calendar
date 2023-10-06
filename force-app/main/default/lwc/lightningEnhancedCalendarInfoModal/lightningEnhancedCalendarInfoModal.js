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