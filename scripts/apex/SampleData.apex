/**
 *  Anonymous Apex to generate sample data for the Lightning Enhanced Calendar LWC.
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

final Integer DAY_SPREAD = 60;
final Integer MAX_EVENTS = 50;
final Integer MINIMUM_EVENT_LENGTH_MINUTES = 30;
final Integer HOURS_PER_DAY = 24;
final Integer MINUTES_PER_HOUR = 60;
final DateTime NOW = DateTime.now();

List<Event> events = [SELECT Id FROM Event];
List<Test_Object__c> testEvents = [SELECT Id FROM Test_Object__c];

if (!events.isEmpty())
    delete as user events;
if (!testEvents.isEmpty())
    delete as user testEvents;

events = new List<Event>();
testEvents = new List<Test_Object__c>();
for (Integer ev = 1; ev <= MAX_EVENTS; ev++) {
    DateTime startingTime = NOW.addMinutes(Integer.valueOf((Math.random() < 0.5 ? -1 : 1) * (Math.random() * DAY_SPREAD * HOURS_PER_DAY * MINUTES_PER_HOUR)));
    DateTime endingTime = startingTime.addMinutes(MINIMUM_EVENT_LENGTH_MINUTES + Integer.valueOf(Math.random() * MINUTES_PER_HOUR * 18));
    events.add(new Event (Subject = 'Meeting', Description = 'Event ' + ev, StartDateTime = startingTime, EndDateTime = endingTime));
    startingTime = now.addMinutes(Integer.valueOf((Math.random() < 0.5 ? -1 : 1) * (Math.random() * DAY_SPREAD * HOURS_PER_DAY * MINUTES_PER_HOUR)));
    endingTime = startingTime.addMinutes(MINIMUM_EVENT_LENGTH_MINUTES + Integer.valueOf(Math.random() * MINUTES_PER_HOUR * 18));
    testEvents.add(new Test_Object__c (Name = 'Test Object ' + ev, Start_Time__c = startingTime, End_Time__c = endingTime));
}
insert as user events;
insert as user testEvents;