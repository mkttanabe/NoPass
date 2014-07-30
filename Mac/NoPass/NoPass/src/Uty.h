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
#import <CommonCrypto/CommonDigest.h>

@interface Uty : NSObject

+ (BOOL)SetPasteBoardText:(NSString*)str;
+ (unsigned char*)SHA1:(NSString*)string outBuffer:(unsigned char[CC_SHA1_DIGEST_LENGTH])outBuffer;
+ (void)msgBox:(NSString*)msg;
+ (void)msgBox2:(NSString*)msg ownerWindow:(id)ownerWindow;
+ (void)dump:(Byte*)data length:(NSInteger)length;
+ (BOOL)fileIsExist:(NSString*)fileNameFullPath;

@end
