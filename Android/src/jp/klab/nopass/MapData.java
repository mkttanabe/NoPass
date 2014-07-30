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

import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;

/*
#define MAPDATA_LENGTH           128
#define OUTDATA_LENGTH_FREE        3

typedef struct _tag_MapDataRecord {
    uuid_t uuid; // 16 byte
    time_t time; // 8 byte
    unsigned char data[MAPDATA_LENGTH]; // ofs 24, 128 byte
    unsigned short outDataLength; // ofs 152, 2 byte
    unsigned char name[0]; // offset 154
} MapDataRecord;
*/

public class MapData {
    private static final String TAG = "NoPass";
    
    private static final int FLD0_UUID_LENGTH = 16;
    private static final int FLD1_TIME_LENGTH = 8;
    private static final int FLD2_DATA_LENGTH = 128;
    private static final int FLD3_OUTLEN_LENGTH = 2;
    
    private static final int FLD2_DATA_OFFSET = FLD0_UUID_LENGTH + FLD1_TIME_LENGTH;
    private static final int FLD3_OUTLEN_OFFSET = FLD2_DATA_OFFSET + FLD2_DATA_LENGTH;
    private static final int FLD4_NAME_OFFSET = FLD3_OUTLEN_OFFSET + FLD3_OUTLEN_LENGTH;
    
    private List<MapDataItem> mapDataItemList = null;

    public boolean load(String path) {
        mapDataItemList = new ArrayList<MapDataItem>();
        byte[] recLength = new byte[2];
        byte[] buf = new byte[4096];
        byte [] data = new byte[FLD2_DATA_LENGTH];
        byte [] outLenByte = new byte[FLD3_OUTLEN_LENGTH];

        try {
            FileInputStream is = new FileInputStream(path);
            BufferedInputStream bis = new BufferedInputStream(is);
            // read current record length
            while (bis.read(recLength, 0, 2) == 2) {
                // convert to short value
                short len = byteDataToShort(recLength);
                // read current record
                if (bis.read(buf, 0, len) < len) {
                    break;
                }
                // map data array
                System.arraycopy(buf, FLD2_DATA_OFFSET, data, 0, FLD2_DATA_LENGTH);
                for (int i = 0; i < data.length; i++) {
                    data[i] += 0x20;
                }
                // the length of the output string
                System.arraycopy(buf, FLD3_OUTLEN_OFFSET, outLenByte, 0, FLD3_OUTLEN_LENGTH);
                short outLen = byteDataToShort(outLenByte);
                // name
                int nameLen = len - FLD4_NAME_OFFSET - 1; // -1 -> '\0'
                byte [] nameByte = new byte[nameLen];
                System.arraycopy(buf, FLD4_NAME_OFFSET, nameByte, 0, nameLen); 
                String name = new String(nameByte, "UTF-8");

                MapDataItem item = new MapDataItem();
                if (item.init(name, data, (int)outLen) == true) {
                    mapDataItemList.add(item);
                }
            }
            bis.close();
            is.close();
        } catch (IOException e) {
            _Log.e(TAG, "MapData.load err=" +  e.toString());
            return false;
        }        
        return true;
    }
    
    // count of map records
    public Integer count() {
        if (mapDataItemList == null) {
            return 0;
        }
        return mapDataItemList.size();
    }
    
    // get name of Nth record
    public String getName(Integer idx) {
        if (!isValidIndex(idx)) {
            return null;
        }
        return mapDataItemList.get(idx).getName();
    }

    // get map data string of Nth record
    public String getData(Integer idx) {
        if (!isValidIndex(idx)) {
            return null;
        }
        return mapDataItemList.get(idx).getData();
    }

    // get output string length of Nth record
    public Integer getOutLength(Integer idx) {
        if (!isValidIndex(idx)) {
            return null;
        }
        return mapDataItemList.get(idx).getOutLength();
    }

    // check if the given element number is valid
    private boolean isValidIndex(Integer idx) {
        if (count() <= 0) {
            return false;
        }
        if (idx < 0 || idx >= count()) {
            return false;
        }
        return true;
    }
    
    private short byteDataToShort(byte[] data) {
        ByteBuffer bb = ByteBuffer.wrap(data, 0, data.length);
        bb.order(ByteOrder.LITTLE_ENDIAN);
        return bb.getShort();
    }
}

