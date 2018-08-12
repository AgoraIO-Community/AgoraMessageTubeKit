package io.agora.agoramessagetubekit;

public abstract class AbstractMTKCallback implements MTKCallback {

    @Override
    public void onLoginSuccess(int uid, int fd) {

    }

    @Override
    public void onLoginFailed(int ecode) {

    }

    @Override
    public void onChannelJoined(String channelID) {

    }

    @Override
    public void onChannelJoinFailed(String channelID, int ecode) {

    }

    @Override
    public void onChannelLeaved(String channelID, int ecode) {

    }

    @Override
    public void onLogout(int ecode) {

    }

    @Override
    public void onChannelUserJoined(String account, int uid) {

    }

    @Override
    public void onChannelUserLeaved(String account, int uid) {

    }

    @Override
    public void onMessageInstantReceive(String account, int uid, String msg) {

    }

    @Override
    public void onMarkedMessageInstantReceive(String account, int uid, String msg) {

    }

    @Override
    public void onMessageChannelReceive(String channelID, String account, int uid, String msg) {

    }

    @Override
    public void onMarkedMessageChannelReceive(String channelID, String account, int uid, String msg) {

    }

    @Override
    public void onMessageSendSuccess(String messageID) {

    }

    @Override
    public void onMessageSendError(String messageID, int ecode) {

    }

    @Override
    public void onMessageSendSuccess() {

    }

    @Override
    public void onError(String name, int ecode, String desc) {

    }

    @Override
    public void onReconnecting(int nretry) {

    }

    @Override
    public void onLog(String s) {

    }
}
