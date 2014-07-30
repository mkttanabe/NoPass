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

#import "MyDropbox.h"
#import "Common.h"
#import "DropboxAPI.h"
#import "Uty.h"

@implementation MyDropbox {
    DropboxAPI *dropBoxAPI;
    BOOL doUpload;
    NSString *rev;
    NSString *localFileFullPath;
    NSString *remoteFileFullPath;
}

- (id)init
{
    self = [super init];
    if (self) {
        //_Log(@"myDropbox init");
        doUpload = NO;
        dropBoxAPI = [[DropboxAPI alloc] init];
        dropBoxAPI.delegate = self;
        NSInteger sts = [dropBoxAPI setUp];
        if (sts == 1) {
        }
    }
    return self;
}

// Dropbox link state
- (BOOL)isLinked
{
    return [dropBoxAPI isLinked];
}

// start OAuth authentication
- (void)startOAuth
{
    return [dropBoxAPI startOAuth];
}

// load revision information of the remote file
- (void)loadRevisionsForFile:(NSString*)targetFileFullPath
{
    remoteFileFullPath = targetFileFullPath;
    [dropBoxAPI loadRevisionsForFile:targetFileFullPath];
}

// upload fils
- (void)uploadFile:(NSString*)_remoteFileFullPath localFileFullPath:(NSString*)_localFileFullPath
{
    //_Log(@"myDropbox uploadFile");
    doUpload = YES;
    localFileFullPath = _localFileFullPath;
    remoteFileFullPath = _remoteFileFullPath;
    [dropBoxAPI loadRevisionsForFile:_remoteFileFullPath];
}

// download file
- (void)downLoadFile:(NSString*)_remoteFileFullPath localFileFullPath:(NSString*)_localFileFullPath
{
    remoteFileFullPath = _remoteFileFullPath;
    localFileFullPath = _localFileFullPath;
    [dropBoxAPI loadFile:_remoteFileFullPath localFileFullPath:_localFileFullPath];
}

// unlink Dropbox
- (void)unLink
{
    return [dropBoxAPI unLink];
}

// query unlink Dropbox
- (void)queryDropboxUnlink:(id)window
{
    // "If you unlink Dropbox you will be prompted to relink. Continue?"
    NSAlert *alert = [ NSAlert alertWithMessageText : TEXT(@"MsgUnlinkDropbox")
                                      defaultButton : TEXT(@"WordOK")
                                    alternateButton : TEXT(@"WordCancel")
                                        otherButton : nil
                          informativeTextWithFormat : @"%@", TEXT(@"QueryUnlinkDropbox")];
    [alert beginSheetModalForWindow:window
                      modalDelegate:self
                     didEndSelector:@selector(unlinkAlertDone:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void) unlinkAlertDone:(NSAlert *)alert
              returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn) {
        [self unLink];
    }
    else if(returnCode == NSAlertAlternateReturn) {
    }
    else if(returnCode == NSAlertOtherReturn) {
    }
    else if(returnCode == NSAlertErrorReturn) {
    }
}

#pragma mark - Events

// Dropbox link state is changed
- (void)sessionStateChanged:(BOOL)isLinked
{
    if (isLinked) {
        [self delegateResult:MyDropbox_LINKED arg1:nil arg2:nil arg3:nil error:nil];
    } else {
        [self delegateResult:MyDropbox_UNLINKED arg1:nil arg2:nil arg3:nil error:nil];
    }
}

// loadRevisionsForFile finished
- (void)loadRevisionsForFileDone:(BOOL)sts
                        revsions:(NSArray*)revisions
                         forFile:(NSString*)path
                           error:(NSError*)error
{
    //_Log(@"MyDropBox loadRevisionsForFileDone: sts=%d", sts);

    // if called to overwrite remote file
    if (doUpload) {
        doUpload = NO;
        rev = nil;
        if (sts) {
            DBMetadata *meta = revisions[0];
            rev = meta.rev;
        }
        // just call upload method and return
        [dropBoxAPI uploadFile:remoteFileFullPath
                 withParentRev:rev
               localFileFullPath:localFileFullPath];
        return;
    }
    
    if (sts) {
        [self delegateResult:MyDropbox_REVISION_LOADED
                        arg1:revisions
                        arg2:path
                        arg3:nil
                       error:nil];
    } else {
        [self delegateResult:MyDropbox_REVISION_LOAD_ERROR
                        arg1:nil
                        arg2:remoteFileFullPath // echo back manually
                        arg3:nil
                       error:error];
    }
}

// loadFile finished
- (void)loadFileDone:(BOOL)sts
          loadedFile:(NSString *)localPath
         contentType:(NSString*)contentType
            metadata:(DBMetadata *)metadata
               error:(NSError*)error
{
    if (sts) {
        [self delegateResult:MyDropbox_FILE_LOADED
                        arg1:localPath
                        arg2:contentType
                        arg3:metadata
                       error:nil];
    } else {
        [self delegateResult:MyDropbox_FILE_LOAD_ERROR
                        arg1:localFileFullPath // echo back manually
                        arg2:nil
                        arg3:nil
                       error:error];
    }
}

// uploadFile finished
- (void)uploadFileDone:(BOOL)sts
      uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath
          metadata:(DBMetadata *)metadata
             error:(NSError*)error
{
    if (sts) {
        [self delegateResult:MyDropbox_FILE_UPLOADED
                        arg1:destPath
                        arg2:srcPath
                        arg3:metadata
                       error:nil];
    } else {
        [self delegateResult:MyDropbox_FILE_UPLOAD_ERROR
                        arg1:remoteFileFullPath // echo back manually
                        arg2:localFileFullPath
                        arg3:nil
                       error:error];
    }
}

// notify the result of processing
- (void)delegateResult:(NSInteger)state
                  arg1:(id)arg1
                  arg2:(id)arg2
                  arg3:(id)arg3
                 error:(NSError*)error
{
    //_Log(@"MyDropbox nofityToApp");
    if ([self.delegate respondsToSelector:@selector(dropboxState:arg1:arg2:arg3:error:)]) {
        [self.delegate dropboxState:state arg1:arg1 arg2:arg2 arg3:arg3 error:error];
    } else {
        NSLog(@"MyDropbox notifyToApp failed");
    }
}

@end
