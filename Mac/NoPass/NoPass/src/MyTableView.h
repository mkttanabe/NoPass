/*
 * Copyright (C) 2014 KLab Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

@class AppData;
@class MyDropbox;

@protocol MyTableViewDelegate
- (void)appNotified:(NSInteger)state
            arg1:(id)arg1
            arg2:(id)arg2
            arg3:(id)arg3
            arg4:(NSInteger)arg4
           error:(NSError*)error;
@end

@interface MyTableView : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>

- (void)loadLocalMapFile;

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) MyDropbox *dropBox;
@property (nonatomic, strong) AppData *appData;

@property (weak) IBOutlet NSTableView *tableView1;
@property (weak) IBOutlet NSMenu *menuPopup;
@property (weak) IBOutlet NSButton *buttonNewMap;
@property (weak) IBOutlet NSButton *buttonEditMap;
@property (weak) IBOutlet NSButton *buttonDeleteMap;
@property (weak) IBOutlet NSButton *buttonSyncDropbox;
@property (weak) IBOutlet NSMenuItem *menuItemDelete;
@property (weak) IBOutlet NSMenuItem *menuItemRename;
@property (weak) IBOutlet NSMenuItem *menuItemEdit;

- (IBAction)buttonNewMapPushed:(id)sender;
- (IBAction)buttonEditMapPushed:(id)sender;
- (IBAction)buttonDeleteMapPushed:(id)sender;
- (IBAction)buttonSyncDropboxPushed:(id)sender;
- (IBAction)menuItemDeleteSelected:(id)sender;
- (IBAction)menuItemRenameSelected:(id)sender;
- (IBAction)menuItemEditSelected:(id)sender;


@end


