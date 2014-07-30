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

#import "MyTableView.h"
#import "Common.h"
#import "AppController.h"
#import "MapDialog.h"
#import "Uty.h"
#import "AppData.h"
#import "MyDropbox.h"
#import "SyncOption.h"

@implementation MyTableView {
    NSMutableArray *_dataArray;
    NSInteger clickedRow;
}

- (id)init
{
    self = [super init];
    if (self) {
        //_Log(@"myTableView init");
        _dataArray = [[NSMutableArray alloc] init];
        self.appData = [[AppData alloc] init];
        self.appData.delegate = self;
        
        self.dropBox = [[MyDropbox alloc] init];
        self.dropBox.delegate = self;
    }
    return self;
}

- (void)loadMapFile
{
    [_dataArray removeAllObjects];
    [self.appData loadMapFile:_dataArray];
    // refresh tableview
    [self.tableView1 reloadData];
}

- (IBAction)buttonNewMapPushed:(id)sender
{
    [self openMapDialog: -1]; // -1 : create new
}

- (IBAction)buttonEditMapPushed:(id)sender
{
    
    NSInteger idx = [self.tableView1 selectedRow];
    [self openMapDialog: idx];
}

// open the modal dialog for the map data
- (void)openMapDialog:(NSInteger)idx
{
    MapDialog *mapDialog = [[MapDialog alloc] initWithWindowNibName:@"MapDialog"];
    mapDialog.delegate = self;
    mapDialog.mapIdxToEdit = idx;
    mapDialog.mapDataArray = _dataArray;
    NSInteger result = [[NSApplication sharedApplication] runModalForWindow:mapDialog.window];
    [mapDialog.window orderOut:self]; // close dialog
    //_Log(@"dialg result=%lu", result);
    [[NSApplication sharedApplication] stopModalWithCode:result];
}

// add or update the map data
- (void)setMapEntry:(NSInteger)idx data:(NSString*)data name:(NSString*)name outLength:(unsigned short)len;
{
    NSNumber *outlenNum = [[NSNumber alloc] initWithUnsignedShort:len];;
    NSNumber *timeNum = [[NSNumber alloc] initWithUnsignedLongLong:time(NULL)];;
    NSData *uuidData;
    NSDictionary *dic;
    
    // set data to the array
    if (idx == -1)  { // -1 = new data
        // get UUID for new record
        uuid_t uuid;
        [[NSUUID UUID] getUUIDBytes:uuid];
        uuidData = [[NSData alloc] initWithBytes:uuid length:sizeof(uuid_t)];
        
        dic = [[NSDictionary alloc] initWithObjectsAndKeys:
               name, KEYSTR_NAME,
               data, KEYSTR_DATA,
               outlenNum, KEYSTR_OUTLEN,
               uuidData, KEYSTR_UUID,
               timeNum, KEYSTR_TIME, nil];
        
        [_dataArray addObject:dic];
        
        // set focus to new entry
        NSInteger rows = [self.tableView1 numberOfRows];
        if (rows > 0) {
            [self.tableView1 selectRowIndexes:[NSIndexSet indexSetWithIndex: rows-1] byExtendingSelection:NO];
        }
        [self.tableView1 setNeedsDisplay];
        
        // add record to local map file
        [self.appData addRecord:dic];
    }
    else { // edited existing data
        // inherit record ID
        NSDictionary *dicOld = [_dataArray objectAtIndex:idx];
        NSData *uuid = [dicOld objectForKey:KEYSTR_UUID];
        uuidData = [uuid copy];
        // replace the record
        dic = [[NSDictionary alloc] initWithObjectsAndKeys:
               name, KEYSTR_NAME,
               data, KEYSTR_DATA,
               outlenNum, KEYSTR_OUTLEN,
               uuidData, KEYSTR_UUID,
               timeNum, KEYSTR_TIME, nil];
        
        [_dataArray replaceObjectAtIndex:idx withObject:dic];
        
        // set updated map data
        [self setMapData:dic];
        
        // update local map file
        [self.appData modifyRecord:dic recordNumber:idx];
    }
    
    // refresh tableview
    [self.tableView1 reloadData];
}

#pragma mark - NSTableView data source

// numberOfRowsInTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return _dataArray.count;
}

