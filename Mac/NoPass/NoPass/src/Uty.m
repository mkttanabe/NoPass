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

#include <CommonCrypto/CommonDigest.h>

#import "Common.h"
#import "Uty.h"


@implementation Uty

+ (BOOL)SetPasteBoardText:(NSString*)str
{
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    BOOL sts = [pasteBoard setString:str forType:NSStringPboardType];
    if (!sts) {
        NSLog(@"SetPasteBoardText: failed to copy to pasteboard");
    }
    return sts;
}

+ (unsigned char*)SHA1:(NSString*)string outBuffer:(unsigned char[CC_SHA1_DIGEST_LENGTH])outBuffer
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA1(data.bytes, (CC_LONG)data.length, outBuffer);
    return outBuffer;
}

+ (void)msgBox:(NSString*)msg
{
    NSAlert* alert =[NSAlert
                     alertWithMessageText:APP_NAME
                     defaultButton:@"OK"
                     alternateButton:nil
                     otherButton:nil
                     informativeTextWithFormat:@"%@", msg];
    [alert runModal];
}

+ (void)msgBox2:(NSString*)msg ownerWindow:(id)ownerWindow
{
    NSAlert *alert = [ NSAlert alertWithMessageText : APP_NAME
                                      defaultButton : @"OK"
                                    alternateButton : nil
                                        otherButton : nil
                          informativeTextWithFormat : @"%@", msg];
    [alert beginSheetModalForWindow:ownerWindow
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
}

+ (void)dump:(Byte*)data length:(NSInteger)length
{
    int cnt = 0;
    NSString *str = @"";
    for (int i = 0; i < length; i++) {
        NSString *wk = [[NSString alloc] initWithFormat:@"%02X ", data[i]];
        str = [str stringByAppendingString:wk];
        if (++cnt % 16 == 0) {
            _Log(@"%@", str);
            str = @"";
        }
    }
}

+ (BOOL)fileIsExist:(NSString*)fileNameFullPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:fileNameFullPath];
}

@end
