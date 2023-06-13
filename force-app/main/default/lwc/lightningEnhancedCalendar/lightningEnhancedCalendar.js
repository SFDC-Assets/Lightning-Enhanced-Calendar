//  Javascript controller for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

import { LightningElement, api, track } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import fullCalendar from '@salesforce/resourceUrl/fullCalendar';
import LightningEnhancedCalendarAboutModal from 'c/lightningEnhancedCalendarAboutModal';
import LightningEnhancedCalendarInfoModal from 'c/lightningEnhancedCalendarInfoModal';
import LightningEnhancedCalendarUpdateModal from 'c/lightningEnhancedCalendarUpdateModal';
import LightningEnhancedCalendarCreateModal from 'c/lightningEnhancedCalendarCreateModal';
import getEvents from '@salesforce/apex/LightningEnhancedCalendar.getEvents';
import updateRecord from '@salesforce/apex/LightningEnhancedCalendar.updateRecord';
import deleteRecord from '@salesforce/apex/LightningEnhancedCalendar.deleteRecord';

import COULD_NOT_LOAD_MAIN_JAVASCRIPT_LIBRARIES from '@salesforce/label/c.LEC_Could_Not_Load_Main_JavaScript_Libraries';
import COULD_NOT_LOAD_SUPPLEMENTAL_JAVASCRIPT_LIBRARIES from '@salesforce/label/c.LEC_Could_Not_Load_Supplemental_JavaScript_Libraries';
import COULD_NOT_GET_CALENDAR_ENTRIES_FOR from '@salesforce/label/c.LEC_Could_Not_Get_Calendar_Entries';
import COULD_NOT_LOAD_CALENDAR_ENTRIES from '@salesforce/label/c.LEC_Could_Not_Load_Calendar_Entries';
import NEW_LABEL from '@salesforce/label/c.LEC_New';
import CREATE_NEW_CALENDAR_ENTRY from '@salesforce/label/c.LEC_Create_New_Calendar_Entry';
import HELP from '@salesforce/label/c.LEC_Help';
import ABOUT_LIGHTNING_ENHANCED_CALENDAR from '@salesforce/label/c.LEC_About_Lightning_Enhanced_Calendar';
import REFRESH from '@salesforce/label/c.LEC_Refresh';
import REFRESH_THE_CALENDAR from '@salesforce/label/c.LEC_Refresh_the_Calendar';
import TOGGLE_DAY_VIEW from '@salesforce/label/c.LEC_Toggle_Day_View';
import TOGGLE_WEEK_VIEW from '@salesforce/label/c.LEC_Toggle_Week_View';
import TOGGLE_MONTH_VIEW from '@salesforce/label/c.LEC_Toggle_Month_View';
import TOGGLE_YEAR_VIEW from '@salesforce/label/c.LEC_Toggle_Year_View';
import TOGGLE_CALENDAR_VIEW from '@salesforce/label/c.LEC_Toggle_Calendar_View';
import TOGGLE_LIST_VIEW from '@salesforce/label/c.LEC_Toggle_List_View';
import TOGGLE_TIMELINE_VIEW from '@salesforce/label/c.LEC_Toggle_Timeline_View';
import TODAY from '@salesforce/label/c.LEC_Today';
import GO_TO_TODAYS_PAGE from '@salesforce/label/c.LEC_Go_To_Todays_Page';
import GO_TO_PREVIOUS_PAGE from '@salesforce/label/c.LEC_Go_To_Previous_Page';
import GO_TO_NEXT_PAGE from '@salesforce/label/c.LEC_Go_To_Next_Page';
import GO_TO_DATE from '@salesforce/label/c.LEC_Go_To_Date';
import DURATION from '@salesforce/label/c.LEC_Duration';
import TYPE from '@salesforce/label/c.LEC_Type';
import CALENDAR_ENTRY_SUCCESSFULLY_CREATED from '@salesforce/label/c.LEC_Calendar_Entry_Successfully_Created';
import COULD_NOT_CREATE_CALENDAR_ENTRY from '@salesforce/label/c.LEC_Could_Not_Create_Calendar_Entry';
import CALENDAR_ENTRY_SUCCESSFULLY_DELETED from '@salesforce/label/c.LEC_Calendar_Entry_Successfully_Deleted';
import COULD_NOT_DELETE_CALENDAR_ENTRY from '@salesforce/label/c.LEC_Could_Not_Delete_Calendar_Entry';
import CALENDAR_ENTRY_SUCCESSFULLY_UPDATED from '@salesforce/label/c.LEC_Calendar_Entry_Successfully_Updated';
import COULD_NOT_UPDATE_CALENDAR_ENTRY from '@salesforce/label/c.LEC_Could_Not_Update_Calendar_Entry';

