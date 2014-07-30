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

#import <DropboxOSX/DropboxOSX.h>
#import "DropboxAPI.h"
#import "Common.h"

@implementation DropboxAPI

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark
#pragma mark public

// setup
- (NSInteger)setUp
{
    //_Log(@"DropboxAPI setUp");
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:APP_KEY_DROPBOX
                            appSecret:APP_SECRET_DROPBOX
                            root:kDBRootAppFolder]; // or kDBRootDropbox
    dbSession.delegate = self;
    
    [DBSession setSharedSession:dbSession];
    
    // register the notification request
    // to follow the changes of Dropbox link state
    NSNotificationCenter *nofifyCenter = [NSNotificationCenter defaultCenter];
    [nofifyCenter addObserver:self
                     selector:@selector(notifyLinkStateChanged:)
                         name:DBAuthHelperOSXStateChangedNotification
                       object:[DBAuthHelperOSX sharedHelper]];
    
    // for test
    //[[DBSession sharedSession] updateAccessToken:@"aaaaa" accessTokenSecret:@"bbbbb" forUserId:@"12345678"];

    // Dropbox session established using user access token in keychain on OS X
    if ([self isLinked]) {
        //_Log(@"Dropbox: session is activated automatically");
        // Session must be linked before creating any DBRestClient objects
        self.restClient = [self createRestClient];
        return 1;
    }
    return 0;
}

// Dropbox link state
- (BOOL)isLinked
{
    return [[DBSession sharedSession] isLinked];
}

// start OAuth authentication
- (void)startOAuth
{
    if (![[DBSession sharedSession] isLinked]) {
        [[DBAuthHelperOSX sharedHelper] authenticate];
    }
}

// unlink Dropbox (logout)
- (void)unLink
{
    [[DBSession sharedSession] unlinkAll];
    [self notifyToApp:NO];
}

// load revision information
- (void)loadRevisionsForFile:(NSString*)path
{
    //_Log(@"DropboxAPI loadRevisionsForFile");
    [self.restClient loadRevisionsForFile: path];
}

// upload file
- (void)uploadFile:(NSString*)remoteFileFullPath withParentRev:(NSString*)rev localFileFullPath:(NSString*)localFileFullPath
{
    // edit remote path, remote file name
    NSArray *div = [remoteFileFullPath pathComponents];
    NSString *fileName = div[div.count-1];
    NSString *dir = @"";
    for (int i = 0; i < div.count - 1; i++) {
        dir = [dir stringByAppendingPathComponent:div[i]];
    }
    [self.restClient uploadFile:fileName toPath:dir withParentRev:rev fromPath:localFileFullPath];
}

// download file
- (void)loadFile:(NSString*)remoteFileFullPath localFileFullPath:(NSString*)localFileFullPath
{
    [self.restClient loadFile:remoteFileFullPath intoPath:localFileFullPath];
}

#pragma mark

// create DBRestClient object
- (DBRestClient*)createRestClient
{
    DBRestClient *client = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    client.delegate = self;
    return client;
}

// notify Dropbox link state to the app
- (void)notifyToApp:(BOOL)isLinked {
    if ([self.delegate respondsToSelector:@selector(sessionStateChanged:)]) {
        [self.delegate sessionStateChanged:isLinked];
    } else {
        NSLog(@"DropboxAPI notifyToApp failed");
    }
}

// handler for changes of Dropbox link state
/* memo
 "[WARNING] DropboxSDK: error making request to /1/oauth/access_token
   - (401) Request token has not been properly authorized by a user."
*/
- (void)notifyLinkStateChanged:(NSNotification *)notification
{
    //BOOL isLoading = [[DBAuthHelperOSX sharedHelper] isLoading];
    //_Log(@"DropboxAPI notifyLinkStateChanged isLoading=%hhd", isLoading);

    // Dropbox session established via OAuth
    if ([[DBSession sharedSession] isLinked]) {
        //_Log(@"DropboxAPI notifyLinkStateChanged isLinked");
        // You can now start using the Dropbox API
        // Session must be linked before creating any DBRestClient objects
        self.restClient = [self createRestClient];
        [self notifyToApp:YES];
    } else {
        //
    }
}

#pragma mark
#pragma mark DBRestClientDelegate

