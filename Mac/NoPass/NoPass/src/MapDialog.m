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

#import "MapDialog.h"
#import "Common.h"
#import "AppDelegate.h"
#import "AppController.h"
#import "AppData.h"

@interface MapDialog ()
@end

@implementation MapDialog {
    NSString *namePrev;
    NSString *dataPrev;
    unsigned short outLengthPrev;
}

/*
 ASCII 0x21 - 0x7e
 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[¥]^_`abcdefghijklmnopqrstuvwxyz{|}~
 */

#define NUMBER      @"0123456789"
#define ALPHA_UPPER @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define ALPHA_LOWER @"abcdefghijklmnopqrstuvwxyz"
#define MARK        @"!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    // -1: create record  else: edit record
    if (self.mapIdxToEdit != -1) {
        NSDictionary *mapData = [self getMapDataByIndex:self.mapIdxToEdit];
        
        namePrev = [mapData objectForKey:KEYSTR_NAME];
        dataPrev = [mapData objectForKey:KEYSTR_DATA];
        NSNumber *lenNum = [mapData objectForKey:KEYSTR_OUTLEN];
        outLengthPrev = [lenNum unsignedShortValue];
        NSData *uuidData = [mapData objectForKey:KEYSTR_UUID];
        uuid_t uuid;
        [uuidData getBytes:uuid];
        [self.labelUUID setStringValue:[self uuidToString:uuid]];
        
        self.labelMapData.stringValue = dataPrev;
        [self stepperOutLengthSetValue:outLengthPrev];
        [self.textFieldMapName setStringValue:namePrev];
        
        [self.buttonOk setEnabled:YES];
        [self.stepperOutLength setEnabled:YES];
        [self.textFieldMapName setEnabled:YES];
    } else {
        namePrev = dataPrev = nil;
        outLengthPrev = -1;
        [self.labelUUID setStringValue:TEXT(@"WordNAV")];
    }
}

- (NSString*)uuidToString:(uuid_t)uuid
{
    NSString *ret = @"";
    for (int i = 0; i < sizeof(uuid_t); i++) {
        NSString *wk = [[NSString alloc] initWithFormat:@"%02X", uuid[i]];
        ret = [ret stringByAppendingString:wk];
    }
    return ret;
}

// return the map record of given index
- (NSDictionary*)getMapDataByIndex:(NSInteger)idx
{
    if (idx < 0 || idx >= self.mapDataArray.count) {
        return nil;
    }
    NSDictionary *data = [self.mapDataArray objectAtIndex:idx];
    return [NSDictionary dictionaryWithDictionary:data];
}

// check if the given name is unique in existing map records
- (BOOL)isUsableMapName:(NSString*)mapName ignoreIndex:(NSInteger)ignoreIndex
{
    NSInteger rows = self.mapDataArray.count;
    for (NSInteger i = 0; i < rows; i++) {
        // skip exclusion element
        if (ignoreIndex != -1 && i == ignoreIndex) {
            continue;
        }
        NSDictionary *data = [self.mapDataArray objectAtIndex:i];
        NSString *name = [data objectForKey:KEYSTR_NAME];
        if ([name isEqualToString:mapName]) {
            return NO;
        }
    }
    return YES;
}

// pressed "generate map data" button
- (IBAction)buttonCreatePushed:(id)sender
{
    // create random map array
    NSString *charList = self.labelChars.stringValue;
    NSString *map = [self createMap:charList];
    // show map data
    [self.labelMapData setStringValue:map];
    // enable controls
    [self.buttonOk setEnabled:YES];
    [self.stepperOutLength setEnabled:YES];
    [self.textFieldMapName setEnabled:YES];
    
    // use current Name if it is unique
    NSString *name = self.textFieldMapName.stringValue;
    if (name.length > 0 && [self isUsableMapName:name ignoreIndex:self.mapIdxToEdit]) {
        return;
    }
    
    // generate candidate Name
    for (int i = 0; i < 9999; i++) {
        NSString *name = [[NSString alloc] initWithFormat:@"Map%04d", i];
        if ([self isUsableMapName:name ignoreIndex:self.mapIdxToEdit]) {
            [self.textFieldMapName setStringValue:name];
            return;
        }
    }
}

