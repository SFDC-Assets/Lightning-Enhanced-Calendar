//  Apex controller for the Lightning Enhanced Calendar LWC.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

public with sharing class LightningEnhancedCalendar {

    private final static String DEFAULT_COLOR = '#3A87AD';

    //  Internal object representing the description of an object to be displayed on the calendar. The input to the
    //  getEvents() method is a serialized JSON string representing this object.

    private class ObjectListItem {
        private String objectApiName;
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
        @AuraEnabled public List<CalendarEvent> events;
        @AuraEnabled public String color;
        @AuraEnabled public Boolean error;
        @AuraEnabled public String errorMsg;

        public CalendarObject(String objectApiName, String startApiName, String endApiName) {
            
            Schema.DescribeSObjectResult sor = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Map<String,Schema.SObjectField> fields = sor.fields.getMap();

            this.objectApiName = objectApiName;
            this.objectLabel = sor.getLabel();
            this.nameFieldApiName = getNameField(objectApiName);
            this.nameFieldLabel = fields.get(this.nameFieldApiName)?.getDescribe().getLabel();
            this.startApiName = startApiName;
            this.startLabel = fields.get(startApiName)?.getDescribe().getLabel();
            this.endApiName = endApiName;
            this.endLabel = fields.get(endApiName)?.getDescribe().getLabel();
            this.events = new List<CalendarEvent>();
            this.error = false;
            this.errorMsg = null;
            this.color = DEFAULT_COLOR;
        }
    }

    public class CalendarEvent {
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String title;
        @AuraEnabled public DateTime startTime;
        @AuraEnabled public DateTime endTime;
        @AuraEnabled public Id id;

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public CalendarEvent (String objectApiName, String title, DateTime startTime, DateTime endTime, Id id) {
            this.objectApiName = objectApiName;
            this.title = title;
            this.startTime = startTime;
            this.endTime = endTime;
            this.id = id;
        }
    }


    //  Retrieves the list of events to display on the calendar.
    //
    //  The parameters represent:
    //      objectsString:  A JSON string that will be deserialized into a list of ObjectListItem objects. Each item must contain:
    //      recordId:  (optional) the Id of a parent record used in an (optional) filter if used on a record page.

    @SuppressWarnings('PMD.ApexSoqlInjection')
    @AuraEnabled(cacheable=true)
    public static List<CalendarObject> getEvents (String objectsString, Id recordId) {

        List<ObjectListItem> objects;
        try {
            objects = (List<ObjectListItem>) JSON.deserialize(objectsString, List<ObjectListItem>.class);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.LEC_Bad_Objects_String);
        }

        List<CalendarObject> eventRecords = new List<CalendarObject>();
        for (ObjectListItem item : objects) {
            CalendarObject co = new CalendarObject(item.objectApiName, item.startApiName, item.endApiName);
            try {
                for (SObject record : Database.query(
                        'SELECT ' + co.nameFieldApiName + ',' + item.startApiName + ',' + item.endApiName + ' FROM ' + item.objectApiName +
                        (item.filter == null ? '' : ' WHERE (' + item.filter + ')')
                    )) {
                    co.events.add(new CalendarEvent(
                        item.objectApiName,
                        (String) record.get(co.nameFieldApiName),
                        (DateTime) record.get(item.startApiName),
                        (DateTime) record.get(item.endApiName),
                        (Id) record.get('Id')
                    ));
                }
                co.color = item.color == null ? DEFAULT_COLOR : item.color;
            } catch (QueryException e) {
                co.error = true;
                co.errorMsg = e.getMessage();
            }
            eventRecords.add(co);
        }

        return eventRecords;
    }


    //  Find the name field for an object.
    //
    //  The parameter represents:
    //      objectApiName:  the API name of the object whose name field is wanted.

    private static String getNameField (String objectApiName) {
        String nameFieldApiName;
        for (Schema.SObjectField field : Schema.describeSObjects(new List<String> {objectApiName})[0].fields.getMap().values()) {
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

    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.ApexSoqlInjection, PMD.ApexCRUDViolation')
    @AuraEnabled
    public static void updateRecord(String objectApiName, String startApiName, String endApiName, DateTime startDate, DateTime endDate, Id recordId) {
        try {
            SObject record = Database.query(
                'SELECT ' + startApiName + ',' + endApiName + ' FROM ' + objectApiName + ' WHERE Id = :recordId'
            );
            record.put(startApiName, startDate);
            record.put(endApiName, endDate);
            update record;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    //  Delete a record from the calendar.
    //
    //  The parameters represent:
    //      objectApiName:  the API name of the object to update.
    //      recordId:  the Id of the record to update.

    @SuppressWarnings('PMD.ApexSoqlInjection, PMD.ApexCRUDViolation')
    @AuraEnabled
    public static void deleteRecord(String objectApiName, Id recordId) {
        try {
            SObject record = Database.query('SELECT Id FROM ' + objectApiName + ' WHERE Id = :recordId');
            delete record;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    //  Create a record with new values from the calendar. Normally, this would be done with a <lightning-record-edit-form>
    //  but as of this writing, this API does not support the Event SObject type.
    //
    //  The parameters represent:
    //      objectApiName:  the API name of the object to create.
    //      startApiName:  the API name of the starting DateTime field.
    //      endApiName:  the API name of the ending DateTime field.
    //      startDate:  the new start date and time.
    //      endDate:  the new end date and time.

    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.ApexCRUDViolation')
    @AuraEnabled
    public static Id createRecord(String objectApiName, String nameFieldApiName, String startApiName, String endApiName, String name, DateTime startDate, DateTime endDate) {
        try {
            SObject record = Schema.getGlobalDescribe().get(objectApiName).newSObject();
            record.put(nameFieldApiName, name);
            record.put(startApiName, startDate);
            record.put(endApiName, endDate);
            insert record;
            return record.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}