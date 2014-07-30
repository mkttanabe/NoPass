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

package jp.klab.nopass;

import android.annotation.TargetApi;
import android.content.ClipData;
import android.content.ClipDescription;
import android.content.Context;
import android.os.Build;

public class Clipboard {

    private Context mContext;

    public Clipboard(Context ctx) {
        mContext = ctx;
    }

    public void copy(String text) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            copyToClipboard(text);
        } else {
            copyToClipboardOld(text);
        }
    }

    // for less than API 11
    @SuppressWarnings("deprecation")
    private void copyToClipboardOld(String text) {
        android.text.ClipboardManager clipboardManager = (android.text.ClipboardManager) mContext
                .getSystemService(Context.CLIPBOARD_SERVICE);
        clipboardManager.setText(text);
    }

    // for API 11 or later
    @TargetApi(11)
    private void copyToClipboard(String text) {
        android.content.ClipboardManager cm = (android.content.ClipboardManager) mContext
                .getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData.Item item = new ClipData.Item(text);
        String[] mimeTypes = new String[] { ClipDescription.MIMETYPE_TEXT_PLAIN };
        ClipData cb = new ClipData("data", mimeTypes, item);
        cm.setPrimaryClip(cb);
    }
}
