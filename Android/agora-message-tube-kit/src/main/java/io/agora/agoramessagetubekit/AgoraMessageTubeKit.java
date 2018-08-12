package io.agora.agoramessagetubekit;

import android.content.Context;

import android.text.TextUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Random;

import io.agora.AgoraAPIOnlySignal;

public class AgoraMessageTubeKit {

    public static final String TAG = "AgoraMessageTubeKit";
    private static final int UID = 0;
    private static final String DEVICE_ID = null;
    public static final int DEFAULT_RETRY_TIME_IN_S = 30;
    public static final int RETRY_COUNT = 3;
    public static final String NO_NEED_TOKEN = "_no_need_token";
    public static final String MESSAGE_ID = "";

    public static final int MESSAGE_TYPE_PEER_TO_PEER_COMMON_MESSAGE = 0;
    public static final int MESSAGE_TYPE_CHANNEL_COMMON_MESSAGE = 1;
    public static final int MESSAGE_TYPE_PEER_TO_PEER_RECEIVE_COM_MSG_SUCCESS = 2;
    public static final int MESSAGE_TYPE_PEER_TO_PEER_JSON_MESSAGE = 3;
    public static final int MESSAGE_TYPE_CHANNEL_JSON_MESSAGE = 4;
    public static final int MESSAGE_TYPE_SEND_PING_TO_SERVER_JSON_MESSAGE = 5;
    public static final int MESSAGE_TYPE_SEND_REQUEST_TO_SERVER_JSON_MESSAGE = 6;

    public static final String ADC_TYPE = "ADCType";
    public static final String ACCOUNT = "account";
    public static final String CHANNEL_ID = "channelId";
    public static final String MESSAGE = "message";
    private static final String REQUEST_ID = "requestId";

    private AgoraAPIOnlySignal mSignalInstance;

    private WeakReference<Context> mContext;

    private String mAppId;

    private String mAccount;

    private String mChannelId;

    private List<MTKCallback> mMtkCallbacks;

    public AgoraMessageTubeKit(Context context, String mAppId) {
        this.mContext = new WeakReference<>(context);
        this.mAppId = mAppId;
        this.mSignalInstance = AgoraAPIOnlySignal.getInstance(context, mAppId);
        this.mMtkCallbacks = new ArrayList<>();
        registerCallback(mMtkCallbacks);
    }

    private void registerCallback(final List<MTKCallback> mtkCallbacks) {
        if (mtkCallbacks == null) {
            throw new RuntimeException("callbacks should not be null");
        }
        mSignalInstance.callbackSet(new AbstractICallBack() {

            @Override
            public void onLoginSuccess(int i, int i1) {
                super.onLoginSuccess(i, i1);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onLoginSuccess(i, i1);
                }
            }

            @Override
            public void onLoginFailed(int i) {
                super.onLoginFailed(i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onLoginFailed(i);
                }
            }

            @Override
            public void onChannelJoined(String s) {
                super.onChannelJoined(s);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onChannelJoined(s);
                }
            }

            @Override
            public void onChannelJoinFailed(String s, int i) {
                super.onChannelJoinFailed(s, i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onChannelJoinFailed(s, i);
                }
            }

            @Override
            public void onChannelLeaved(String s, int i) {
                super.onChannelLeaved(s, i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onChannelLeaved(s, i);
                }
            }

            @Override
            public void onLogout(int i) {
                super.onLogout(i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onLogout(i);
                }
            }

            @Override
            public void onChannelUserJoined(String s, int i) {
                super.onChannelUserJoined(s, i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onChannelUserJoined(s, i);
                }
            }

            @Override
            public void onChannelUserLeaved(String s, int i) {
                super.onChannelUserLeaved(s, i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onChannelUserLeaved(s, i);
                }
            }

            @Override
            public void onMessageSendSuccess(String s) {
                super.onMessageSendSuccess(s);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onMessageSendSuccess(s);
                }
            }