// objectValueForTableColumn
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //_Log(@"objectValueForTableColumn row=%ld", row);
    
    if (_dataArray.count <= 0) {
        return nil;
    }
    
    NSDictionary *data = [_dataArray objectAtIndex:row];
    //_Log(@"col=[%@]", [tableColumn identifier] );
    if ([[tableColumn identifier] isEqualToString:@"TITLE"]) {
        return [data objectForKey:KEYSTR_NAME];
    }
    return nil;
}

// a cell is clicked
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    //_Log(@"tableViewSelectionDidChange");
    if (_dataArray.count <= 0) {
        return;
    }
    int row = (int)[self.tableView1 selectedRow];
    // blank column
    if (row == -1) {
        // disable Delete/Edit button
        [self.buttonDeleteMap setEnabled:NO];
        [self.buttonEditMap setEnabled:NO];
        // non-selected state
        [self setMapData:nil];
        return;
    }
    // enable Delete/Edit button
    [self.buttonDeleteMap setEnabled:YES];
    [self.buttonEditMap setEnabled:YES];
    
    NSDictionary *data = [_dataArray objectAtIndex:row];
    
    // set selected map data
    [self setMapData:data];
}

// finished editing the cell
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
    //_Log(@"setObjectValue: obj=%@ row=%ld", anObject, row);
    NSString *newName = anObject;
    NSDictionary *data = [_dataArray objectAtIndex:row];
    NSString *oldName = [data objectForKey:KEYSTR_NAME];
    
    // (this method is not called if the cell data is not changed
    if ([newName isEqualToString:oldName]) {
        return;
    }
    
    // update the time of the record
    NSNumber *timeNum = [[NSNumber alloc] initWithUnsignedLongLong:time(NULL)];
    
    NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                         newName, KEYSTR_NAME,
                         [data objectForKey:KEYSTR_DATA], KEYSTR_DATA,
                         [data objectForKey:KEYSTR_OUTLEN], KEYSTR_OUTLEN,
                         [data objectForKey:KEYSTR_UUID], KEYSTR_UUID,
                         timeNum, KEYSTR_TIME, nil];
    
    // replace the record
    [_dataArray replaceObjectAtIndex:row withObject: dic];
    // refresh tableview
    [self.tableView1 reloadData];
    
    // update local map file
    [self.appData modifyRecord:dic recordNumber:row];
    
}

#pragma mark

// popup menu - Delete
- (IBAction)menuItemDeleteSelected:(id)sender
{
    if (clickedRow > -1) {
        [self queryDeleteEntry];
    }
}

// popup menu - Rename
- (IBAction)menuItemRenameSelected:(id)sender
{
    if (clickedRow > -1) {
        [self.tableView1 editColumn:0 row:clickedRow withEvent:nil select:YES];
    }
}

// popup menu - Edit
- (IBAction)menuItemEditSelected:(id)sender
{
    if (clickedRow > -1) {
        [self openMapDialog: clickedRow];
    }
}

// right-clicked the mouse
- (void)menuNeedsUpdate:(NSMenu *)menu
{
    clickedRow = [self.tableView1 clickedRow];
    //NSInteger clickedcol = [self.tableView1 clickedColumn];
    //_Log(@"row=%ld", clickedRow);
    
    if (clickedRow > -1) {
        // set focus to clicked cell
        [self.tableView1 selectRowIndexes:[NSIndexSet indexSetWithIndex: clickedRow] byExtendingSelection:NO];
    }
}

// delete map record
- (void)deleteMapEntry:(NSInteger)row
{
    NSInteger counts = _dataArray.count;
    //NSInteger row = [self.tableView1 selectedRow];
    if (counts <=0 || row == -1) {
        return;
    }
    
    // the last column
    if (row == counts - 1) {
        //NSInteger rows = [self.tableView1 numberOfRows];
        if (counts >= 2) {
            [self.tableView1 selectRowIndexes:[NSIndexSet indexSetWithIndex: counts-2] byExtendingSelection:NO];
        }
        [self.tableView1 setNeedsDisplay];
    }
    
    // remove the entry from tableview
    [_dataArray removeObjectAtIndex:row];
    if (_dataArray.count > 0) {
        // refresh view
        [self.tableView1 reloadData];
        // newly selected map
        NSInteger curRow = [self.tableView1 selectedRow];
        NSDictionary *data = [_dataArray objectAtIndex:curRow];
        [self setMapData:data];
        
    } else {
        // enable Delete/Edit button
        [self.buttonDeleteMap setEnabled:NO];
        [self.buttonEditMap setEnabled:NO];
        // non-selected state
        [self setMapData:nil];
    }
    // remove the entry from local map file
    [self.appData modifyRecord:nil recordNumber:row];
}

