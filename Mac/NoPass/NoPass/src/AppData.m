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

#import "AppData.h"
#import "Common.h"
#import "Uty.h"

@implementation AppData {
    #define BUF_SIZE 4096
    Byte buf[BUF_SIZE];
}

// fullpath of local map file
- (NSString*)localMapFileFullPath
{
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    NSString *myMapFilePath = [dir stringByAppendingPathComponent:APP_NAME];
    NSError* error = nil;
    
    // make directory hierarchy
    [[NSFileManager defaultManager] createDirectoryAtPath:myMapFilePath
                              withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    
    myMapFilePath = [myMapFilePath stringByAppendingPathComponent:DATA_NAME];
    return myMapFilePath;
}

// fullpath of downloaded remote map file for synchronization
- (NSString*)localDropboxTempMapFileFullPath
{
    // has ".db" suffix
    return [[self localMapFileFullPath] stringByAppendingString:SUFFIX_DROPBOX_TMPFILE];
}

// check if exist the local map file
- (BOOL)localMapFileExists
{
    NSString *myMapFile = [self localMapFileFullPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath: myMapFile]) {
        return YES;
    }
    return NO;
}

// cut out the sample map file
- (BOOL)copySampleMapData
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *myResData = [bundle pathForResource:APP_NAME ofType:DATA_FILE_EXT];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL result = [fileManager copyItemAtPath:myResData toPath:[self localMapFileFullPath] error:&error];
    if (result) {
        return YES;
    }
    return NO;
}

// add new record to local map file
- (BOOL)addRecord:(NSDictionary*)dic
{
    NSString *filePath = [self localMapFileFullPath];
    FILE *fp = fopen([filePath UTF8String], "a");
    if (!fp) {
        return NO;
    }
    BOOL sts = [self saveRecord:fp data:dic];
    fclose(fp);
    return sts;
}

// edit/delete existing record in local map file (dic == nil -> delete record)
- (BOOL)modifyRecord:(NSDictionary*)dic recordNumber:(NSInteger)idx
{
    __block BOOL sts = NO;
    [self notifyToApp:YES doReload:NO doUpload:NO]; // notify start
    
    // processing in worker thread
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQ = dispatch_get_main_queue();
    dispatch_async(globalQ, ^{
        
        NSString *filePath = [self localMapFileFullPath];
        NSString *filePathTmp = [filePath stringByAppendingString:SUFFIX_TMPFILE];
        NSString *filePathBkup = [filePath stringByAppendingString:SUFFIX_BACKUPFILE];
        FILE *fpr = fopen([filePath UTF8String], "r");
        FILE *fpw = fopen([filePathTmp UTF8String], "w"); // temporary file
        if (!fpr || !fpw) {
            goto DONE;
        }
        unsigned short recLen;
        NSInteger count = 0;
        while (fread(&recLen, sizeof(short), 1, fpr) >= 1) {
            if (count != idx) {
                // copy existing record to temporary file
                if (fread(&buf, recLen, 1, fpr) <= 0) {
                    goto DONE;
                }
                if (fwrite(&recLen, sizeof(short), 1, fpw) <= 0) {
                    goto DONE;
                }
                if (fwrite(&buf, recLen, 1, fpw) <= 0) {
                    goto DONE;
                }
            } else {
                // the target record to update or delete
                if (fseek(fpr, recLen, SEEK_CUR) != 0) { // skip existing record
                    goto DONE;
                }
                if (dic != nil) {
                    if (![self saveRecord:fpw data:dic]) {
                        goto DONE;
                    }
                }
            }
            count++;
        }
        sts = YES;
        
    DONE:
        if (fpr) {
            fclose(fpr);
        }
        if (fpw) {
            fclose(fpw);
        }
        // backup existing local map file -> "*.bkup"
        // set the temporary file as new local map file
        unlink([filePathBkup UTF8String]);
        rename([filePath UTF8String], [filePathBkup UTF8String]);
        rename([filePathTmp UTF8String], [filePath UTF8String]);
        
        // notify the end of processing (from Main Queue)
        dispatch_async(mainQ, ^{
            [self notifyToApp:NO doReload:NO doUpload:NO];
        });
    });
    return sts;
}