            @Override
            public void onMessageInstantReceive(String s, int i, String s1) {
                super.onMessageInstantReceive(s, i, s1);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    MTKCallback mtkCallback = iterator.next();
                    try {
                        JSONObject jsonObject = new JSONObject(s1);
                        String adcType = jsonObject.getString(ADC_TYPE);

                        if (TextUtils.equals(adcType, "" + MESSAGE_TYPE_PEER_TO_PEER_RECEIVE_COM_MSG_SUCCESS)) {
                            mtkCallback.onMessageSendSuccess();
                            return;
                        }

                        String account = jsonObject.getString(ACCOUNT);
                        String message = jsonObject.getString(MESSAGE);
                        mtkCallback.onMarkedMessageInstantReceive(s, i, message);
                    } catch (JSONException e) {
                        e.printStackTrace();
                        mtkCallback.onMessageInstantReceive(s, i, s1);
                    }
                }
            }

            @Override
            public void onMessageChannelReceive(String s, String s1, int i, String s2) {
                super.onMessageChannelReceive(s, s1, i, s2);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    MTKCallback mtkCallback = iterator.next();
                    try {
                        JSONObject jsonObject = new JSONObject(s2);
                        String adcType = jsonObject.getString(ADC_TYPE);
                        String account = jsonObject.getString(ACCOUNT);
                        String channelId = jsonObject.getString(CHANNEL_ID);
                        String message = jsonObject.getString(MESSAGE);
                        mtkCallback.onMarkedMessageChannelReceive(s, s1, i, message);
                    } catch (JSONException e) {
                        e.printStackTrace();
                        mtkCallback.onMessageChannelReceive(s, s1, i, s2);
                    }
                }
            }

            @Override
            public void onMessageSendError(String s, int i) {
                super.onMessageSendError(s, i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onMessageSendError(s, i);
                }
            }

            @Override
            public void onError(String s, int i, String s1) {
                super.onError(s, i, s1);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onError(s, i, s1);
                }
            }

            @Override
            public void onReconnecting(int i) {
                super.onReconnecting(i);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onReconnecting(i);
                }
            }

            @Override
            public void onLog(String s) {
                super.onLog(s);
                Iterator<MTKCallback> iterator = mtkCallbacks.iterator();
                while (iterator.hasNext()) {
                    iterator.next().onLog(s);
                }
            }
        });
    }

    public void addCallback(MTKCallback mtkCallback) {
        mMtkCallbacks.add(mtkCallback);
    }

    public void addCallbacks(List<MTKCallback> mtkCallbacks) {
        mMtkCallbacks.addAll(mtkCallbacks);
    }

    public void removeCallback(MTKCallback mtkCallback) {
        mMtkCallbacks.remove(mtkCallback);
    }

    public void removeCallbacks(List<MTKCallback> mtkCallbacks) {
        mMtkCallbacks.removeAll(mtkCallbacks);
    }

    public void removeAllCallbacks() {
        mMtkCallbacks.clear();
    }

    public void unregisterCallback() {
        removeAllCallbacks();
        this.mMtkCallbacks = null;
        mSignalInstance.callbackSet(null);
    }

    public void login(String account) {
        login(account, NO_NEED_TOKEN, DEFAULT_RETRY_TIME_IN_S, RETRY_COUNT);
    }

    public void login(String account, String token) {
        login(account, token, DEFAULT_RETRY_TIME_IN_S, RETRY_COUNT);
    }

    public void login(String account, int retry_time_in_s, int retry_count) {
        login(account, NO_NEED_TOKEN, retry_time_in_s, retry_count);
    }

    public void login(String account, String token, int retry_time_in_s, int retry_count) {
        this.mAccount = account;
        if (this.mMtkCallbacks == null) {
            throw new RuntimeException("callbacks should not be null");
        }
        mSignalInstance.login2(mAppId, account, token, UID, DEVICE_ID, retry_time_in_s, retry_count);
    }

    public void logout() {
        mSignalInstance.logout();
    }

    public void joinChannel(String channelId) {
        this.mChannelId = channelId;
        mSignalInstance.channelJoin(channelId);
    }

    public void leaveChannel() {
        mSignalInstance.channelLeave(mChannelId);
    }

    public void sendInstantMessage(String account, String msg) {
        this.sendMarkedInstantMessage(MESSAGE_TYPE_PEER_TO_PEER_COMMON_MESSAGE, account, msg);
    }

    public void sendInstantMessageInJson(String account, String msg) {
        JSONObject jsonObject;
        try {
            jsonObject = new JSONObject(msg);
        } catch (JSONException e) {
            e.printStackTrace();
            throw new RuntimeException("in parameter must be valid json string " + msg);
        }
        this.sendMarkedInstantMessage(MESSAGE_TYPE_PEER_TO_PEER_JSON_MESSAGE, account, jsonObject);
    }

    private void sendMarkedInstantMessage(int type, String account, Object msg) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put(ADC_TYPE, type);
            jsonObject.put(ACCOUNT, mAccount);

            jsonObject.put(MESSAGE, msg);
            mSignalInstance.messageInstantSend(account, UID, jsonObject.toString(), MESSAGE_ID);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void sendChannelMessage(String msg) {
        this.sendMarkedChannelMessage(MESSAGE_TYPE_CHANNEL_COMMON_MESSAGE, msg);
    }

    public void sendChannelMessageInJson(String msg) {
        JSONObject jsonObject;
        try {
            jsonObject = new JSONObject(msg);
        } catch (JSONException e) {
            e.printStackTrace();
            throw new RuntimeException("in parameter must be valid json string " + msg);
        }
        this.sendMarkedChannelMessage(MESSAGE_TYPE_CHANNEL_JSON_MESSAGE, jsonObject);
    }

    private void sendMarkedChannelMessage(int type, Object msg) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put(ADC_TYPE, type);
            jsonObject.put(ACCOUNT, mAccount);
            jsonObject.put(CHANNEL_ID, mChannelId);

            jsonObject.put(MESSAGE, msg);

            mSignalInstance.messageChannelSend(mChannelId, jsonObject.toString(), MESSAGE_ID);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void sendPingToServer(String server, String msg) {
        JSONObject jsonObject;
        try {
            jsonObject = new JSONObject(msg);
        } catch (JSONException e) {
            e.printStackTrace();
            throw new RuntimeException("in parameter must be valid json string " + msg);
        }

        try {
            jsonObject.put(ADC_TYPE, MESSAGE_TYPE_SEND_PING_TO_SERVER_JSON_MESSAGE);
            jsonObject.put(REQUEST_ID, new Random(System.currentTimeMillis()).nextInt());
            mSignalInstance.messageInstantSend(server, UID, jsonObject.toString(), MESSAGE_ID);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void sendRequestToServer(String server, int requestId, String msg) {
        JSONObject jsonObject;
        try {
            jsonObject = new JSONObject(msg);
        } catch (JSONException e) {
            e.printStackTrace();
            throw new RuntimeException("in parameter must be valid json string " + msg);
        }

        try {
            jsonObject.put(ADC_TYPE, MESSAGE_TYPE_SEND_REQUEST_TO_SERVER_JSON_MESSAGE);
            jsonObject.put(REQUEST_ID, requestId);
            mSignalInstance.messageInstantSend(server, UID, jsonObject.toString(), MESSAGE_ID);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
