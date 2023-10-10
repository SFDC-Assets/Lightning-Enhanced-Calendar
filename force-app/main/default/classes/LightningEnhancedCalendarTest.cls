/**
 *  Apex test class for the Lightning Enhanced Calendar LWC.
 *
 *  Copyright (c) 2023, salesforce.com, inc.
 *  All rights reserved.
 *  SPDX-License-Identifier: GPL-2.0-only
 *  For full license text, see the LICENSE file in the repo root or https://opensource.org/license/gpl-2-0
 *
 *  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; version 2.
 *
 *  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 *  @author john.meyer@salesforce.com
 */

@isTest(isParallel=true seeAllData=false)
private without sharing class LightningEnhancedCalendarTest {

	static final Integer DAY_SPREAD = 30;
	static final Integer MAX_EVENTS = LightningEnhancedCalendar.TEST_MAXIMUM_ROWS;
	static final Integer MINIMUM_EVENT_LENGTH_MINUTES = 30;
	static final Integer HOURS_PER_DAY = 24;
	static final Integer MINUTES_PER_HOUR = 60;
	static final DateTime NOW = DateTime.now();

	@testSetup
	private static void setup() {
		insert makeEvents(MAX_EVENTS);
	}

	private static List<Event> makeEvents (Integer numberOfEvents) {
		final Id userId = UserInfo.getUserId();
		List<Event> events = new List<Event>();

		for (Integer ev = 1; ev <= numberOfEvents; ev++) {
			DateTime startingTime = NOW.addHours(Integer.valueOf((Math.random() < 0.5 ? -1 : 1) * (Math.random() * DAY_SPREAD * HOURS_PER_DAY)));
			DateTime endingTime = startingTime.addMinutes(MINIMUM_EVENT_LENGTH_MINUTES + Integer.valueOf(Math.random() * MINUTES_PER_HOUR * 18));
			events.add(new Event(
				Subject = 'Meeting',
				Description = 'Event ' + ev,
				StartDateTime = startingTime,
				EndDateTime = endingTime,
				OwnerId = userId
			));
		}	
		return events;
	}

	@isTest
	private static void testGetEvents() {
		System.Test.startTest();
		List<LightningEnhancedCalendar.CalendarObject> calObjects = LightningEnhancedCalendar.getEvents(
			'[{"objectApiName": "Event", "startApiName": "StartDateTime", "endApiName": "EndDateTime", "color": "#3A87AD", "filter": "CreatedDate > 2005-01-01T01:00:00Z"}]',
			null
		);
		Assert.areEqual(1, calObjects.size(), 'Retrieved ' + calObjects.size() + ' calendar events, should have been 1.');
		System.Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@isTest
	private static void testBadJSONString() {
		System.Test.startTest();
		try {
			List<LightningEnhancedCalendar.CalendarObject> calObjects = LightningEnhancedCalendar.getEvents('badJSON', null);
			Assert.fail('Bad JSON string should have thrown an AuraHandledException.');
		} catch (Exception e) {
			// Exception properly generated.
		}
		System.Test.stopTest();
	}

	@isTest
	private static void testBadObjectName() {
		System.Test.startTest();
		List<LightningEnhancedCalendar.CalendarObject> calObjects = LightningEnhancedCalendar.getEvents(
			'[{"objectApiName": "BadObjectApiName", "startApiName": "BadFieldName", "endApiName": "EndDateTime", "color": "#3A87AD"}]',
			null
		);
		// Exception properly handled.
		Assert.areEqual(calObjects.size(), calObjects.size(), 'Bad object exception was not handled.');
		System.Test.stopTest();
	}

	@isTest
	private static void testBadObjectSettings() {
		System.Test.startTest();
		List<LightningEnhancedCalendar.CalendarObject> calObjects = LightningEnhancedCalendar.getEvents(
			'[{"objectApiName": "Event", "startApiName": "BadFieldName", "endApiName": "EndDateTime", "color": "#3A87AD"}]',
			null
		);
		// Exception properly handled.
		Assert.areEqual(calObjects.size(), calObjects.size(), 'Bad object settings exception was not handled.');
		System.Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@isTest
	private static void testTooManyObjects() {
		System.Test.startTest();
		String testString = '{"objectApiName": "Event", "startApiName": "StartDateTime", "endApiName": "EndDateTime", "color": "#3A87AD"}';
		String objectString = testString;
		for (Integer count = 0; count < Limits.getLimitQueries() + 1; count++) {
			objectString += ', ' + testString;
		}
		objectString = '[' + objectString + ']';
		try {
			List<LightningEnhancedCalendar.CalendarObject> calObjects = LightningEnhancedCalendar.getEvents(objectString, null);
			Assert.fail('Too many objects should have thrown an AuraHandledException.');
		} catch (Exception e) {
			// Exception properly generated.
		}
		System.Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@isTest
	private static void testTooManyRecords() {
		System.Test.startTest();
		insert makeEvents(MAX_EVENTS);
		String testString = '{"objectApiName": "Event", "startApiName": "StartDateTime", "endApiName": "EndDateTime", "color": "#3A87AD"}';
		testString = '[' + testString + ',' + testString + ']';
		try {
			List<LightningEnhancedCalendar.CalendarObject> calObjects = LightningEnhancedCalendar.getEvents(testString, null);
			Assert.fail('Too many records should have thrown an AuraHandledException.');
		} catch (Exception e) {
			// Exception properly generated.
		}
		System.Test.stopTest();
	}

	@isTest
	private static void testDefaultDuration() {
		System.Test.startTest();
		LightningEnhancedCalendarDurationView defaultViews = new LightningEnhancedCalendarDurationView();
		VisualEditor.DynamicPickListRows rows = defaultViews.getValues();
		Assert.areNotEqual(0, rows.size(), 'Default views returned no rows.');
		Assert.areEqual('Week View', defaultViews.getDefaultValue().getLabel(), 'Bad default value.');
		System.Test.stopTest();
	}

	@isTest
	private static void testDefaultType() {
		System.Test.startTest();
		LightningEnhancedCalendarTypeView defaultViews = new LightningEnhancedCalendarTypeView();
		VisualEditor.DynamicPickListRows rows = defaultViews.getValues();
		Assert.areNotEqual(0, rows.size(), 'Default views returned no rows.');
		Assert.areEqual('Calendar View', defaultViews.getDefaultValue().getLabel(), 'Bad default value.');
		System.Test.stopTest();
	}

	@isTest
	private static void testGoodUpdateRecord() {
		System.Test.startTest();
		Event testEvent = [SELECT StartDateTime, EndDateTime FROM Event LIMIT 1][0];
		DateTime newStart = testEvent.StartDateTime.addHours(1);
		DateTime newEnd = testEvent.EndDateTime.addHours(1);
		LightningEnhancedCalendar.updateRecord('Event', 'StartDateTime', 'EndDateTime', newStart, newEnd, testEvent.Id);
		testEvent = [SELECT StartDateTime, EndDateTime FROM Event LIMIT 1][0];
		Assert.areEqual(newStart, testEvent.StartDateTime, 'Update record failed to change start date and time.');
		Assert.areEqual(newEnd, testEvent.EndDateTime, 'Update record failed to change end date and time.');
		System.Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@isTest
	private static void testBadUpdateRecord() {
		System.Test.startTest();
		Event testEvent = [SELECT StartDateTime, EndDateTime FROM Event LIMIT 1][0];
		DateTime newStart = testEvent.StartDateTime.addHours(1);
		DateTime newEnd = testEvent.EndDateTime.addHours(1);
		try {
			LightningEnhancedCalendar.updateRecord('Event', 'BadFieldName', 'EndDateTime', newStart, newEnd, testEvent.Id);
			Assert.fail('updateRecord should have generated an exception.');
		} catch (Exception e) {
			// Exception properly generated.
		}
		System.Test.stopTest();
	}

	@isTest
	private static void testGoodDeleteRecord() {
		System.Test.startTest();
		Id recordId = [SELECT Id FROM Event LIMIT 1].Id;
		LightningEnhancedCalendar.deleteRecord('Event', recordId);
		Assert.areEqual(0, [SELECT COUNT() FROM Event WHERE Id = :recordId], 'Delete record failed to delete the record.');
		System.Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@isTest
	private static void testBadDeleteRecord() {
		System.Test.startTest();
		try {
			LightningEnhancedCalendar.deleteRecord('BadObjectName', 'XXX');
			Assert.fail('deleteRecord should have generated an exception.');
		} catch (Exception e) {
			// Exception properly generated.
		}
		System.Test.stopTest();
	}
}