const WEEKEND_COLOR = '#DDDDDD';
const VIEWS = {
	day: { calendar: 'timeGridDay', list: 'listDay', timeline: 'timelineDay' },
	week: { calendar: 'timeGridWeek', list: 'listWeek', timeline: 'timelineWeek' },
	month: { calendar: 'dayGridMonth', list: 'listMonth', timeline: 'timelineMonth' },
	year: { calendar: 'timelineYear', list: 'listYear', timeline: 'timelineYear' }
};

export default class LightningEnhancedCalendar extends NavigationMixin(LightningElement) {
	@api cardTitle = 'Calendar';
	@api defaultDuration = 'week';
	@api defaultType = 'calendar';
	@api objects;
	@api shadeWeekends = false;
	@api showWeekNumbers = false;
	@api licenseKey;

	@api recordId;

	labels = {
		NEW_LABEL,
		HELP,
		ABOUT_LIGHTNING_ENHANCED_CALENDAR,
		REFRESH,
		REFRESH_THE_CALENDAR,
		CREATE_NEW_CALENDAR_ENTRY,
		TOGGLE_DAY_VIEW,
		TOGGLE_WEEK_VIEW,
		TOGGLE_MONTH_VIEW,
		TOGGLE_YEAR_VIEW,
		TOGGLE_CALENDAR_VIEW,
		TOGGLE_TIMELINE_VIEW,
		TOGGLE_LIST_VIEW,
		TODAY,
		GO_TO_TODAYS_PAGE,
		GO_TO_PREVIOUS_PAGE,
		GO_TO_NEXT_PAGE,
		GO_TO_DATE,
		DURATION,
		TYPE
	};

	@track events = [];
	@track calendar;

	calendarTitle;

	spinnerVisible = false;

	jsInitialized = false;

	firstRender = true;

	selectedDuration;
	@track durations = {
		day: { selected: false, variant: 'neutral' },
		week: { selected: true, variant: 'neutral' },
		month: { selected: false, variant: 'brand' },
		year: { selected: false, variant: 'neutral' }
	};
	selectedType;
	@track types = {
		calendar: { selected: true, variant: 'brand' },
		list: { selected: false, variant: 'neutral' },
		timeline: { selected: false, variant: 'neutral' }
	};

	objectProperties = [];

	connectedCallback() {
		this.addEventListener('fcnewdraggedevent', this.handleNewDraggedEvent.bind(this));
		this.addEventListener('fceventclick', this.handleEventClick.bind(this));
		this.addEventListener('fceventdrop', this.handleEventDrop.bind(this));
		this.addEventListener('fceventresize', this.handleEventResize.bind(this));
	}

	renderedCallback() {
		if (!this.jsInitialized) {
			Promise.all([
				loadScript(this, fullCalendar + '/packages/core/main.js'),
				loadStyle(this, fullCalendar + '/packages/core/main.min.css')
			])
				.then(() => {
					Promise.all([
						loadScript(this, fullCalendar + '/packages/daygrid/main.min.js'),
						loadStyle(this, fullCalendar + '/packages/daygrid/main.min.css'),
						loadScript(this, fullCalendar + '/packages/list/main.min.js'),
						loadStyle(this, fullCalendar + '/packages/list/main.min.css'),
						loadScript(this, fullCalendar + '/packages/timegrid/main.min.js'),
						loadStyle(this, fullCalendar + '/packages/timegrid/main.min.css'),
						loadScript(this, fullCalendar + '/packages/interaction/main.min.js'),
						loadScript(this, fullCalendar + '/packages/moment/main.min.js'),
						loadScript(this, fullCalendar + '/packages/moment-timezone/main.min.js'),
						loadScript(this, fullCalendar + '/packages-premium/timeline/main.min.js'),
						loadStyle(this, fullCalendar + '/packages-premium/timeline/main.min.css')
					])
						.then(() => {
							this.initializeCalendar();
						})
						.catch((error) => {
							this.dispatchEvent(
								new ShowToastEvent({
									title: COULD_NOT_LOAD_SUPPLEMENTAL_JAVASCRIPT_LIBRARIES,
									message: JSON.stringify(error),
									variant: 'error',
									mode: 'sticky'
								})
							);
						});
				})
				.catch((error) => {
					this.dispatchEvent(
						new ShowToastEvent({
							title: COULD_NOT_LOAD_MAIN_JAVASCRIPT_LIBRARIES,
							message: JSON.stringify(error),
							variant: 'error',
							mode: 'sticky'
						})
					);
				})
				.finally(() => {
					this.jsInitialized = true;
				});
		}
	}

