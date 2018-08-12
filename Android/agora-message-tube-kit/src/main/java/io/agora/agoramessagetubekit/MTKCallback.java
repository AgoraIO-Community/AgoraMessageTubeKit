package io.agora.agoramessagetubekit;

public interface MTKCallback {

    // onLoginSuccess(int uid, int fd)，登录成功回调
    // uid 固定填0，fd 仅供 Agora 内部使用
    void onLoginSuccess(int uid, int fd);

    void onLoginFailed(int ecode);

    // onChannelJoined(String channelID), 加入频道回调
    void onChannelJoined(String channelID);

    // onChannelJoinFailed(String channelID,int ecode), 加入频道失败回调
    void onChannelJoinFailed(String channelID, int ecode);

    // onChannelLeaved(String channelID,int ecode), 离开频道回调
    void onChannelLeaved(String channelID, int ecode);

    // onLogout(int ecode), 退出登录回调
    void onLogout(int ecode);

    // onChannelUserJoined(String account,int uid), 其他用户加入频道回调
    void onChannelUserJoined(String account, int uid);

    // onChannelUserLeaved(String account,int uid), 其他用户离开频道回调
    void onChannelUserLeaved(String account, int uid);

    // onMessageInstantReceive(String account,int uid,String msg), 接收方收到消息后，接收方收到的回调
    void onMessageInstantReceive(String account, int uid, String msg);

    void onMarkedMessageInstantReceive(String account, int uid, String msg);

    // onMessageChannelReceive(String channelID, String account,int uid,String msg), 收到频道消息回调
    void onMessageChannelReceive(String channelID, String account, int uid, String msg);

    void onMarkedMessageChannelReceive(String channelID, String account, int uid, String msg);

    // onMessageSendSuccess(String messageID), 消息已发送成功回调
    void onMessageSendSuccess(String messageID);

    void onMessageSendSuccess();

    // onMessageSendError(String messageID,int ecode), 消息发送失败回调
    void onMessageSendError(String messageID, int ecode);

    // onError(String name,int ecode,String desc), 出错回调
    void onError(String name, int ecode, String desc);

    // onReconnecting(int nretry), 连接丢失回调
    void onReconnecting(int nretry);

    void onLog(String s);

}