- (void)notifyToApp:(BOOL)sts doReload:(BOOL)doReload doUpload:(BOOL)doUpload
{
    //_Log(@"AppData notifyToApp");
    if ([self.delegate respondsToSelector:@selector(fileIOStartOrFinish:doReload:doUpload:)]) {
        [self.delegate fileIOStartOrFinish:sts doReload:doReload doUpload:doUpload];
    } else {
        NSLog(@"AppData notifyToApp failed");
    }
}

// write a map data record
- (BOOL)saveRecord:(FILE*)fp data:(NSDictionary*)dic
{
    size_t num;
    NSString *name = [dic objectForKey:KEYSTR_NAME];
    NSString *data = [dic objectForKey:KEYSTR_DATA];
    NSNumber *lenNum = [dic objectForKey:KEYSTR_OUTLEN];
    unsigned short outlen = [lenNum integerValue];
    NSData *uuid = [dic objectForKey:KEYSTR_UUID];
    NSNumber *timeNum = [dic objectForKey:KEYSTR_TIME];
    time_t time = [timeNum unsignedLongLongValue];
    
    // calculate the length of the record
    // *[NSString length] counts as 1 length even multi-byte character
    NSInteger nameLength = strlen([name UTF8String]);
    unsigned short recordLength =
            sizeof(MapDataRecord) +
            //name.length + sizeof(char); // name + '\0'
            nameLength + sizeof(char);
    
    // output the length
    num = fwrite(&recordLength, sizeof(short), 1, fp);
    if (num <= 0) {
        return NO;
    }
    
    MapDataRecord *rec = (MapDataRecord*)buf;
    if (recordLength > BUF_SIZE) {
        rec = (MapDataRecord*)malloc(recordLength);
    }
    
    // uuid
    uuid_t uuidBytes;
    memset(uuidBytes, 0, sizeof(uuid_t));
    [uuid getBytes:uuidBytes];
    memcpy(rec->uuid, uuidBytes, sizeof(uuid_t));
    
    // time
    rec->time = time;
    
    // map data (Subtract 0x20 from each element of the array）
    unsigned char mData[MAPDATA_LENGTH+1];
    memcpy(mData, [data UTF8String], MAPDATA_LENGTH);
    for (int i = 0; i < MAPDATA_LENGTH; i++) {
        mData[i] -= 0x20;
    }
    memcpy(rec->data, mData, MAPDATA_LENGTH);
    
    // the length of output string
    rec->outDataLength = outlen;
    
    // name - only this field is variable length
    void *p = rec->name;
    memcpy(p, [name UTF8String], nameLength + 1);
    
    num = fwrite(rec, recordLength, 1, fp);
    if (rec != (MapDataRecord*)buf) {
        free(rec);
    }
    if (num <= 0) {
        return NO;
    }
    return YES;
}

