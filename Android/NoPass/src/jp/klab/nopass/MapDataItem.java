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

public class MapDataItem {
    private static final String TAG = "NoPass";
    private String mapName;
    private String mapData;
    private Integer outLength;

    public MapDataItem() {
    }

    public boolean init(String name, byte[] data, Integer outLen) {
        if (name == null || name.length() <= 0 || data == null
                || data.length <= 0 || outLen <= 0) {
            return false;
        }
        try {
            mapData = new String(data, "UTF-8");
        } catch (UnsupportedEncodingException e1) {
            _Log.e(TAG, "MapDataItem init err=" + e1.toString());
            return false;
        }
        mapName = name;
        outLength = outLen;
        return true;
    }

    public String getName() {
        return mapName;
    }

    public String getData() {
        return mapData;
    }

    public Integer getOutLength() {
        return outLength;
    }
}
