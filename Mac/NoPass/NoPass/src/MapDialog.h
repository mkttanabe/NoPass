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

@protocol MapDialogDelegate
- (void)setMapEntry:(NSInteger)idx
               data:(NSString*)data
               name:(NSString*)name
          outLength:(unsigned short)len;
@end

@interface MapDialog : NSWindowController

@property (nonatomic, weak) id delegate;
@property (nonatomic) NSInteger mapIdxToEdit;
@property (nonatomic, weak) NSMutableArray *mapDataArray;

@property (weak) IBOutlet NSTextField *labelChars;
@property (weak) IBOutlet NSButton *checkNumber;
@property (weak) IBOutlet NSButton *checkMark;
@property (weak) IBOutlet NSButton *checkAlphaUpper;
@property (weak) IBOutlet NSButton *checkAlphaLower;
@property (weak) IBOutlet NSButton *checkSpecialChar;
@property (weak) IBOutlet NSTextField *textFieldSpecialChar;
@property (weak) IBOutlet NSTextField *textFieldOutLength;
@property (weak) IBOutlet NSTextField *textFieldMapName;
@property (weak) IBOutlet NSTextField *labelMapData;
@property (weak) IBOutlet NSButton *buttonCreate;
@property (weak) IBOutlet NSButton *buttonOk;
@property (weak) IBOutlet NSStepper *stepperOutLength;
@property (weak) IBOutlet NSTextField *labelUUID;

- (IBAction)buttonCreatePushed:(id)sender;
- (IBAction)buttonOkPushed:(id)sender;
- (IBAction)buttonCancelPushed:(id)sender;
- (IBAction)checkNumberPushed:(id)sender;
- (IBAction)checkMarkPushed:(id)sender;
- (IBAction)checkAlphaUpperPushed:(id)sender;
- (IBAction)checkAlphaLowerPushed:(id)sender;
- (IBAction)checkSpecialCharPushed:(id)sender;
- (IBAction)textFieldSpecialCharChanged:(id)sender;
- (IBAction)stepperOutLengthChanged:(id)sender;

@end
