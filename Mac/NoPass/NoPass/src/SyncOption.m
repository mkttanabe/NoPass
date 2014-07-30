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

#import "SyncOption.h"
#import "Common.h"

@interface SyncOption ()
@end

@implementation SyncOption

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self.radioOldRecord.cells[0] setTag:SYNC_OPT_KEEP_OLD_RECORD];
    [self.radioOldRecord.cells[1] setTag:0];
    [self.radioForeignRecord.cells[0] setTag:SYNC_OPT_KEEP_FOREIGN_RECORD];
    [self.radioForeignRecord.cells[1] setTag:0];
    
}

- (IBAction)buttonCancelPushed:(id)sender {
    [[NSApplication sharedApplication] stopModalWithCode:0];
}

- (IBAction)buttonStartPushed:(id)sender {
    NSInteger sts = SYNC_STARTFLAG |
                    [[self.radioOldRecord selectedCell] tag] |
                    [[self.radioForeignRecord selectedCell] tag];
    
    [[NSApplication sharedApplication] stopModalWithCode:sts];
}
@end