// load local map file
- (BOOL)loadMapFile:(NSMutableArray*)_dataArray
{
    NSString *filePath = [self localMapFileFullPath];
    FILE *fp = fopen([filePath UTF8String], "r");
    if (!fp) {
        return NO;
    }
    unsigned short recLen;
    while (fread(&recLen, sizeof(short), 1, fp) >= 1) {
        
        MapDataRecord *rec = (MapDataRecord*)buf;
        if (recLen > BUF_SIZE) {
            rec = (MapDataRecord*)malloc(recLen);
        }
        if (fread(rec, recLen, 1, fp) <= 0) {
            break;
        }
        // restore the map data array
        for (int i = 0; i < MAPDATA_LENGTH; i++) {
            rec->data[i] += 0x20;
        }
        char *p = (void*)rec->name;
        NSString *name = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
        NSString *data = [[NSString alloc] initWithBytes:rec->data length:MAPDATA_LENGTH encoding:NSUTF8StringEncoding];
        NSNumber *outlen = [[NSNumber alloc] initWithUnsignedShort:rec->outDataLength];
        NSNumber *time = [[NSNumber alloc] initWithUnsignedLongLong:rec->time];
        NSData *uuid = [[NSData alloc] initWithBytes:rec->uuid length:sizeof(uuid_t)];
        
        
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:
                             name, KEYSTR_NAME,
                             data, KEYSTR_DATA,
                             outlen, KEYSTR_OUTLEN,
                             uuid, KEYSTR_UUID,
                             time, KEYSTR_TIME, nil];
        
        [_dataArray addObject:dic];
        
        /// for test
        /*
        _Log(@"name=%@", name);
        struct tm lt;
        localtime_r(&rec->time, &lt);
        _Log(@"time=%04d-%02d-%02d %02d:%02d:%02d",
             lt.tm_year+1900, lt.tm_mon+1, lt.tm_mday, lt.tm_hour, lt.tm_min, lt.tm_sec);
        _Log(@"uuid=");
        [Uty dump:rec->uuid length:sizeof(uuid_t)];
        */
        ///
        
        if (rec != (MapDataRecord*)buf) {
            free(rec);
        }
    }
    fclose(fp);
    return YES;
}

// appropriate record length?
- (BOOL)isValidRecordLength:(NSInteger)n
{
    if (n > sizeof(MapDataRecord) &&
        n < sizeof(MapDataRecord) * 2) {
        return YES;
    }
    return NO;
}

// get record count of the map file
- (NSInteger)getMapDataRecordCount:(NSString*)mapFileName
{
    NSInteger recNum = 0;
    FILE *fp = fopen([mapFileName UTF8String], "r");
    if (!fp) {
        return 0;
    }
    unsigned short recLen;
    while (fread(&recLen, sizeof(short), 1, fp) >= 1) {
        if (![self isValidRecordLength: recLen]) {
            break;
        }
        if (fseek(fp, recLen, SEEK_CUR) != 0) {
            break;
        }
        recNum++;
    }
    fclose(fp);
    return recNum;
}

// returns a pointer array of all the records in the map file.
- (MapDataRecord**)getMapDataRecordArray:(NSString*)mapFileName
{
    MapDataRecord **recArray = NULL;
    // get total record count
    NSInteger recNum = [self getMapDataRecordCount:mapFileName];
    if (recNum <= 0) {
        return NULL;
    }
    FILE *fp = fopen([mapFileName UTF8String], "r");
    if (!fp) {
        return NULL;
    }

    // allocate ARRAY[record count + 1]
    // the last element is NULL
    size_t size = (recNum + 1) * sizeof(MapDataRecord*);
    recArray = (MapDataRecord**)malloc(size);
    memset(recArray, 0, size);

    unsigned short recLen;
    NSInteger count = 0;
    // read each record
    while (fread(&recLen, sizeof(short), 1, fp) >= 1) {
        if (![self isValidRecordLength: recLen]) {
            break;
        }
        MapDataRecord *rec = (MapDataRecord*)malloc(recLen);
        if (fread(rec, recLen, 1, fp) <= 0) {
            free(rec);
            break;
        }
        // set to the array
        recArray[count++] = rec;
    }
    fclose(fp);
    return recArray;
}

// free the array allocated by getMapDataRecordArray()
- (void)freeMapDataRecordArray:(MapDataRecord***)recp
{
    if (*recp) {
        for (int i = 0; (*recp)[i] != NULL; i++) {
            free((*recp)[i]);
        }
        free(*recp);
    }
}

