//  Apex data source for the Lightning Enhanced Calendar LWC default duration view.
//
//  Copyright (c) 2023, salesforce.com, inc.
//  All rights reserved.
//  SPDX-License-Identifier: BSD-3-Clause
//  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
//
//  Contact: john.meyer@salesforce.com

public with sharing class LightningEnhancedCalendarDurationView extends VisualEditor.DynamicPickList {

    private VisualEditor.DynamicPickListRows calendarViews = new VisualEditor.DynamicPickListRows(
        new List<VisualEditor.DataRow> {
            new VisualEditor.DataRow('Day View', 'day'),
            new VisualEditor.DataRow('Week View', 'week'),
            new VisualEditor.DataRow('Month View', 'month'),
            new VisualEditor.DataRow('Year View', 'year')
        },
        true
    );
    
    public override VisualEditor.DataRow getDefaultValue () {
        return this.calendarViews.get(1);
    }
    
    public override VisualEditor.DynamicPickListRows getValues () {               
        return this.calendarViews;
    }
}