// upload OK
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    //_Log(@"DropboxAPI uploadedFile: %@", metadata.path);
    
    if ([self.delegate respondsToSelector:@selector(uploadFileDone:uploadedFile:from:metadata:error:)]) {
        [self.delegate uploadFileDone:YES
                         uploadedFile:destPath
                        from:srcPath
                           metadata:metadata
                              error:nil];
    } else {
        NSLog(@"DropboxAPI uploadFileDone failed");
    }
}

// upload NG
- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
    //_Log(@"DropboxAPI uploadFileFailedWithError: %@", error);
    
    if ([self.delegate respondsToSelector:@selector(uploadFileDone:uploadedFile:from:metadata:error:)]) {
        [self.delegate uploadFileDone:NO
                         uploadedFile:nil
                                 from:nil
                             metadata:nil
                                error:error];
    } else {
        NSLog(@"DropboxAPI uploadFileDone failed");
    }
}

// download OK
- (void)restClient:(DBRestClient *)client
        loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType
          metadata:(DBMetadata *)metadata
{
    //_Log(@"DropboxAPI loadedFile: %@", localPath);
    
    if ([self.delegate respondsToSelector:@selector(loadFileDone:loadedFile:contentType:metadata:error:)]) {
        [self.delegate loadFileDone:YES
                         loadedFile:localPath
                        contentType:contentType
                           metadata:metadata
                              error:nil];
    } else {
        NSLog(@"DropboxAPI loadFileDone failed");
    }
}

// download NG
- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    //_Log(@"DropboxAPI loadFileFailedWithError: %@", error);
    
    if ([self.delegate respondsToSelector:@selector(loadFileDone:loadedFile:contentType:metadata:error:)]) {
        [self.delegate loadFileDone:NO
                         loadedFile:nil
                        contentType:nil
                           metadata:nil
                              error:error];
    } else {
        NSLog(@"DropboxAPI loadFileDone failed");
    }
}

// loadRevisionsForFile OK
- (void)restClient:(DBRestClient*)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path
{
    //_Log(@"DropboxAPI loadedRevisions path=[%@]", path);
    // test
    //DBMetadata *meta = revisions[0];
    //NSString *rev = meta.rev;
    //_Log(@"rev=[%@]", rev);
    
    if ([self.delegate respondsToSelector:@selector(loadRevisionsForFileDone:revsions:forFile:error:)]) {
        [self.delegate loadRevisionsForFileDone:YES
                                       revsions:revisions
                                        forFile:path
                                          error:nil];
    } else {
        NSLog(@"DropboxAPI roadRevisionsForFileDone failed");
    }
}

// loadRevisionsForFile NG
- (void)restClient:(DBRestClient*)client loadRevisionsFailedWithError:(NSError *)error
{
    //_Log(@"DropboxAPI loadRevisionsFailedWithError: %@", error);
    if ([self.delegate respondsToSelector:@selector(loadRevisionsForFileDone:
                                                    revsions:
                                                    forFile:error:)]) {
        [self.delegate loadRevisionsForFileDone:NO
                                       revsions:nil
                                        forFile:nil
                                          error:error];
    } else {
        NSLog(@"DropboxAPI loadRevisionsForFileDone failed");
    }
}

//  loadMetadata OK
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    if (metadata.isDirectory) {
        _Log(@"loadedMetadata folder %@:", metadata.path);
        for (DBMetadata *file in metadata.contents) {
            _Log(@"	%@", file.filename);
        }
    }
}

//  loadMetadata NG
- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    //_Log(@"Error loading metadata: %@", error);
}

#pragma mark
#pragma mark DBSessionDelegate

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    //_Log(@"DropboxAPI sessionDidReceiveAuthorizationFailure");
}

#pragma mark

// test
// get userId, accessToken, accessTokenSecret of current session
- (void)getAccessTokenPair
{
    DBSession *session = [DBSession sharedSession];
    if (![session isLinked]) {
        _Log(@"Dropbox getAccessTokenPair: not linked");
        return;
    }
    NSArray *userIds = [session userIds];
    NSString *userId = userIds[0];
    MPOAuthCredentialConcreteStore *store = [session credentialStoreForUserId:userId];
    NSString *accessToken = store.accessToken;
    NSString *accessTokenSecret = store.accessTokenSecret;
    _Log(@"Dropbox userId=[%@] accessToken=[%@] accessTokenSecret=[%@]",
         userId, accessToken, accessTokenSecret);
}

@end