	initializeCalendar() {
		this.spinnerVisible = true;
		this.selectedDuration = this.defaultDuration;
		this.selectedType = this.defaultType;
		this.setDurationButtons(this.defaultDuration);
		this.setTypeButtons(this.defaultType);
		this.objectProperties = [];
		getEvents({ objectsString: this.objects, recordId: this.recordId })
			.then((result) => {
				if (result) {
					this.events = [];
					if (this.shadeWeekends)
						this.events.push({
							id: 'weekends',
							daysOfWeek: [0, 6],
							rendering: 'background',
							color: WEEKEND_COLOR,
							overLap: false,
							allDay: true
						});
					result.forEach((calObject) => {
						if (calObject.error) {
							this.dispatchEvent(
								new ShowToastEvent({
									title: `${COULD_NOT_GET_CALENDAR_ENTRIES_FOR} ${calObject.objectLabel}`,
									message: calObject.errorMsg,
									variant: 'error',
									mode: 'sticky'
								})
							);
						} else {
							this.objectProperties.push({
								objectApiName: calObject.objectApiName,
								objectLabel: calObject.objectLabel,
								nameFieldApiName: calObject.nameFieldApiName,
								nameFieldLabel: calObject.nameFieldLabel,
								startApiName: calObject.startApiName,
								startLabel: calObject.startLabel,
								endApiName: calObject.endApiName,
								endLabel: calObject.endLabel,
								color: calObject.color
							});
							calObject.events.forEach((calEvent) => {
								this.events.push({
									id: calEvent.id,
									title: calEvent.title,
									start: new Date(calEvent.startTime),
									end: new Date(calEvent.endTime),
									color: calObject.color,
									extendedProps: {
										objectApiName: calEvent.objectApiName
									}
								});
							});
						}
					});
					if (this.firstRender) {
						this.calendar = new FullCalendar.Calendar(this.refs.calendar, {
							schedulerLicenseKey: this.licenseKey,
							plugins: ['dayGrid', 'timeGrid', 'list', 'interaction', 'moment', 'timeline'],
							views: {
								timelineWeek: {
									slotDuration: { minutes: 360 }
								},
								timeGridDay: {
									allDaySlot: false
								},
								timeGridWeek: {
									allDaySlot: false
								},
								timelineYear: {
									type: 'timeline',
									dateIncrement: { years: 1 },
									slotDuration: { months: 1 },
									visibleRange: (currentDate) => {
										return {
											start: currentDate.clone().startOf('year'),
											end: currentDate.clone().endOf('year')
										};
									}
								}
							},
							defaultView: VIEWS[this.selectedDuration][this.selectedType],
							titleFormat: {
								month: 'long',
								year: 'numeric',
								day: 'numeric'
							},
							eventTimeFormat: {
								hour: 'numeric',
								minute: '2-digit',
								meridiem: 'short'
							},
							nowIndicator: true,
							editable: true,
							selectable: true,
							weekNumbers: this.showWeekNumbers,
							select: (info) => {
								this.dispatchEvent(
									new CustomEvent('fcnewdraggedevent', {
										detail: info
									})
								);
							},
							eventClick: (info) => {
								this.dispatchEvent(
									new CustomEvent('fceventclick', {
										detail: info
									})
								);
							},
							eventDrop: (info) => {
								this.dispatchEvent(
									new CustomEvent('fceventdrop', {
										detail: info
									})
								);
							},
							eventResize: (info) => {
								this.dispatchEvent(
									new CustomEvent('fceventresize', {
										detail: info
									})
								);
							},
							header: false,
							events: this.events
						});
						this.firstRender = false;
					}
					this.calendar.render();
					this.calendarTitle = this.calendar.view.title;
				}
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: COULD_NOT_LOAD_CALENDAR_ENTRIES,
						message: error.body.message,
						variant: 'error',
						mode: 'sticky'
					})
				);
			})
			.finally(() => {
				this.spinnerVisible = false;
			});
	}

	setDurationButtons(newDuration) {
		Object.keys(this.durations).forEach((key, index) => {
			this.durations[key].selected = false;
			this.durations[key].variant = 'neutral';
		});
		this.durations[newDuration].selected = true;
		this.durations[newDuration].variant = 'brand';
	}

	setTypeButtons(newType) {
		Object.keys(this.types).forEach((key, index) => {
			this.types[key].selected = false;
			this.types[key].variant = 'neutral';
		});
		this.types[newType].selected = true;
		this.types[newType].variant = 'brand';
	}

	setDuration(newDuration) {
		this.selectedDuration = newDuration;
		this.setDurationButtons(newDuration);
		this.calendar.changeView(VIEWS[newDuration][this.selectedType]);
		this.calendarTitle = this.calendar.view.title;
	}

	setType(newType) {
		this.selectedType = newType;
		this.setTypeButtons(newType);
		this.calendar.changeView(VIEWS[this.selectedDuration][newType]);
		this.calendarTitle = this.calendar.view.title;
	}

	handleDurationButton(jsEvent) {
		this.setDuration(jsEvent.target.value);
	}

	handleTypeButton(jsEvent) {
		this.setType(jsEvent.target.value);
	}

	handleGotoDateButton(jsEvent) {
		this.calendar.gotoDate(jsEvent.target.value);
		this.calendarTitle = this.calendar.view.title;
	}

	handlePreviousButton(jsEvent) {
		this.calendar.prev();
		this.calendarTitle = this.calendar.view.title;
	}

	handleTodayButton(jsEvent) {
		this.calendar.today();
		this.calendarTitle = this.calendar.view.title;
	}

	handleNextButton(jsEvent) {
		this.calendar.next();
		this.calendarTitle = this.calendar.view.title;
	}

	handleScroll(jsEvent) {
		jsEvent.stopImmediatePropagation();
	}

	handleAboutModal(jsEvent) {
		LightningEnhancedCalendarAboutModal.open({
			size: 'small',
			description: 'Lightning Enhanced Calendar version and availability modal'
		});
	}

	createNewEvent(startDate, endDate) {
		LightningEnhancedCalendarCreateModal.open({
			size: 'small',
			description: 'Create new calendar entry',
			objectProperties: this.objectProperties,
		}).then((returnValue) => {
			switch (returnValue.status) {
				case 'cancel':
					break;
				case 'create':
					let defaultValues = {};
					defaultValues[returnValue.nameFieldApiName] = returnValue.name;
					defaultValues[returnValue.startApiName] = startDate === null ? null : this.calendar.formatIso(startDate);
					defaultValues[returnValue.endApiName] = endDate === null ? null : this.calendar.formatIso(endDate);
					this[NavigationMixin.Navigate]({
						type: 'standard__objectPage',
						attributes: {
							objectApiName: returnValue.objectApiName,
							actionName: 'new'
						},
						state: {
							defaultFieldValues: encodeDefaultFieldValues(defaultValues)
						}
					});
			}
		});
	}

	handleNewDraggedEvent(jsEvent) {
		jsEvent.preventDefault();
		jsEvent.stopPropagation();
		this.createNewEvent(jsEvent.detail.start, jsEvent.detail.end);
	}

	handleNewEvent(jsEvent) {
		jsEvent.preventDefault();
		jsEvent.stopPropagation();
		this.createNewEvent(null, null);
	}

	handleEventClick(jsEvent) {
		jsEvent.preventDefault();
		jsEvent.stopPropagation();
		const objectInfo = this.objectProperties.find(
			(element) => element.objectApiName === jsEvent.detail.event.extendedProps.objectApiName
		);
		LightningEnhancedCalendarInfoModal.open({
			size: 'small',
			description: 'Get calendar entry information',
			eventTitle: jsEvent.detail.event.title,
			eventTitleLabel: objectInfo.nameFieldLabel,
			startLabel: objectInfo.startLabel,
			endLabel: objectInfo.endLabel,
			startDate: this.calendar.formatIso(jsEvent.detail.event.start),
			endDate: this.calendar.formatIso(jsEvent.detail.event.end)
		}).then((returnValue) => {
			switch (returnValue.status) {
				case 'delete':
					this.spinnerVisible = true;
					deleteRecord({
						objectApiName: jsEvent.detail.event.extendedProps.objectApiName,
						recordId: jsEvent.detail.event.id
					})
						.then(() => {
							this.calendar.getEventById(jsEvent.detail.event.id).remove();
							this.dispatchEvent(
								new ShowToastEvent({
									message: CALENDAR_ENTRY_SUCCESSFULLY_DELETED,
									variant: 'success'
								})
							);
							this.dispatchEvent(
								new CustomEvent('leceventchanged', {
									bubbles: true,
									composed: true,
									detail: {
										kind: 'delete',
										recordId: jsEvent.detail.event.id,
										objectApiName: jsEvent.detail.event.extendedProps.objectApiName,
										startApiName: objectInfo.startApiName,
										endApiName: objectInfo.endApiName,
										start: this.calendar.formatIso(jsEvent.detail.event.start),
										end: this.calendar.formatIso(jsEvent.detail.event.end)
									}
								})
							);
						})
						.catch((error) => {
							this.dispatchEvent(
								new ShowToastEvent({
									title: COULD_NOT_DELETE_CALENDAR_ENTRY,
									message: error.body.message,
									variant: 'error',
									mode: 'sticky'
								})
							);
						})
						.finally(() => {
							this.spinnerVisible = false;
						});
					break;
				case 'go-to-record':
					this[NavigationMixin.Navigate]({
						type: 'standard__recordPage',
						attributes: {
							recordId: jsEvent.detail.event.id,
							actionName: 'view'
						}
					});
					break;
				case 'close':
					break;
			}
		});
	}

	eventChange(newEvent, previousEvent) {
		const objectInfo = this.objectProperties.find((element) => element.objectApiName === newEvent.extendedProps.objectApiName);
		LightningEnhancedCalendarUpdateModal.open({
			size: 'small',
			description: 'Update calendar entry',
			selectedObject: objectInfo,
			eventTitle: newEvent.title,
			startDate: this.calendar.formatIso(newEvent.start),
			endDate: this.calendar.formatIso(newEvent.end)
		}).then((returnValue) => {
			switch (returnValue.status) {
				case 'cancel':
					this.calendar.getEventById(newEvent.id).setDates(previousEvent.start, previousEvent.end);
					break;
				case 'update':
					this.spinnerVisible = true;
					updateRecord({
						objectApiName: newEvent.extendedProps.objectApiName,
						startApiName: objectInfo.startApiName,
						endApiName: objectInfo.endApiName,
						startDate: returnValue.startDate,
						endDate: returnValue.endDate,
						recordId: newEvent.id
					})
						.then(() => {
							this.calendar.getEventById(newEvent.id).setDates(returnValue.startDate, returnValue.endDate);
							this.dispatchEvent(
								new ShowToastEvent({
									message: CALENDAR_ENTRY_SUCCESSFULLY_UPDATED,
									variant: 'success'
								})
							);
							this.dispatchEvent(
								new CustomEvent('leceventchanged', {
									bubbles: true,
									composed: true,
									detail: {
										kind: 'update',
										recordId: newEvent.id,
										objectApiName: newEvent.extendedProps.objectApiName,
										startApiName: objectInfo.startApiName,
										endApiName: objectInfo.endApiName,
										start: returnValue.startDate,
										end: returnValue.endDate
									}
								})
							);
						})
						.catch((error) => {
							this.dispatchEvent(
								new ShowToastEvent({
									title: COULD_NOT_UPDATE_CALENDAR_ENTRY,
									message: error.body.message,
									variant: 'error',
									mode: 'sticky'
								})
							);
						})
						.finally(() => {
							this.spinnerVisible = false;
						});
					break;
			}
		});
		this.calendar.rerenderEvents();
	}

	handleEventDrop(jsEvent) {
		jsEvent.preventDefault();
		jsEvent.stopPropagation();
		this.eventChange(jsEvent.detail.event, jsEvent.detail.oldEvent);
	}

	handleEventResize(jsEvent) {
		jsEvent.preventDefault();
		jsEvent.stopPropagation();
		this.eventChange(jsEvent.detail.event, jsEvent.detail.prevEvent);
	}
}