// output a MapDataRecord to the file
- (BOOL)writeMapDataRecord:(FILE*)fp rec:(MapDataRecord*)rec altName:(char*)altName
{
    if (!fp || !rec) {
        return NO;
    }
    char *p;
    if (!altName) {
        p = (char*)((void*)rec->name);
        if (!p) {
            return NO;
        }
    } else {
        p = altName;
    }
    // record length
    unsigned short recLen = sizeof(MapDataRecord) +
                        strlen(p) + sizeof(char); // '\0';
    
    if (fwrite(&recLen, sizeof(short), 1, fp) <= 0) {
        return NO;
    }
    if (fwrite(rec, sizeof(MapDataRecord), 1, fp) <= 0) {
        return NO;
    }
    if (fwrite(p, strlen(p) + sizeof(char), 1, fp) <= 0) {
        return NO;
    }
    return YES;
}

// create alternative name for the record
- (char*)createAltName:(MapDataRecord*)rec
{
    char *pName = (char*)((void*)rec->name);
    char *pAltName = (char*)buf;
    
    struct tm lt;
    localtime_r(&rec->time, &lt);
    // "[original name]_YYYYMMDD-HHMNSS"
    sprintf(pAltName, "%s_%04d%02d%02d-%02d%02d%02d", pName,
            lt.tm_year+1900, lt.tm_mon+1, lt.tm_mday, lt.tm_hour, lt.tm_min, lt.tm_sec);

    return pAltName;
}

// create and write an alternative record of given record
- (BOOL)writeMapDataAltRecord:(FILE*)fp rec:(MapDataRecord*)rec
{
    // copy the record
    MapDataRecord *p = (MapDataRecord*)malloc(sizeof(MapDataRecord));
    memcpy(p, rec, sizeof(MapDataRecord));
    // set new UUID
    uuid_t uuid;
    [[NSUUID UUID] getUUIDBytes:uuid];
    memcpy(p->uuid, uuid, sizeof(uuid_t));
    char *pAltName = [self createAltName:rec];
    
    BOOL sts = [self writeMapDataRecord:fp rec:p altName:pAltName];
    free(p);
    return sts;
}

// check if the alternate record of given record already exists in checkArray.
- (BOOL)alreadyExistAltRecord:(MapDataRecord*)rec checkArray:(MapDataRecord**)checkArray
{
    BOOL sts = NO;
    char *pAltName = [self createAltName:rec];
    size_t size = sizeof(MapDataRecord) + strlen(pAltName) + sizeof(char);
    // copy the record
    MapDataRecord *p = (MapDataRecord*)malloc(size);
    memcpy(p, rec, sizeof(MapDataRecord));
    // set alternative name
    strcpy((char*)((void*)p->name), pAltName);
    for (int i = 0; checkArray[i] != NULL; i++) {
        // already exists matched record except UUID
        if ([self compareRecordExceptUUID:p recOther:checkArray[i]]) {
            sts = YES;
            break;
        }
    }
    free(p);
    return sts;
}

// compare UUID of two records
- (BOOL)compareRecordUuid:(MapDataRecord*)rec recOther:(MapDataRecord*)recOther
{
    if (memcmp(recOther->uuid, rec->uuid, sizeof(uuid_t)) == 0) {
        return YES;
    }
    return NO;
}

// compare time of two records
- (int)compareRecordTime:(MapDataRecord*)rec recOther:(MapDataRecord*)recOther
{
    if (rec->time == recOther->time) {
        return 0;
    } else if (rec->time > recOther->time) {
        return 1;
    }
    return -1;
}

// compare records
- (BOOL)compareRecord:(MapDataRecord*)rec recOther:(MapDataRecord*)recOther
{
    char *pName = (char*)((void*)rec->name);
    char *pNameOther = (char*)((void*)recOther->name);
    
    if (memcmp(rec, recOther, sizeof(MapDataRecord)) == 0) {
        if (strcmp(pName, pNameOther) == 0) {
            return YES;
        }
    }
    return NO;
}

