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
#import "Common.h"

#define DATA_FILE_EXT            @"dat"
#define DATA_NAME                APP_NAME @"." DATA_FILE_EXT
#define DATA_NAME_REMOTE         @"/" DATA_NAME

#define SUFFIX_TMPFILE           @".tmp"
#define SUFFIX_DROPBOX_TMPFILE   @".db"
#define SUFFIX_BACKUPFILE        @".bkup"

#define MAPDATA_LENGTH           128
#define OUTDATA_LENGTH_FREE        3

typedef struct _tag_MapDataRecord {
    uuid_t uuid;
    time_t time;
    unsigned char data[MAPDATA_LENGTH];
    unsigned short outDataLength;
    unsigned char name[0];
} MapDataRecord;

#define KEYSTR_UUID   @"uuid"
#define KEYSTR_TIME   @"time"
#define KEYSTR_DATA   @"data"
#define KEYSTR_OUTLEN @"outlen"
#define KEYSTR_NAME   @"name"

@protocol AppDataDelegate
- (void)fileIOStartOrFinish:(BOOL)StartOrFinish
                   doReload:(BOOL)doReload
                   doUpload:(BOOL)doUpload;
@end

@interface AppData : NSObject

@property (nonatomic, weak) id delegate;

- (NSString*)localMapFileFullPath;
- (NSString*)localDropboxTempMapFileFullPath;
- (BOOL)localMapFileExists;
- (BOOL)copySampleMapData;
- (BOOL)addRecord:(NSDictionary*)dic;
- (BOOL)modifyRecord:(NSDictionary*)dic recordNumber:(NSInteger)idx;
- (BOOL)loadMapFile:(NSMutableArray*)_dataArray;
- (BOOL)mapFilesAreIdentical:(NSString*)otherFilePath;
- (BOOL)mergeMapFiles:(NSString*)otherFilePath
        keepOldRecord:(BOOL)keepOldRecord
    keepForeignRecord:(BOOL)keepForeignRecord;

@end