- (void)fileIOStartOrFinish:(BOOL)StartOrFinish doReload:(BOOL)doReload doUpload:(BOOL)doUpload
{
    //_Log(@"myTableview fileIOStartOrFinish");
    
    if (StartOrFinish == NO && doReload) {
        // reload local map file
        [self loadMapFile];
    }
    if (!doUpload) {
        [self setControlsEnabled:!StartOrFinish];
    } else {
        // upload local map file to Dropbox
        [self.dropBox uploadFile:DATA_NAME_REMOTE localFileFullPath:[self.appData localMapFileFullPath]];
    }
}

- (IBAction)buttonDeleteMapPushed:(id)sender
{
    [self queryDeleteEntry];
}

- (void)queryDeleteEntry
{
    // "The currently selected map data will be deleted..."
    NSAlert *alert = [ NSAlert alertWithMessageText : TEXT(@"MsgDeleteRecord")
                                      defaultButton : TEXT(@"WordOK")
                                    alternateButton : TEXT(@"WordCancel")
                                        otherButton : nil
                          informativeTextWithFormat : @"%@", TEXT(@"QueryDeleteRecord")];
	
    [alert beginSheetModalForWindow:[[NSApp delegate] mainWindow]
                      modalDelegate:self
                     didEndSelector:@selector(unlinkAlertDone:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void) unlinkAlertDone:(NSAlert *)alert
              returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn) {
        [self deleteMapEntry:[self.tableView1 selectedRow]];
    }
}

// "Sync with Dropbox" button
- (IBAction)buttonSyncDropboxPushed:(id)sender {
    // try to download remote map file from Dropbox
    [self setControlsEnabled:NO];
    [self.dropBox downLoadFile:DATA_NAME_REMOTE localFileFullPath:[self.appData localDropboxTempMapFileFullPath]];
}

- (void)delegateResult:(NSInteger)state
                  arg1:(id)arg1
                  arg2:(id)arg2
                  arg3:(id)arg3
                  arg4:(NSInteger)arg4
                 error:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(appNotified:arg1:arg2:arg3:arg4:error:)]) {
        [self.delegate appNotified:state arg1:arg1 arg2:arg2 arg3:arg3 arg4:arg4 error:error];
    } else {
        NSLog(@"myTableview appNotified failed");
    }
    
}

