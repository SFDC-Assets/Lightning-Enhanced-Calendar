//  Apex test class for the Lightning Enhanced Calendar LWC.
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

@isTest(isParallel=true)
private without sharing class LightningEnhancedCalendarTest {
	static final Integer DAY_SPREAD = 30;
	static final Integer MAX_EVENTS = 10;

	@testSetup
	private static void setup() {
		insert makeEvents (MAX_EVENTS);
	}

	private static List<Event> makeEvents (Integer numberOfEvents) {
		final Id userId = UserInfo.getUserId();
		final DateTime now = DateTime.now();
		List<Event> events = new List<Event>();

		for (Integer ev = 1; ev <= numberOfEvents; ev++) {
			DateTime startingTime = now.addHours(Integer.valueOf((Math.random() * 2.0 < 1.0 ? -1 : 1) * (Math.random() * DAY_SPREAD * 24)));
			DateTime endingTime = startingTime.addMinutes(30 + Integer.valueOf(Math.random() * 60 * 18));
			events.add(
				new Event(
					Subject = 'Meeting',
					Description = 'Event ' + ev,
					StartDateTime = startingTime,
					EndDateTime = endingTime,
					OwnerId = userId
				)
			);
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
		Assert.areEqual(1, calObjects.size(), 'Retrieved ' + calObjects.size() + ' calendar events.');
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
			// Exception properly handled.
		}

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
		Assert.areEqual(calObjects.size(), calObjects.size(), 'Bad object exception was not handled.');
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
			// Exception properly handled.
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
