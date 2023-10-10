/**
 *  Apex controller for the Lightning Enhanced Calendar LWC.
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

public with sharing class LightningEnhancedCalendar {

    private static final String DEFAULT_COLOR = '#3A87AD';
    @testVisible private final static Integer TEST_MAXIMUM_ROWS = 10;

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
            this.color = DEFAULT_COLOR;
            this.error = false;
            this.errorMsg = null;
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


    /**
     * Retrieves the list of objects along with their event entries to display on the calendar.
     *
     * @param objectsString  A JSON string that will be deserialized into a list of ObjectListItem objects. Each item must contain:
     * @param recordId       (optional) The Id of a parent record used in an (optional) filter if used on a record page.
     * @return               The list of objects with entries to display on the calendar.
     * @throws AuraHandledException If the object string is bad or if there are too many objects or too many calendar entry records
     */

    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    @AuraEnabled(cacheable=true)
    public static List<CalendarObject> getEvents (String objectsString, Id recordId) {

        List<ObjectListItem> objects;
        Integer rowsLeft = System.Test.isRunningTest() ? TEST_MAXIMUM_ROWS : Limits.getLimitQueryRows();

        //  Decode the objects string that was passed in from Lightning App Builder and make sure we don't exceed the governor
        //  limits (we must do a SOQL query for each object). Unlikely, but let's be sure.
        try {
            objects = (List<ObjectListItem>) JSON.deserialize(objectsString, List<ObjectListItem>.class);
            if (objects.size() > Limits.getLimitQueries()) {
                throw new AuraHandledException(System.Label.LEC_Too_Many_Objects + ' ' + Limits.getLimitQueries());
            }    
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.LEC_Bad_Objects_String);
        }

        //  Cycle through each object that was given, and grab the "event" entries for each one. Again, take some pains to make sure
        //  we don't exceed governor limits on the total number of query rows returned and gracefully check for badly formed queries
        //  that can result from corrupted filters, for example.
        List<CalendarObject> eventRecords = new List<CalendarObject>();
        for (ObjectListItem item : objects) {
            CalendarObject calObject = new CalendarObject(item.objectApiName, item.customLabel, item.nameFieldApiName, item.startApiName, item.endApiName);
            try {
                if (rowsLeft <= 0) {
                    throw new AuraHandledException(System.Label.LEC_Too_Many_Records + ' ' + Limits.getLimitQueryRows());
                }
                for (List<SObject> records : Database.query(
                    String.escapeSingleQuotes('SELECT ' + calObject.nameFieldApiName + ',' + item.startApiName + ',' + item.endApiName + ' FROM ' + item.objectApiName) +
                        (item.filter == null ? '' : ' WHERE (' + item.filter + ')') +
                        ' LIMIT :rowsLeft'
                    )) {
                    for (SObject record : records) {
                        calObject.events.add(new CalendarEntry(
                            item.objectApiName,
                            (String) record.get(calObject.nameFieldApiName),
                            (DateTime) record.get(item.startApiName),
                            (DateTime) record.get(item.endApiName),
                            (Id) record.get('Id')
                        ));
                    }
                    rowsLeft -= records.size();
                }
                calObject.color = item.color == null ? DEFAULT_COLOR : item.color;
            } catch (QueryException e) {
                calObject.error = true;
                calObject.errorMsg = e.getMessage();
            }
            eventRecords.add(calObject);
        }

        return eventRecords;
    }


    /**
     * Returns the API name for the name field of the object.
     *
     * @param fields    A list of SObjectFields to interrogate.
     * @return          The API name for the name field of the object.
     */

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


    /**
     * Updates a record with new values from the calendar; normally, this would be done with a <lightning-record-edit-form>
     * but as of this writing, this API does not support the Event SObject type.
     *
     * @param objectApiName The API name of the object to update.
     * @param startApiName  The API name of the starting DateTime field.
     * @param endApiName    The API name of the ending DateTime field.
     * @param startDate     The new start date and time.
     * @param endDate       The new end date and time.
     * @param recordId      The Id of the record to update.
     * @throws AuraHandledException If the update fails.
     */

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


    /**
     * Deletes a record from the calendar.
     *
     * @param objectApiName The API name of the object.
     * @param recordId      The Id of the record to delete.
     */

    @AuraEnabled
    public static void deleteRecord(String objectApiName, Id recordId) {
        delete as user Database.query(String.escapeSingleQuotes('SELECT Id FROM ' + objectApiName + ' WHERE Id = :recordId'));
    }

}