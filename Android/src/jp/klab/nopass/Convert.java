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

import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class Convert {
    private static final String TAG = "NoPass";

    private String sourceText;
    private String currentMapData;
    private Integer outDataLength;

    private final Integer OUTDATA_LENGTH_FREE = 3;
    private final Integer CC_SHA1_DIGEST_LENGTH = 20;

    public Convert(String text, String data, Integer len) {
        sourceText = text;
        currentMapData = data;
        outDataLength = len;
    }

    public String getResult() {
        byte[] keyData = null;
        try {
            keyData = sourceText.getBytes("US-ASCII");
        } catch (UnsupportedEncodingException e) {
            _Log.e(TAG, "Convert.getResult err=[" + e.toString() + "]");
            return null;
        }
        Integer outLength;
        Integer keyLength = sourceText.length();
        Integer mod = getTextMod(sourceText);
        if (mod <= -1) {
            return null;
        }
        String src = sourceText + currentMapData;
        if (outDataLength != OUTDATA_LENGTH_FREE) {
            outLength = outDataLength;
            for (int i = 0; i < outLength; i++) {
                src = sourceText + src;
            }
        } else {
            outLength = keyLength;
        }
        // get SHA1 hash
        byte[] dgst = getSha1Hash(src);
        if (dgst == null) {
            return null;
        }
        String newValue = "";
        Integer keyCount = 0;
        Integer dgstCount = 0;

        // loop for the length of the output string
        for (Integer i = 0; i < outLength; i++) {
            if (dgstCount >= CC_SHA1_DIGEST_LENGTH) {
                dgstCount = 0;
            }
            if (keyCount >= keyLength) {
                keyCount = 0;
            }
            // Integer idx = dgst[dgstCount++] / 2;
            Integer idx = dgst[dgstCount++] & 0xFF; // Java!
            idx = idx / 2;
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
            String c = currentMapData.substring(idx, idx + 1);
            newValue = newValue + c;
        }
        return newValue;
    }

    private Integer getTextMod(String str) {
        Integer sum = 0;
        byte[] asciiCodes;
        try {
            asciiCodes = str.getBytes("US-ASCII");
        } catch (Exception e) {
            _Log.e(TAG, "Convert.getSrcTextMod err=" + e.toString());
            return -1;
        }
        for (int i = 0; i < asciiCodes.length; i++) {
            sum += asciiCodes[i];
        }
        // _Log.d(TAG, "sum=" + sum + " mod=" + sum % 10);
        return sum % 10;
    }

    private byte[] getSha1Hash(String str) {
        byte[] digest = null;
        MessageDigest md = null;
        try {
            md = MessageDigest.getInstance("SHA-1");
        } catch (NoSuchAlgorithmException e) {
            _Log.e(TAG, "Convert.digest 1 err=" + e.toString());
            return null;
        }
        try {
            digest = md.digest(str.getBytes("UTF-8"));
        } catch (UnsupportedEncodingException e) {
            _Log.e(TAG, "Convert.digest 2 err=" + e.toString());
            return null;
        }
        /*
         * for (int i = 0; i < digest.length; i++) { _Log.d(TAG, "hex=" +
         * String.format("0x%02X", digest[i])); }
         */
        return digest;
    }
}
