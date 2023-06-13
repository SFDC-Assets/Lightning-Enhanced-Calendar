//  Apex test class for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')     // Hasn't been updated for Assert class yet
@isTest(isParallel=true)
private without sharing class LightningEnhancedCalendarTest {

    static final Integer DAY_SPREAD = 30;
    static final Integer MAX_EVENTS = 1;

    @testSetup
	private static void setup () {

        Id userId = UserInfo.getUserId();
		DateTime now = DateTime.now();
		List<Event> events = new List<Event>();

		for (Integer ev = 1; ev <= MAX_EVENTS; ev++) {
			DateTime startingTime = now.addHours(Integer.valueOf((Math.random() * 2.0 < 1.0 ? -1 : 1) * (Math.random() * DAY_SPREAD * 24)));
			DateTime endingTime = startingTime.addMinutes(30 + Integer.valueOf(Math.random() * 60 * 18));
			events.add(new Event(Subject = 'Event ' + ev, StartDateTime = startingTime, EndDateTime = endingTime, OwnerId = userId));
		}
		insert events;
	}

	@isTest
	private static void testGetEvents () {
        System.Test.startTest();
        List<LightningEnhancedCalendar.CalendarObject> events = LightningEnhancedCalendar.getEvents(
            '[{"objectApiName": "Event", "startApiName": "StartDateTime", "endApiName": "EndDateTime", "color": "#3A87AD", "filter": "CreatedDate > 2005-01-01T01:00:00Z"}]', null
        );
        Assert.areEqual(MAX_EVENTS, events.size(), 'Retrieved ' + events.size() + ' calendar events.');
        System.Test.stopTest();
	}

    @SuppressWarnings('PMD.EmptyCatchBlock')
	@isTest
	private static void testBadJSONString () {
        System.Test.startTest();
        try {
            List<LightningEnhancedCalendar.CalendarObject> events = LightningEnhancedCalendar.getEvents('badJSON', null);
            Assert.fail('Should have created an AuraHandledException');
        } catch (Exception e) {
            // Exception properly handled.
        }
        System.Test.stopTest();
	}

	@isTest
	private static void testBadObjectSettings () {
        System.Test.startTest();
        List<LightningEnhancedCalendar.CalendarObject> events = LightningEnhancedCalendar.getEvents(
            '[{"objectApiName": "Event", "startApiName": "BadFieldName", "endApiName": "EndDateTime", "color": "#3A87AD"}]', null
        );
        // Exception properly handled.
        System.Test.stopTest();
	}

    @isTest
    private static void testDefaultDuration () {
        System.Test.startTest();
        LightningEnhancedCalendarDurationView defaultViews = new LightningEnhancedCalendarDurationView();
        VisualEditor.DynamicPickListRows rows = defaultViews.getValues();
        Assert.areNotEqual(0, rows.size(), 'Default views returned no rows.');
        Assert.areEqual('Week View', defaultViews.getDefaultValue().getLabel(), 'Bad default value.');
        System.Test.stopTest();
    }

    @isTest
    private static void testDefaultType () {
        System.Test.startTest();
        LightningEnhancedCalendarTypeView defaultViews = new LightningEnhancedCalendarTypeView();
        VisualEditor.DynamicPickListRows rows = defaultViews.getValues();
        Assert.areNotEqual(0, rows.size(), 'Default views returned no rows.');
        Assert.areEqual('Calendar View', defaultViews.getDefaultValue().getLabel(), 'Bad default value.');
        System.Test.stopTest();
    }

    @isTest
    private static void testGoodUpdateRecord () {
        System.Test.startTest();
        Event testEvent = [SELECT StartDateTime, EndDateTime FROM Event LIMIT 1][0];
        DateTime newStart = testEvent.StartDateTime.addHours(1);
        DateTime newEnd = testEvent.EndDateTime.addHours(1);
        LightningEnhancedCalendar.updateRecord('Event', 'StartDateTime', 'EndDateTime', newStart, newEnd, testEvent.Id);
        testEvent = [SELECT StartDateTime, EndDateTime FROM Event LIMIT 1][0];
        Assert.areEqual(newStart, testEvent.StartDateTime);
        Assert.areEqual(newEnd, testEvent.EndDateTime);
        System.Test.stopTest();
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    @isTest
    private static void testBadUpdateRecord () {
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
    private static void testGoodDeleteRecord () {
        System.Test.startTest();
        Id recordId = [SELECT Id FROM Event LIMIT 1].Id;
        LightningEnhancedCalendar.deleteRecord('Event', recordId);
        Assert.areEqual(0, [SELECT COUNT() FROM Event WHERE Id = :recordId]);
        System.Test.stopTest();
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    @isTest
    private static void testBadDeleteRecord () {
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