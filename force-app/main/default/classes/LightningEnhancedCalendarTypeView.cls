//  Apex data source for the Lightning Enhanced Calendar LWC default type view.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

public with sharing class LightningEnhancedCalendarTypeView extends VisualEditor.DynamicPickList {

    private VisualEditor.DynamicPickListRows calendarViews = new VisualEditor.DynamicPickListRows(
        new List<VisualEditor.DataRow> {
            new VisualEditor.DataRow('Calendar View', 'calendar'),
            new VisualEditor.DataRow('List View', 'list'),
            new VisualEditor.DataRow('Timeline View', 'timeline')
        },
        true
    );
    
    public override VisualEditor.DataRow getDefaultValue () {
        return this.calendarViews.get(0);
    }
    
    public override VisualEditor.DynamicPickListRows getValues () {               
        return this.calendarViews;
    }
}