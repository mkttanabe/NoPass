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

enum {
    MyDropbox_LINKED = 0,
    MyDropbox_UNLINKED,
    MyDropbox_REVISION_LOADED,
    MyDropbox_REVISION_LOAD_ERROR,
    MyDropbox_FILE_LOADED,
    MyDropbox_FILE_LOAD_ERROR,
    MyDropbox_FILE_UPLOADED,
    MyDropbox_FILE_UPLOAD_ERROR,
    
};

@protocol MyDropboxDelegate
- (void)dropboxState:(NSInteger)state
                arg1:(id)arg1
                arg2:(id)arg2
                arg3:(id)arg3
               error:(NSError*)error;
@end

@interface MyDropbox : NSObject

@property (nonatomic, weak) id delegate;

- (BOOL)isLinked;
- (void)startOAuth;
- (void)unLink;
- (void)queryDropboxUnlink:(id)window;
- (void)loadRevisionsForFile:(NSString*)targetFileFullPath;
- (void)uploadFile:(NSString*)_remoteFileFullPath localFileFullPath:(NSString*)_localFileFullPath;
- (void)downLoadFile:(NSString*)_remoteFileFullPath localFileFullPath:(NSString*)_localFileFullPath;

@end
