//  Apex controller for the Lightning Enhanced Calendar LWC.
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

public with sharing class LightningEnhancedCalendar {

    private final static String DEFAULT_COLOR = '#3A87AD';

    //  Internal object representing the description of an object to be displayed on the calendar. The input to the
    //  getEvents() method is a serialized JSON string representing this object.

    private class ObjectListItem {
        private String objectApiName;
        private String customLabel;
        private String nameFieldApiName;
        private String startApiName;
        private String endApiName;
        private String filter;
        private String color;
    }
 
    //  A serialized list of CalendarObjects will be returned to the component.

    public class CalendarObject {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public String nameFieldApiName;
        @AuraEnabled public String nameFieldLabel;
        @AuraEnabled public String startApiName;
        @AuraEnabled public String startLabel;
        @AuraEnabled public String endApiName;
        @AuraEnabled public String endLabel;
        @AuraEnabled public List<CalendarEntry> events;
        @AuraEnabled public String color;
        @AuraEnabled public Boolean error;
        @AuraEnabled public String errorMsg;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public CalendarObject(String objectApiName, String customLabel, String nameFieldApiName, String startApiName, String endApiName) {
            
            Schema.DescribeSObjectResult dsor = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Map<String,Schema.SObjectField> fields = dsor.fields.getMap();

            this.objectApiName = objectApiName;
            this.objectLabel = customLabel == null ? dsor.getLabel() : customLabel;
            this.nameFieldApiName = nameFieldApiName == null ? getNameField(fields.values()) : nameFieldApiName;
            this.nameFieldLabel = fields.get(this.nameFieldApiName)?.getDescribe().getLabel();
            this.startApiName = startApiName;
            this.startLabel = fields.get(startApiName)?.getDescribe().getLabel();
            this.endApiName = endApiName;
            this.endLabel = fields.get(endApiName)?.getDescribe().getLabel();
            this.events = new List<CalendarEntry>();
            this.error = false;
            this.errorMsg = null;
            this.color = DEFAULT_COLOR;
        }
    }

    public class CalendarEntry {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String title;
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public Id id;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public CalendarEntry (String objectApiName, String title, DateTime startTime, DateTime endTime, Id id) {
            this.objectApiName = objectApiName;
            this.title = title;
            this.startTime = startTime;
            this.endTime = endTime;
            this.id = id;
        }
    }


    //  Retrieves the list of entries to display on the calendar.
    //
    //  The parameters represent:
    //      objectsString:  A JSON string that will be deserialized into a list of ObjectListItem objects. Each item must contain:
    //      recordId:  (optional) the Id of a parent record used in an (optional) filter if used on a record page.

    @SuppressWarnings('PMD.ApexSoqlInjection, PMD.OperationWithLimitsInLoop')
    @AuraEnabled(cacheable=true)
    public static List<CalendarObject> getEvents (String objectsString, Id recordId) {

        List<ObjectListItem> objects;
        try {
            objects = (List<ObjectListItem>) JSON.deserialize(objectsString, List<ObjectListItem>.class);
            if (objects.size() > Limits.getLimitQueries()) {
                throw new AuraHandledException(System.Label.LEC_Too_Many_Objects + ' ' + Limits.getLimitQueries());
            }    
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.LEC_Bad_Objects_String);
        }

        List<CalendarObject> eventRecords = new List<CalendarObject>();
        for (ObjectListItem item : objects) {
            CalendarObject calObject = new CalendarObject(item.objectApiName, item.customLabel, item.nameFieldApiName, item.startApiName, item.endApiName);
            try {
                for (List<SObject> records : Database.query(
                        'SELECT ' + calObject.nameFieldApiName + ',' + item.startApiName + ',' + item.endApiName + ' FROM ' + item.objectApiName +
                        (item.filter == null ? '' : ' WHERE (' + item.filter + ')')
                    )) {
                    for (Sobject record : records) {
                        calObject.events.add(new CalendarEntry(
                            item.objectApiName,
                            (String) record.get(calObject.nameFieldApiName),
                            (DateTime) record.get(item.startApiName),
                            (DateTime) record.get(item.endApiName),
                            (Id) record.get('Id')
                        ));
                    }
                }
                calObject.color = item.color == null ? DEFAULT_COLOR : item.color;
            } catch (QueryException e) {
                calObject.error = true;
                calObject.errorMsg = e.getMessage();
            } catch (LimitException e) {
                calObject.error = true;
                throw new AuraHandledException(System.Label.LEC_Too_Many_Records + ' ' + Limits.getLimitQueryRows());
            }
            eventRecords.add(calObject);
        }

        return eventRecords;
    }


    //  Returns the API name for the name field of the object.
    //
    //  The parameter represents:
    //      fields: a list of SObjectFields to interrogate

    private static String getNameField (List<Schema.SObjectField> fields) {
        String nameFieldApiName;
        for (Schema.SObjectField field : fields) {
            if (field.getDescribe().isNameField()) {
                nameFieldApiName = field.getDescribe().getName();
                break;
            }
        }
        return nameFieldApiName;
    }


    //  Update a record with new values from the calendar. Normally, this would be done with a <lightning-record-edit-form>
    //  but as of this writing, this API does not support the Event SObject type.
    //
    //  The parameters represent:
    //      objectApiName:  the API name of the object to update.
    //      startApiName:  the API name of the starting DateTime field.
    //      endApiName:  the API name of the ending DateTime field.
    //      startDate:  the new start date and time.
    //      endDate:  the new end date and time.
    //      recordId:  the Id of the record to update.

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static void updateRecord(String objectApiName, String startApiName, String endApiName, DateTime startDate, DateTime endDate, Id recordId) {
        try {
            SObject record = Database.query(
                String.escapeSingleQuotes('SELECT ' + startApiName + ',' + endApiName + ' FROM ' + objectApiName + ' WHERE Id = :recordId')
            );
            record.put(startApiName, startDate);
            record.put(endApiName, endDate);
            update as user record;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    //  Delete a record from the calendar.
    //
    //  The parameters represent:
    //      objectApiName:  the API name of the object.
    //      recordId:  the Id of the record to delete.

    @AuraEnabled
    public static void deleteRecord(String objectApiName, Id recordId) {
        delete as user Database.query(String.escapeSingleQuotes('SELECT Id FROM ' + objectApiName + ' WHERE Id = :recordId'));
    }

}