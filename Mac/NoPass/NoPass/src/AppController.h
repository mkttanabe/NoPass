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

@class MyTableView;
@class MyTextView;

enum {
    APP_ALREADY_SYNCED = 1000,
    APP_SET_CONTROLS_ENABLED,
    APP_SET_MAPDATA,
    APP_SET_OUTTEXTTDATA
};

@interface AppController : NSObject

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *menuPopup;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenuItem *menuUseDropbox;
@property (unsafe_unretained) IBOutlet MyTextView *keyTextView;
@property (weak) IBOutlet MyTableView *myTableView;
@property (weak) IBOutlet NSButton *buttonExit;
@property (weak) IBOutlet NSTextField *dataTextField;
@property (weak) IBOutlet NSButton *buttonCopyBoard;
@property (weak) IBOutlet NSStepper *stepper1;
@property (weak) IBOutlet NSTextField *dataLength;
@property (weak) IBOutlet NSTableView *tableView1;

- (IBAction)buttonExitPushed:(id)sender;
- (IBAction)buttonClearPushed:(id)sender;
- (IBAction)buttonCopyBoardPushed:(id)sender;
- (IBAction)buttonClearBoardPushed:(id)sender;
- (IBAction)stepper1Changed:(id)sender;
- (IBAction)menuUseDropboxSelected:(id)sender;

@end





