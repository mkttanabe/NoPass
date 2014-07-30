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
#import <DropboxOSX/DropboxOSX.h>

@protocol DropboxAPIDelegate
- (void)sessionStateChanged:(BOOL)isLinked;

- (void)loadRevisionsForFileDone:(BOOL)sts
                        revsions:(NSArray*)revsions
                         forFile:(NSString*)path
                           error:(NSError*)error;

- (void)loadFileDone:(BOOL)sts
          loadedFile:(NSString *)localPath
         contentType:(NSString*)contentType
            metadata:(DBMetadata *)metadata
               error:(NSError*)error;


- (void)uploadFileDone:(BOOL)sts
      uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath
          metadata:(DBMetadata *)metadata
             error:(NSError*)error;
@end

@interface DropboxAPI : NSObject <DBRestClientDelegate, DBSessionDelegate>

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) DBRestClient *restClient;

- (NSInteger)setUp;
- (BOOL)isLinked;
- (void)startOAuth;
- (void)unLink;
//- (void)overWriteFile:(NSString*)fileName dir:(NSString *)path src:(NSString*)localFileName;
- (void)loadRevisionsForFile:(NSString*)path;
- (void)uploadFile:(NSString*)remoteFileFullPath withParentRev:(NSString*)rev localFileFullPath:(NSString*)localFileFullPath;
- (void)loadFile:(NSString*)remoteFileFullPath localFileFullPath:(NSString*)localFileFullPath;

@end


