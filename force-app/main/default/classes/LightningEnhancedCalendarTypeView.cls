//  Apex data source for the Lightning Enhanced Calendar LWC default type view.
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