// compare records except UUID
- (BOOL)compareRecordExceptUUID:(MapDataRecord*)rec recOther:(MapDataRecord*)recOther
{
    char *pName = (char*)((void*)rec->name);
    char *pNameOther = (char*)((void*)recOther->name);
    
    if (rec->time == recOther->time &&
        rec->outDataLength == recOther->outDataLength &&
        memcmp(rec->data, recOther->data, sizeof(MapDataRecord)) == 0 &&
        strcmp(pName, pNameOther) == 0) {
        return YES;
    }
    return NO;
}

// compare two map files
- (BOOL)mapFilesAreIdentical:(NSString*)otherFilePath
{
    BOOL sts = YES;
    FILE *fp1 = NULL, *fp2 = NULL;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attribute = [fm attributesOfItemAtPath:[self localMapFileFullPath] error:nil];
    NSNumber *fileSize = [attribute objectForKey:NSFileSize];
    NSDictionary *attributeOther = [fm attributesOfItemAtPath:otherFilePath error:nil];
    NSNumber *fileSizeOther = [attributeOther objectForKey:NSFileSize];
    if (fileSize != fileSizeOther) {
        return NO;
    }
    fp1 = fopen([[self localMapFileFullPath] UTF8String], "r");
    fp2 = fopen([otherFilePath UTF8String], "r");
    if (!fp1 || !fp2) {
        sts = NO;
        goto DONE;
    }
    size_t readBytes;
    Byte buf2[BUF_SIZE];
    while ((readBytes = fread(buf, 1, BUF_SIZE, fp1)) > 0) {
        fread(buf2, 1, readBytes, fp2);
        if (memcmp(buf, buf2, readBytes) != 0) {
            sts = NO;
            goto DONE;
        }
    }
DONE:
    if (fp2) {
        fclose(fp2);
    }
    if (fp1) {
        fclose(fp1);
    }
    return sts;
}

