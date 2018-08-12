package io.agora.agoramessagetubekitdemo;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Toast;

import io.agora.agoramessagetubekit.AbstractMTKCallback;
import io.agora.agoramessagetubekit.AgoraMessageTubeKit;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        AgoraMessageTubeKit agoraMessageTubeKit = new AgoraMessageTubeKit(this, "81d6b6dfc77b4998a43e7504379cc6bf");
        agoraMessageTubeKit.addCallback(new AbstractMTKCallback() {

            @Override
            public void onLoginSuccess(int uid, int fd) {
                super.onLoginSuccess(uid, fd);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(MainActivity.this, "加入频道成功", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });
        agoraMessageTubeKit.login("yaoximing");

    }
}
