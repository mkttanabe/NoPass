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

#import "AppController.h"
#import "Common.h"
#import "AppDelegate.h"
#import "MyTableView.h"
#import "MyTextView.h"
#import "MyDropbox.h"
#import "AppData.h"
#import "Uty.h"

@implementation AppController

- (id)init
{
    self = [super init];
    if (self) {
        //_Log(@"app init");
    }
    return self;
}

- (void)awakeFromNib
{
    //_Log(@"app awakeFromNib");
    
    // get AppDeletege object
    id delegate = [NSApp delegate];
    [delegate setAppController:self];
    [delegate setMainWindow:self.window];
    
    self.myTableView.delegate = self;
    self.keyTextView.delegate = self;
    
    // set this window as always on top
    [self.window setLevel:NSModalPanelWindowLevel];
    
    // initialize stepper control
    NSInteger outTextLength = [self.stepper1 integerValue];
    if (outTextLength > 3) {
        [self.dataLength setIntegerValue:outTextLength];
    } else {
        [self.dataLength setStringValue:TEXT(@"WordFree")];
    }
    [self.keyTextView setOutDataLength:outTextLength];
    
    // initialize status item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setImage:[NSImage imageNamed:@"NoPassStatus"]];
    [self.statusItem setMenu:self.menuPopup];
    
    // Dropbox link state
    if ([self.myTableView.dropBox isLinked]) {
        [self.menuUseDropbox setState:NSOnState];
        [[self.myTableView buttonSyncDropbox] setEnabled:YES];
    } else {
        [self.menuUseDropbox setState:NSOffState];
        [[self.myTableView buttonSyncDropbox] setEnabled:NO];
    }
    
    // load local map file
    [self.myTableView loadLocalMapFile];
}

// got notification
- (void)appNotified:(NSInteger)state
                arg1:(id)arg1
                arg2:(id)arg2
                arg3:(id)arg3
                arg4:(NSInteger)arg4
               error:(NSError*)error
{
    NSString *msg;
    
    //_Log(@"app appNotified: state=%ld", (long)state);

    switch(state) {
    case MyDropbox_LINKED:
        // check menu item
        [self.menuUseDropbox setState:NSOnState];
        [[self.myTableView buttonSyncDropbox] setEnabled:YES];
         // "Linked to Dropbox successfully."
        msg = TEXT(@"MsgLinkedDropbox");
        [Uty msgBox:msg];
        break;

    case MyDropbox_UNLINKED:
        // uncheck menu item
        [self.menuUseDropbox setState:NSOffState];
        [[self.myTableView buttonSyncDropbox] setEnabled:NO];
        // "Unlinked Dropbox."
        msg = TEXT(@"MsgUnlinkedDropbox");
        [Uty msgBox:msg];
        break;

    case MyDropbox_FILE_UPLOADED:
        {
            NSString *dstPath = arg1;
            NSString *srcPath = arg2;
            if ([dstPath isEqualToString:DATA_NAME_REMOTE] &&
                [srcPath isEqualToString:[self.myTableView.appData localMapFileFullPath]]) {
                // "Merged map file was uploaded to Dropbox"
                msg = TEXT(@"MsgSynced");
            } else {
                // "The file was uploaded to Dropbox"
                msg = TEXT(@"MsgUploaded");
            }
        }
        [Uty msgBox2:msg ownerWindow:self.window];
        break;

    case MyDropbox_FILE_UPLOAD_ERROR:
        // "Failed to upload file to Dropbox."
        msg = TEXT(@"MsgUploadError");
        [Uty msgBox2:msg ownerWindow:self.window];
        break;

    case MyDropbox_FILE_LOAD_ERROR:
        // "Failed to download file from Dropbox."
        msg = TEXT(@"MsgDownloadError");
        [Uty msgBox2:msg ownerWindow:self.window];
        break;
            
    case APP_ALREADY_SYNCED:
        // "The remote map file in Dropbox is identical to the local map file."
        msg = TEXT(@"MsgAlreadySynced");
        [Uty msgBox2:msg ownerWindow:self.window];
        break;
            
    case APP_SET_CONTROLS_ENABLED:
        if (arg4) {
            [self setControlsEnabled:YES];
        } else {
            [self setControlsEnabled:NO];
        }
        break;
            
    case APP_SET_MAPDATA:
        {
            NSDictionary *dic = arg1;
            NSString *mapStr = nil;
            NSInteger outlen = -1;
            if (dic != nil) {
                mapStr = [dic objectForKey:KEYSTR_DATA];
                NSNumber *number = [dic objectForKey:KEYSTR_OUTLEN];
                outlen = [number integerValue];
            }
            if (outlen != -1) {
                [self stepper1SetValue:outlen];
            }
            [self.keyTextView setMapData:mapStr];
        }
        break;

    case APP_SET_OUTTEXTTDATA:
        [self setOutDataFiledString:arg1];
        break;
    }
}

- (IBAction)menuUseDropboxSelected:(id)sender
{
    if ([sender state] == NSOnState) {
        [self.myTableView.dropBox queryDropboxUnlink:self.window];
    } else {
        [self.myTableView.dropBox startOAuth];
    }
}

- (IBAction)buttonExitPushed:(id)sender {
    ////exit(0);
    //[NSApp terminate:self]; // to call applicationWillTerminate()
    [self.window close];
}

- (IBAction)buttonClearPushed:(id)sender {
    // clear input/output fields
    [self.keyTextView setString:@""];
    [self setOutDataFiledString:@""];
}

- (IBAction)buttonCopyBoardPushed:(id)sender {
    [Uty SetPasteBoardText:[self.dataTextField stringValue]];
}

- (IBAction)buttonClearBoardPushed:(id)sender {
    [Uty SetPasteBoardText:@""];
}

- (IBAction)stepper1Changed:(id)sender
{
    NSInteger val = (int)[sender integerValue];
    [self stepper1SetValue:val];
}

// set string to output field
- (void)setOutDataFiledString:(NSString*)str;
{
    [self.dataTextField setStringValue:str];
    if (str.length > 0) {
        [self.buttonCopyBoard setEnabled:YES];
    } else {
        [self.buttonCopyBoard setEnabled:NO];
    }
}

// set the length of output string
- (void)stepper1SetValue:(NSInteger)val
{
    [self.stepper1 setIntegerValue: val];

    if (val != OUTDATA_LENGTH_FREE) {
        [self.dataLength setIntegerValue:val];
    } else {
        [self.dataLength setStringValue:TEXT(@"WordFree")];
    }
    [self.keyTextView setOutDataLength:val];
}

// enable/disable controls
- (void)setControlsEnabled:(BOOL)YESorNo
{
    //_Log(@"app setControlsEnabled arg=%d", YESorNo);
    if (YESorNo == YES) {
        [self.window setTitle:APP_NAME];
    } else {
        [self.window setTitle:TEXT(@"MsgPleaseWait")];
    }
    [[self.myTableView buttonNewMap] setEnabled:YESorNo];
    [[self.myTableView buttonDeleteMap] setEnabled:YESorNo];
    [[self.myTableView buttonEditMap] setEnabled:YESorNo];
    if ([self.myTableView.dropBox isLinked]) {
        [[self.myTableView buttonSyncDropbox] setEnabled:YESorNo];
    }
    [self.tableView1 setEnabled:YESorNo];
    [self.buttonExit setEnabled:YESorNo];
    [self.statusItem setEnabled:YESorNo];
}

@end
