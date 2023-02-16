//  Anonymous Apex to generate sample data for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

final Integer DAY_SPREAD = 60;
final Integer MAX_EVENTS = 50;

List<Event> events = [SELECT Id FROM Event];
List<Test_Object__c> testEvents = [SELECT Id FROM Test_Object__c];
DateTime now = DateTime.now();

if (!events.isEmpty())
    delete events;
if (!testEvents.isEmpty())
    delete testEvents;

events = new List<Event>();
testEvents = new List<Test_Object__c>();
for (Integer ev = 1; ev <= MAX_EVENTS; ev++) {
    DateTime startingTime = now.addMinutes(Integer.valueOf((Math.random()*2.0 < 1.0 ? -1 : 1) * (Math.random() * DAY_SPREAD * 24 * 60)));
    DateTime endingTime = startingTime.addMinutes(30 + Integer.valueOf(Math.random() * 60 * 18));
    events.add(new Event (Subject = 'Event ' + ev, StartDateTime = startingTime, EndDateTime = endingTime));
    startingTime = now.addMinutes(Integer.valueOf((Math.random()*2.0 < 1.0 ? -1 : 1) * (Math.random() * DAY_SPREAD * 24 * 60)));
    endingTime = startingTime.addMinutes(30 + Integer.valueOf(Math.random() * 60 * 18));
    testEvents.add(new Test_Object__c (Name = 'Test Object ' + ev, Start_Time__c = startingTime, End_Time__c = endingTime));
}
insert events;
insert testEvents;