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

#import <Cocoa/Cocoa.h>

#define SYNC_STARTFLAG               0x10000000
#define SYNC_OPT_KEEP_OLD_RECORD     0x00000001
#define SYNC_OPT_KEEP_FOREIGN_RECORD 0x00000100

@interface SyncOption : NSWindowController

@property (weak) IBOutlet NSMatrix *radioOldRecord;
@property (weak) IBOutlet NSMatrix *radioForeignRecord;

- (IBAction)buttonCancelPushed:(id)sender;
- (IBAction)buttonStartPushed:(id)sender;

@end


