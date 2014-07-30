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

#ifndef Common_h
#define Common_h

//#define DEVELOP

#define APP_NAME           @"NoPass"

#define APP_KEY_DROPBOX    @"*** APP_KEY ***"
#define APP_SECRET_DROPBOX @"*** APP_SEC ***"

#define TEXT(STR) NSLocalizedString(STR, @"")

#pragma pack(2)

#ifdef DEVELOP
#define _Log(...) NSLog(__VA_ARGS__)
#else
#define _Log(...) ;
#endif

#endif