// reflect the states of each character type check boxes to source characters list
- (void)showCharacters
{
    NSString *str = @"";
    if (self.checkNumber.state == NSOnState) {
        str = [str stringByAppendingString:NUMBER];
    }
    if (self.checkMark.state == NSOnState) {
        str = [str stringByAppendingString:MARK];
    }
    if (self.checkAlphaUpper.state == NSOnState) {
        str = [str stringByAppendingString:ALPHA_UPPER];
    }
    if (self.checkAlphaLower.state == NSOnState) {
        str = [str stringByAppendingString:ALPHA_LOWER];
    }
    if (self.checkSpecialChar.state == NSOnState) {
        // check given character and add to source list if it is unique in the list.
        NSString *chars = self.textFieldSpecialChar.stringValue;
        for (int i = 0; i < chars.length; i++) {
            NSString *c = [chars substringWithRange:NSMakeRange(i, 1)];
            if ([c isEqualToString:@" "] || [c isEqualToString:@"\t"]) {
                // skip space or tab
                continue;
            }
            if (![c canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                // skip multi-byte character
                continue;
            }
            NSRange range = [str rangeOfString:c];
            if (range.location == NSNotFound) {
                str = [str stringByAppendingString:c];
            }
        }
    }
    [self.labelChars setStringValue:str];
    
    // requires minimum 10 source characters
    if (str.length < 10) {
        [self.buttonCreate setEnabled:NO];
    } else {
        [self.buttonCreate setEnabled:YES];
    }
}

// set output string length value to controls
- (void)stepperOutLengthSetValue:(unsigned short)val
{
    [self.stepperOutLength setIntegerValue: val];
    
    if (val != OUTDATA_LENGTH_FREE) {
        [self.textFieldOutLength setIntegerValue:val];
    } else {
        [self.textFieldOutLength setStringValue:TEXT(@"WordFree")];
    }
}

// generate map data array
- (NSString*)createMap:(NSString*)charList
{
    NSString *map = @"";
    int maxNum = (int)charList.length - 1;
    
    // 128-byte fixed
    for (int i = 0; i < 128; i++) {
        int random = (int)(arc4random() % maxNum) + 0;
        NSString *c = [charList substringWithRange:NSMakeRange(random, 1)];
        map = [map stringByAppendingString:c];
    }
    return map;
}

- (void)cleanUp
{
    [self.labelMapData setStringValue:@""];
    [self.buttonOk setEnabled:NO];
    [self stepperOutLengthSetValue:OUTDATA_LENGTH_FREE];
    [self.stepperOutLength setEnabled:NO];
    [self.textFieldMapName setStringValue:@""];
    [self.textFieldMapName setEnabled:NO];
}

// pressed "Use" button
- (IBAction)buttonOkPushed:(id)sender
{
    // check map name
    NSString *name = self.textFieldMapName.stringValue;
    if (name.length <= 0) {
        
        // "The name of map data is not given."
        NSAlert* alert =[NSAlert
                         alertWithMessageText:APP_NAME
                         defaultButton:TEXT(@"WordOK")
                         alternateButton:nil
                         otherButton:nil
                         informativeTextWithFormat:TEXT(@"MsgMapNameIsNotGiven")];
        [alert runModal];
        return;
    }
    
    NSString *data = self.labelMapData.stringValue;
    NSInteger outLength = [self.stepperOutLength integerValue];

    if ([name isEqualTo:namePrev] && [data isEqualTo:dataPrev] &&
        outLength == outLengthPrev) {
        // record is not changed
        //_Log(@"MapDialog buttonOkPushed: not changed");
    }
    else {
        // reflect created/updated map data
        if ([self.delegate respondsToSelector:@selector(setMapEntry:data:name:outLength:)]) {
            [self.delegate setMapEntry:self.mapIdxToEdit
                                  data:self.labelMapData.stringValue
                                  name:self.textFieldMapName.stringValue
                             outLength:(unsigned short)[self.stepperOutLength integerValue]];
        } else {
            NSLog(@"MapDialog setMapEntry failed");
        }
    }
    [self cleanUp];
    [[NSApplication sharedApplication] stopModalWithCode:1];
}

// pressed "Cancel" button
- (IBAction)buttonCancelPushed:(id)sender {
    [self cleanUp];
    [[NSApplication sharedApplication] stopModalWithCode:0];
}

// checked/unchecked "Use Numbers" box
- (IBAction)checkNumberPushed:(id)sender {
    [self showCharacters];
}

// checked/unchecked "Use Symbols" box
- (IBAction)checkMarkPushed:(id)sender {
    [self showCharacters];
}

// checked/unchecked "Use 'A'-'Z'" box
- (IBAction)checkAlphaUpperPushed:(id)sender {
    [self showCharacters];
}

// checked/unchecked "Use 'a'-'z'" box
- (IBAction)checkAlphaLowerPushed:(id)sender {
    [self showCharacters];
}

// checked/unchecked "Use given character" box
- (IBAction)checkSpecialCharPushed:(id)sender {
    // accept the changes to the characters field
    [self.window endEditingFor:self.textFieldSpecialChar];
    
    if ([sender state] == NSOnState) {
        [self.textFieldSpecialChar setEnabled:YES];
    } else {
        [self.textFieldSpecialChar setEnabled:NO];
    }
    [self showCharacters];
}

- (IBAction)textFieldSpecialCharChanged:(id)sender {
    // フィールドが FirstResponder でなくならなければ変更が反映されないのでペンディング
}

// changed the value of stepper control
- (IBAction)stepperOutLengthChanged:(id)sender {
    NSInteger val = (int)[sender integerValue];
    [self stepperOutLengthSetValue:val];
}

//- (id)getAppController {
//    id delegate = [NSApp delegate];
//    return [delegate appController];
//}

@end