// merge records between local map file and downloaded map file
- (BOOL)mergeMapFiles:(NSString*)otherFilePath
        keepOldRecord:(BOOL)keepOldRecord
    keepForeignRecord:(BOOL)keepForeignRecord
{
    __block BOOL sts = NO;
    [self notifyToApp:YES doReload:NO doUpload:NO]; // notify start
    
    // processing in worker thread
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQ = dispatch_get_main_queue();
    dispatch_async(globalQ, ^{

        NSString *filePath = [self localMapFileFullPath];
        NSString *filePathOther = [filePath stringByAppendingString:SUFFIX_DROPBOX_TMPFILE];
        NSString *filePathTmp = [filePath stringByAppendingString:SUFFIX_TMPFILE];
        NSString *filePathBkup = [filePath stringByAppendingString:SUFFIX_BACKUPFILE];
        FILE *fpTmp = NULL;
        MapDataRecord *rec, *recOther;
        MapDataRecord **recArray = [self getMapDataRecordArray:filePath];
        MapDataRecord **recArrayOther = [self getMapDataRecordArray:filePathOther];
        
        // if OtherMapFile does not have available records,
        // upload local map file to Dropbox directly
        if (!recArrayOther) {
            goto DONE;
        }
        
        // open temp file
        fpTmp = fopen([filePathTmp UTF8String], "w");
        if (!fpTmp) {
            goto DONE;
        }

        // local map file has no available records
        if (!recArray) {
            // option: "remote map file holds a record which is not in local map file."
            //          -> "Copy it to local"
            if (keepForeignRecord) {
                // copy all records in OtherMapFile
                for (int i = 0; recArrayOther[i] != NULL; i++) {
                    [self writeMapDataRecord:fpTmp rec:recArrayOther[i] altName:NULL];
                }
            }
            goto DONE;
        }
        
        // loop for all records in local map file
        for (int i = 0; recArray[i] != NULL; i++) {
            rec = recArray[i];

            recOther = NULL;
            // search the record in OtherMapFile witch has matched UUID of
            // current local record
            for (int i = 0; recArrayOther[i] != NULL; i++) {
                recOther = recArrayOther[i];
                if ([self compareRecordUuid:rec recOther:recOther]) {
                    break;
                }
                recOther = NULL;
            }
            // write the local record only,
            // if OtherMapFile does not have the UUID matched record, or
            // if OtherMapFile has entire matched record
            if (!recOther || [self compareRecord:rec recOther:recOther]) {
                [self writeMapDataRecord:fpTmp rec:rec altName:NULL];
            } else {
                int sts = [self compareRecordTime:rec recOther:recOther];
                if (sts > 0) { // the local record is newer
                    // write local record
                    [self writeMapDataRecord:fpTmp rec:rec altName:NULL];

                    // option: "local & remote map file both holds a record which
                    //          has the same unique ID and different contents."
                    //          -> "Leave both"
                    if (keepOldRecord) {
                        // write the UUID matched (older) record in OtherMapFile
                        if (![self alreadyExistAltRecord:recOther checkArray:recArray]) {
                            [self writeMapDataAltRecord:fpTmp rec:recOther];
                        }
                    }
                } else { // the record of OtherMapFile is newer
                    [self writeMapDataRecord:fpTmp rec:recOther altName:NULL];
                    if (keepOldRecord) {
                        // write the UUID matched (older) record in local map file
                        [self writeMapDataAltRecord:fpTmp rec:rec];
                    }
                }
            }
        }
        
        if (keepForeignRecord) {
            // loop for all records in OtherMapFile
            for (int i = 0; recArrayOther[i] != NULL; i++) {
                recOther = recArrayOther[i];
                rec = NULL;
                // search the record in local map file witch has matched UUID of
                // current record of OtherMapFile
                for (int i = 0; recArray[i] != NULL; i++) {
                    rec = recArray[i];
                    if ([self compareRecordUuid:recOther recOther:rec]) {
                        break;
                    }
                    rec = NULL;
                }
                // write the record if local map file does not have the
                // UUID matched record
                if (!rec) {
                    [self writeMapDataRecord:fpTmp rec:recOther altName:NULL];
                }
            }
        }
        
DONE:
        // dump
        //for (int i = 0; recArray[i] != NULL; i++) {
        //    rec = recArray[i];
        //    [self dumpRecord:rec];
        //}

        sts = YES;
        if (fpTmp) {
            fclose(fpTmp);
            // backup existing local map file -> "*.bkup"
            // set the temporary file as new local map file
            unlink([filePathBkup UTF8String]);
            rename([filePath UTF8String], [filePathBkup UTF8String]);
            rename([filePathTmp UTF8String], [filePath UTF8String]);
        }
        [self freeMapDataRecordArray:&recArray];
        [self freeMapDataRecordArray:&recArrayOther];

        // notify the end of processing (from Main Queue)
        dispatch_async(mainQ, ^{
            if (sts) {
                [self notifyToApp:NO doReload:YES doUpload:YES];
            }
        });
        //[self notifyToApp:NO doReload:YES doUpload:YES];

    });
    return sts;
}

// for test
- (void)dumpRecord:(MapDataRecord*)rec
{
    if (!rec) {
        return;
    }
    _Log(@"name=%s", rec->name);
    _Log(@"uuid=");
    [Uty dump:rec->uuid length:sizeof(uuid_t)];
    struct tm lt;
    localtime_r(&rec->time, &lt);
    _Log(@"time=%04d-%02d-%02d %02d:%02d:%02d",
         lt.tm_year+1900, lt.tm_mon+1, lt.tm_mday, lt.tm_hour, lt.tm_min, lt.tm_sec);
    unsigned char dat[MAPDATA_LENGTH+1];
    memcpy(dat, rec->data, MAPDATA_LENGTH);
    dat[MAPDATA_LENGTH] = '\0';
    for (int i = 0; i < MAPDATA_LENGTH; i++) {
        dat[i] += 0x20;
    }
    _Log(@"data=%s", dat);
    _Log(@"outlen=%d", rec->outDataLength);
    
}

@end

