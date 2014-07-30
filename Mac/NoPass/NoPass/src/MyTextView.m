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

#import "MyTextView.h"
#import "Uty.h"
#import "Common.h"
#import "AppController.h"
#import "AppData.h"

@implementation MyTextView  {
    NSString *currentMapData;
    NSInteger outDataLength;
    BOOL _Enabled;
}

- (id)initWithFrame:(NSRect)frame
{
    //_Log(@"textview initWithFrame");
    self = [super initWithFrame:frame];
    if (self) {
        // set fixed font
        [self setFont: [NSFont fontWithName:@"Menlo Regular" size:12]];
        [self alignLeft:nil];
        currentMapData = nil;
        [self enableMe:NO];
    }
    return self;
}

// enable or disable
-(void)enableMe:(BOOL)enableIt
{
    [self setSelectable: enableIt];
    [self setEditable: enableIt];
    if (enableIt) {
        [self setTextColor: [NSColor controlTextColor]];
        [self setBackgroundColor:[NSColor whiteColor]];
    } else {
        [self setTextColor: [NSColor disabledControlTextColor]];
        [self setBackgroundColor:[NSColor windowBackgroundColor]];
    }
    _Enabled = enableIt;
}

// draw focus ring
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

    if (_Enabled) {
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(dirtyRect);
    }
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    //_Log(@"myTextVIew textDidEndEditing");
    // [self setSelectedRange:NSZeroRange];
}

// set the length of output string
- (void)setOutDataLength:(NSInteger)val
{
    outDataLength = val;
    [self setDataText];
}

// set map data
- (void)setMapData:(NSString*)mapData
{
    currentMapData  = mapData;
    if (currentMapData != nil) {
        [self enableMe:YES];
        [self setDataText];
    } else {
        //[[self getAppController] setDataFiledString:@""];
        [self setOutDataFiledString:@""];
        [self enableMe:NO];
    }
}

- (BOOL) acceptsFirstResponder {
    return YES;
}

// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/EventOverview/HandlingKeyEvents/HandlingKeyEvents.html
- (void)keyDown:(NSEvent *)theEvent {
    [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

// following action methods are declared in NSResponder.h
- (void)insertTab:(id)sender
{
    //_Log(@"insertTab");
}
- (void)insertBacktab:(id)sender
{
    //_Log(@"insertBacktab");
}

- (void)insertNewline:(id)sender
{
    //_Log(@"insertNewline");
}
- (void)deleteForward:(id)sender
{
    //_Log(@"deleteForward");
    [super deleteForward:sender];
    [self setDataText];
}
- (void)deleteBackward:(id)sender
{
    //_Log(@"deleteBackward");
    [super deleteBackward:sender];
    [self setDataText];
}

- (void)insertText:(id)textString
{
    NSString *str = textString;
    
    if (currentMapData.length <= 0) {
        return;
    }
    // ignore non-ASCII character
    if (![str canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        str = @"";
    }
    // move cursor to bottom of the field
    NSRange	wholeRange;
    NSRange	endRange;
	[self selectAll:nil];
    wholeRange = [self selectedRange];
    endRange = NSMakeRange(wholeRange.length, 0);
    [self setSelectedRange:endRange];
    
    // max 40 characters
    if ([[super string] length] >= 40) {
        return;
    }
    [super insertText:str];
    [self setDataText];
}

- (void)setDataText
{
    NSString *currentKeyData = [super string];
    if (currentKeyData.length <= 0 || currentMapData.length <= 0) {
        [self setOutDataFiledString:@""];
        return;
    }
    const char *keyData = [currentKeyData UTF8String];
    int sum = 0;
    for (int i = 0; keyData[i] != '\0'; i++) {
        sum += keyData[i];
    }
    int mod = sum % 10;
    //_Log(@"MyTextView setDataText sum=%d mod=%d", sum, sum % 10);
    
    NSString *src = [currentKeyData stringByAppendingString: currentMapData];
    NSInteger outLength;
    NSInteger keyLength = currentKeyData.length;
    if (outDataLength != OUTDATA_LENGTH_FREE) {
        outLength = outDataLength;
        for (int i = 0; i < outLength; i++) {
            src = [currentKeyData stringByAppendingString:src];
        }
    } else {
        outLength = keyLength;
    }
    // get SHA1 hash
    unsigned char dgst[CC_SHA1_DIGEST_LENGTH];
    [Uty SHA1:src outBuffer:dgst];
    
    NSString *newValue = @"";
    int keyCount = 0;
    int dgstCount = 0;
    
    // loop for the length of the output string
    for (int i = 0; i < outLength; i++) {
        if (dgstCount >= CC_SHA1_DIGEST_LENGTH) {
            dgstCount = 0;
        }
        if (keyCount >= keyLength) {
            keyCount = 0;
        }
        int idx = dgst[dgstCount++] / 2;
        if (idx % 3 == 0) {
            idx = i + mod;
        } else if (idx % 2 == 0) {
            idx = (idx % 10) + i + keyData[keyCount++] - 0x20;
        } else {
            idx = idx + i + keyData[keyCount++] - 0x20;
        }
        while (idx >= 128) {
            idx -= 128;
        }
        // append a character to output string
        @try {
            NSString *c = [currentMapData substringWithRange:NSMakeRange(idx, 1)];
            newValue = [newValue stringByAppendingString:c ];
        }
        @catch (NSException *exception) {
            [self setOutDataFiledString:@""];
            return;
        }
    }
    // set result string to output field
    [self setOutDataFiledString:newValue];
    return;
}

- (void)setOutDataFiledString:(NSString*)str
{
    if ([self.delegate respondsToSelector:@selector(appNotified:arg1:arg2:arg3:arg4:error:)]) {
        [self.delegate appNotified:APP_SET_OUTTEXTTDATA arg1:str arg2:nil arg3:nil arg4:-1 error:nil];
    } else {
        NSLog(@"MyTextView setOutDataFiledString failed");
    }
}

@end
