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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import jp.klab.nopass.R.id;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.dropbox.client2.DropboxAPI;
import com.dropbox.client2.android.AndroidAuthSession;
import com.dropbox.client2.exception.DropboxException;
import com.dropbox.client2.session.AccessTokenPair;
import com.dropbox.client2.session.AppKeyPair;
import com.dropbox.client2.session.Session.AccessType;

public class MainActivity extends Activity implements OnClickListener,
        Handler.Callback {
    private static final String TAG = "NoPass";

    private static final String DROPBOX_APP_KEY     = "*** APP_KEY ***";
    private static final String DROPBOX_APP_SCECRET = "*** APP_SEC ***";
    private DropboxAPI<AndroidAuthSession> mDBApi;
    private static final String DROPBOX_APP_FOLDER_NAME = "/";
    private static final AccessType DROPBOX_ACCESS_TYPE = AccessType.APP_FOLDER;

    private static final String KEYSTR_DROPBOX_KEY = "dbkey";
    private static final String KEYSTR_DROPBOX_SEC = "dbsec";
    private static final int MSG_CLOSE_DIALOG = 1;
    private static final int MSG_SHOW_MESSAGE = 2;
    private static final int MSG_LOAD_MAPDATA = 3;
    private static final int MSG_DO_CONVERT = 4;

    private Handler mHandler;
    private ProgressDialog mDialog = null;
    private Button mButtonGetData;
    private Button mButtonDoIt;
    private Button mButtonCopyBoard;
    private Button mButtonClearBoard;
    private TextView mTextViewOutData;
    private EditText mEditTextInData;
    private Spinner mSpinnerMap;

    private Integer mSelectedMapIndex = 0;
    private Boolean mIsFirst = true;
    private Clipboard mClipboard;
    private MapData mMapData = null;
    private ArrayAdapter<String> mAdapter = null;

    @SuppressWarnings("deprecation")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        //_Log.d(TAG, "onCreate");
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        mHandler = new Handler(this);
        mClipboard = new Clipboard(this);

        // initialize spinner
        mSpinnerMap = (Spinner) findViewById(R.id.spinner1);
        mAdapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_spinner_item);
        mAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        mSpinnerMap.setAdapter(mAdapter);
        mSpinnerMap.setPrompt(getString(R.string.WordMapList));
        mAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);

        // set selection listener to spinner
        mSpinnerMap
                .setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
                    @Override
                    public void onItemSelected(AdapterView<?> parent,
                            View view, int position, long id) {
                        // Spinner spinner = (Spinner) parent;
                        mSelectedMapIndex = position;
                        mHandler.sendEmptyMessage(MSG_DO_CONVERT);
                    }

                    @Override
                    public void onNothingSelected(AdapterView<?> parent) {
                        mSelectedMapIndex = -1;
                    }
                });

        mButtonGetData = (Button) findViewById(id.buttonGetData);
        mButtonGetData.setOnClickListener(this);
        mButtonDoIt = (Button) findViewById(id.buttonDoIt);
        mButtonDoIt.setOnClickListener(this);
        mButtonDoIt.setEnabled(false);
        mButtonCopyBoard = (Button) findViewById(id.buttonCopyBoard);
        mButtonCopyBoard.setOnClickListener(this);
        mButtonCopyBoard.setEnabled(false);
        mButtonClearBoard = (Button) findViewById(id.buttonClearBoard);
        mButtonClearBoard.setOnClickListener(this);
        mTextViewOutData = (TextView) findViewById(id.textViewOutData);
        mTextViewOutData.setTextColor(Color.LTGRAY);
        mTextViewOutData.setOnClickListener(this);
        mEditTextInData = (EditText) findViewById(id.editTextInData);

        AppKeyPair appKeyPair = new AppKeyPair(DROPBOX_APP_KEY,
                DROPBOX_APP_SCECRET);
        AndroidAuthSession session = new AndroidAuthSession(appKeyPair,
                DROPBOX_ACCESS_TYPE);
        mDBApi = new DropboxAPI<AndroidAuthSession>(session);

        // try to get the stored user access token
        String[] userAuthInfo = loadUserAuthInfo();
        // start OAuth authentication if the token is not stored
        if (userAuthInfo[0].length() <= 0 || userAuthInfo[1].length() <= 0) {
            ((AndroidAuthSession) mDBApi.getSession())
                    .startAuthentication(MainActivity.this);
        } else {
            // start Dropbox session using the stored token
            AccessTokenPair userKeyPair = new AccessTokenPair(userAuthInfo[0],
                    userAuthInfo[1]);
            mDBApi.getSession().setAccessTokenPair(userKeyPair);
        }
    }

    @Override
    protected void onResume() {
        //_Log.d(TAG, "onResume");
        super.onResume();
        AndroidAuthSession session = (AndroidAuthSession) mDBApi.getSession();

        // Dropbox session is established using the stored user access token
        if (session.isLinked()) {
            // load local map file if exists
            mHandler.sendEmptyMessage(MSG_LOAD_MAPDATA);
        }
        // OAuth authentication has been succeeded
        else if (session.authenticationSuccessful()) {
            Log.d(TAG, "session.authenticationSuccessful == true");
            try {
                session.finishAuthentication();
                // store the user access token
                AccessTokenPair tokens = session.getAccessTokenPair();
                saveUserAuthInfo(tokens.key, tokens.secret);
            } catch (IllegalStateException e) {
                _Log.e(TAG, "Error authenticating:" + e.toString());
            }
        } else {
            if (mIsFirst) {
                mIsFirst = false;
            } else {
                // user cancelled the authentication
                finish();
            }
        }
        // download remote map file from Dropbox
        if (!islocalMapFileExists()) {
            if (session.isLinked()) {
                downloadMapDataFile();
            }
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        // Back button -> finish app
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            finish();
            return true;
        }
        return false;
    }

    @Override
    public void onClick(View v) {
        // download remote map file
        if (v == (View) mButtonGetData) {
            downloadMapDataFile();
        }
        // run
        else if (v == (View) mButtonDoIt) {
            mHandler.sendEmptyMessage(MSG_DO_CONVERT);
        }
        // copy to clipboard
        else if (v == (View) mButtonCopyBoard) {
            String str = mTextViewOutData.getText().toString();
            mClipboard.copy(str);
            Toast.makeText(this, R.string.MsgCopiedToClipboard, Toast.LENGTH_SHORT).show();
        }
        // clear clipboard
        else if (v == (View) mButtonClearBoard) {
            mClipboard.copy("");
        }
        // tap the output string area
        else if (v == (View) mTextViewOutData) {
            // clear the string
            mTextViewOutData.setText("");
            mButtonCopyBoard.setEnabled(false);
        }
    }

    @Override
    public boolean handleMessage(Message msg) {
        // close progressDialog
        if (msg.what == MSG_CLOSE_DIALOG) {
            if (mDialog != null) {
                mDialog.dismiss();
                mDialog = null;
            }
            return true;
        }
        // show message
        if (msg.what == MSG_SHOW_MESSAGE) {
            if (msg.obj != null) {
                showDialogMessage(this, (String) msg.obj, false);
            }
            return true;
        }
        // load the downloaded map file
        if (msg.what == MSG_LOAD_MAPDATA) {
            if (islocalMapFileExists()) {
                if (!loadLocalMapData()) {
                    showDialogMessage(this, getString(R.string.MsgFailedToLoadMapFile), false);
                }
            }
            return true;
        }
        // generate the output string
        if (msg.what == MSG_DO_CONVERT) {
            String str = mEditTextInData.getText().toString();
            if (str.length() > 0) {
                mButtonCopyBoard.setEnabled(true);
                Convert conv = new Convert(str,
                        mMapData.getData(mSelectedMapIndex),
                        mMapData.getOutLength(mSelectedMapIndex));
                String out = conv.getResult();
                if (out == null) {
                    showDialogMessage(this, getString(R.string.MsgFailedToGenerateString), false);
                    out = "";
                }
                mTextViewOutData.setText(out);
            } else {
                mTextViewOutData.setText("");
                mButtonCopyBoard.setEnabled(false);
            }
            return true;
        }
        return false;
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.add(0, 0, Menu.NONE, R.string.WordUnlinkDropbox);
        menu.add(0, 1, Menu.NONE, R.string.WordAbout);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case 0:
            AlertDialog.Builder dlg = new AlertDialog.Builder(this);
            dlg.setTitle(R.string.app_name);
            dlg.setIcon(R.drawable.ic_launcher);
            dlg.setMessage(R.string.MsgUnlinkDropbox);
            dlg.setPositiveButton(R.string.WordYes,
                    new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int which) {
                            mDBApi.getSession().unlink();
                            removeUserAuthInfo();
                            removeMapFile();
                            finish();
                        }
                    });
            dlg.setNegativeButton(R.string.WordNo,
                    new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int which) {
                        }
                    });
            dlg.show();
            break;

        case 1: // about
            PackageManager pm = this.getPackageManager();
            String ver = "";
            try {
                PackageInfo packageInfo = pm.getPackageInfo(
                        this.getPackageName(), 0);
                ver = packageInfo.versionName;
            } catch (Exception e) {
                ver = "???";
            }
            showDialogMessage(this, getString(R.string.app_name) + " version "
                    + ver + "\n\n" + getString(R.string.Copyright), false);
            break;

        default:
            break;
        }
        return super.onOptionsItemSelected(item);
    }

    // save user access token
    private void saveUserAuthInfo(String key, String secret) {
        SharedPreferences prefs = getSharedPreferences(TAG, MODE_PRIVATE);
        prefs.edit().putString(KEYSTR_DROPBOX_KEY, key).commit();
        prefs.edit().putString(KEYSTR_DROPBOX_SEC, secret).commit();
    }

    // load user access token
    private String[] loadUserAuthInfo() {
        SharedPreferences prefs = getSharedPreferences(TAG, MODE_PRIVATE);
        String[] data = new String[2];
        data[0] = prefs.getString(KEYSTR_DROPBOX_KEY, "");
        data[1] = prefs.getString(KEYSTR_DROPBOX_SEC, "");
        return data;
    }

    // remove user access token
    private void removeUserAuthInfo() {
        SharedPreferences prefs = getSharedPreferences(TAG, MODE_PRIVATE);
        prefs.edit().remove(KEYSTR_DROPBOX_KEY).commit();
        prefs.edit().remove(KEYSTR_DROPBOX_SEC).commit();
    }

    // fullpath of local map file
    public String localMapFileName() {
        return this.getFilesDir().getAbsolutePath() + File.separator
                + getString(R.string.app_name) + ".dat";
    }

    // check if exist the local map file
    public boolean islocalMapFileExists() {
        File f = new File(localMapFileName());
        if (!f.exists() || f.length() <= 0) {
            return false;
        }
        return true;
    }

    // remove local map file
    public void removeMapFile() {
        File f = new File(localMapFileName());
        if (f.exists()) {
            f.delete();
        }
    }

    // load local map file
    public boolean loadLocalMapData() {
        mAdapter.clear();
        mMapData = new MapData();
        if (!mMapData.load(localMapFileName())) {
            return false;
        }
        // set map names to spinner adapter
        for (int i = 0; i < mMapData.count(); i++) {
            mAdapter.add(mMapData.getName(i));
            // _Log.d(TAG, "name=[" + mapData.getName(i) + "]");
            // _Log.d(TAG, "data=[" + mapData.getData(i) + "]");
            // _Log.d(TAG, "len=[" + mapData.getOutLength(i) + "]");
        }
        // enable "Run" button
        mButtonDoIt.setEnabled(true);
        return true;
    }

    // download remote map file from Dropbox
    public boolean downloadMapDataFile() {
        final Message msg = Message.obtain();
        msg.obj = null;
        mDialog = new ProgressDialog(this);
        mDialog.setMessage(getString(R.string.MsgDownloading));
        mDialog.setProgressStyle(ProgressDialog.STYLE_SPINNER);
        mDialog.setCancelable(false);
        mDialog.show();
        (new Thread(new Runnable() {
            @Override
            public void run() {
                // download remote map file to app local directory
                OutputStream os = null;
                try {
                    os = new FileOutputStream(localMapFileName());
                } catch (FileNotFoundException e) {
                    msg.obj = new String(e.toString());
                }
                if (msg.obj == null) {
                    try {
                        mDBApi.getFile(DROPBOX_APP_FOLDER_NAME
                                + getString(R.string.app_name) + ".dat", null,
                                os, null);
                    } catch (DropboxException e1) {
                        String err = e1.toString();
                        if (err.indexOf("404 ") >= 0) { // file not found
                            // getFile err=DropboxServerException (nginx): 404
                            // None (File not found)
                            msg.obj = new String(getString(R.string.MsgNoMapFileInDropbox));
                        } else {
                            msg.obj = new String(getString(R.string.MsgFailedToGetFileFromDropbox) + "\n\n"
                                    + err);
                        }
                    }
                }
                try {
                    os.close();
                } catch (IOException e) {
                }
                // close ProgressDialog
                mHandler.sendEmptyMessage(MSG_CLOSE_DIALOG);
                if (msg.obj != null) { // some error
                    // show error message
                    msg.what = MSG_SHOW_MESSAGE;
                    mHandler.sendMessage(msg);
                } else { // OK
                    msg.what = MSG_SHOW_MESSAGE;
                    msg.obj = new String(getString(R.string.MsgDownloadedMapFileFromDropbox));
                    mHandler.sendMessage(msg);
                    // load the downloaded map file
                    mHandler.sendEmptyMessage(MSG_LOAD_MAPDATA);
                }
            }
        })).start();
        return true;
    }

    // show message
    void showDialogMessage(Context ctx, String msg, final boolean bFinish) {
        new AlertDialog.Builder(ctx).setTitle(R.string.app_name)
                .setIcon(R.drawable.ic_launcher).setMessage(msg)
                .setPositiveButton("OK", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                        if (bFinish) {
                            finish();
                        }
                    }
                }).show();
    }
}
