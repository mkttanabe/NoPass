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

#import <Cocoa/Cocoa.h>

@protocol MyTextViewDelegate
- (void)appNotified:(NSInteger)state
            arg1:(id)arg1
            arg2:(id)arg2
            arg3:(id)arg3
            arg4:(NSInteger)arg4
           error:(NSError*)error;
@end

@interface MyTextView : NSTextView

@property (nonatomic, weak) id delegate;

- (void)setOutDataLength:(NSInteger)val;
- (void)setMapData:(NSString*)mapData;

@end