- (void)dropboxState:(NSInteger)state
                arg1:(id)arg1
                arg2:(id)arg2
                arg3:(id)arg3
               error:(NSError*)error
{
    //_Log(@"myTableview dropboxState");
    
    switch (state) {
        case MyDropbox_LINKED:
        case MyDropbox_UNLINKED:
            [self setControlsEnabled:YES];
            [self delegateResult:state arg1:arg1 arg2:arg2 arg3:arg3 arg4:-1 error:error];
        break;

        // download OK
        case MyDropbox_FILE_LOADED:
        {
            NSString *localPath = arg1;
            // downloaded as local map file
            if ([localPath isEqualToString:[self.appData localMapFileFullPath]]) {
                [self loadLocalMapFile];
            }
            // downloaded for synchronization
            else if ([localPath isEqualTo:[self.appData localDropboxTempMapFileFullPath]]) {
                [self setControlsEnabled:NO];
                // check if it matches with the local map file
                if ([self.appData mapFilesAreIdentical:localPath]) {
                    unlink([localPath UTF8String]);
                    [self setControlsEnabled:YES];
                    [self delegateResult:APP_ALREADY_SYNCED arg1:nil arg2:nil arg3:nil arg4:-1 error:nil];
                    return;
                }
                // query options to merge records
                [self querySyncMethod];
            }
        }
        break;

        // download NG
        case MyDropbox_FILE_LOAD_ERROR:
        {
            NSString *localPath = arg1;
            //_Log(@"file load err=%ld local=%@", (long)error.code, localPath);
            
            // failed to download as local map file
            if ([localPath isEqualToString:[self.appData localMapFileFullPath]]) {
                [self loadLocalMapFile];
            }
            // failed to download for synchronization
            else if ([localPath isEqualTo:[self.appData localDropboxTempMapFileFullPath]]) {
                if (error.code == 404) { // not found
                    NSString *localMapFile = [self.appData localMapFileFullPath];
                    if (![Uty fileIsExist:localMapFile]) {
                        // create 0 byte file
                        FILE *fp = fopen([localMapFile UTF8String], "w");
                        (fp) ? fclose(fp) : 1;
                    }
                    if ([Uty fileIsExist:localMapFile]) {
                        // upload local map file to Dropbox
                        [self.dropBox uploadFile:DATA_NAME_REMOTE localFileFullPath:localMapFile];
                    }
                    return;
                } else { // other error
                    [self setControlsEnabled:YES];
                    [self delegateResult:state arg1:nil arg2:nil arg3:nil arg4:-1 error:error];
                }
            }
        }
        break;

        // upload OK
        case MyDropbox_FILE_UPLOADED:
        {
            NSString *dstPath = arg1;
            //NSString *srcPath = arg2;
            //_Log(@"file uploaded [%@]<-[%@]", dstPath, srcPath);
            if ([dstPath isEqualToString:DATA_NAME_REMOTE]) {
                [self setControlsEnabled:YES];
                [self delegateResult:state arg1:arg1 arg2:arg2 arg3:arg3 arg4:-1 error:error];
                unlink([[self.appData localDropboxTempMapFileFullPath] UTF8String]);
            }
        }
        break;

        // upload NG
        case MyDropbox_FILE_UPLOAD_ERROR:
        {
            NSString *dstPath = arg1;
            //NSString *srcPath = arg2;
            //_Log(@"file upload load err=%ld [%@]<-[%@]", (long)error.code, dstPath, srcPath);
            if ([dstPath isEqualToString:DATA_NAME_REMOTE]) {
                [self setControlsEnabled:YES];
                [self delegateResult:state arg1:arg1 arg2:arg2 arg3:arg3 arg4:-1 error:error];
            }
        }
        break;
    }
}

- (void)setMapData:(NSDictionary*)dataDic
{
    [self delegateResult:APP_SET_MAPDATA arg1:dataDic arg2:nil arg3:nil arg4:-1 error:nil];
}

- (void)setControlsEnabled:(BOOL)YESorNo
{
    NSInteger val = (YESorNo) ? 1 : 0;
    [self delegateResult:APP_SET_CONTROLS_ENABLED arg1:nil arg2:nil arg3:nil arg4:val error:nil];
}

- (void)loadLocalMapFile
{
    if (![self.appData localMapFileExists]) {
        // cut out the sample map file if the local file does not exist
        [self.appData copySampleMapData];
    }
    // load local map file
    [self loadMapFile];
}

// query options to merge records
- (void)querySyncMethod
{
    // open modal dialog
    SyncOption *dlg = [[SyncOption alloc] initWithWindowNibName:@"SyncOption"];
    NSInteger result = [[NSApplication sharedApplication] runModalForWindow:dlg.window];
    [dlg.window orderOut:self]; // close dialog
    //_Log(@"dialg result=%lu", result);
    [[NSApplication sharedApplication] stopModalWithCode:result];
    
    NSString *downloadedRemoteFile = [self.appData localDropboxTempMapFileFullPath];
    if (result == 0) { // cancel
        [self setControlsEnabled:YES];
        unlink([downloadedRemoteFile UTF8String]);
        return;
    }
    // options
    BOOL keepOldRecord = NO;
    BOOL keepForeignRecord = NO;
    if (result & SYNC_OPT_KEEP_OLD_RECORD) {
        keepOldRecord = YES;
    }
    if (result & SYNC_OPT_KEEP_FOREIGN_RECORD) {
        keepForeignRecord = YES;
    }
    // merge records
    [self.appData mergeMapFiles:downloadedRemoteFile
                  keepOldRecord:keepOldRecord
              keepForeignRecord:keepForeignRecord];
}

/*
 - (id)getAppController {
    id delegate = [NSApp delegate];
    return [delegate appController];
 }
 */

@end
