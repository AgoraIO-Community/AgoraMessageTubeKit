//
//  AgoraMessageTubeKit.h
//  AgoraMessageTubeKit
//
//  Created by CavanSu on 2018/5/28.
//  Copyright © 2018 CavanSu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraMessageTubeKit/SignalEcode.h>

typedef NS_ENUM(NSInteger, WorkMode) {
    WorkModeJoinChannelOnly,
    WorkModeLoginAndJoinChannel
};

@class AgoraMessageTubeKit;
@protocol AgoraMessageTubeKitDelegate <NSObject>
@optional
- (void)messageTubeDidLoginSuccess:(AgoraMessageTubeKit * _Nonnull)msgTube;
- (void)messageTubeDidLogout:(AgoraMessageTubeKit * _Nonnull)msgTube;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didLoginFailedWithError:(SignalEcode)error;

- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didJoinedChannelSuccessWithChannelId:(NSString * _Nonnull)channelId;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didJoinedChannelFailedWithChannelId:(NSString * _Nonnull)channelId error:(SignalEcode)error;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didLeavedChannelWithChannelId:(NSString * _Nonnull)channelId;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didUserJoinedChannelWithChannelId:(NSString * _Nonnull)channelId userAccount:(NSString * _Nonnull)userAccount;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didUserLeavedChannelWithChannelId:(NSString * _Nonnull)channelId userAccount:(NSString * _Nonnull)userAccount;

- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didReceivedPeerMessage:(NSString * _Nonnull)message remoteAccount:(NSString * _Nonnull)account;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didReceivedChannelMessage:(NSString * _Nonnull)message channelId:(NSString * _Nonnull)channelId remoteAccount:(NSString * _Nonnull)account;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didReceivedPeerJsonMessage:(NSDictionary * _Nonnull)msgDic remoteAccount:(NSString * _Nonnull)account;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didReceivedChannelJsonMessage:(NSDictionary * _Nonnull)msgDic channelId:(NSString * _Nonnull)channelId remoteAccount:(NSString * _Nonnull)account;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didRemotePeerReceviedMessageSuccess:(NSString * _Nonnull)account;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didChannelMessageSendSuccessWithChannelId:(NSString * _Nonnull)channelId;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didSendPeerOrChannelMessageFailedWithError:(SignalEcode)error messageId:(nullable NSString *)messageId;

- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didOccurErrorCode:(SignalEcode)code errorName:(NSString * _Nonnull)name errorDesc:(NSString * _Nonnull)desc;
- (void)messageTubeConnectionDidLost:(AgoraMessageTubeKit * _Nonnull)msgTube;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube reconnectingWithRetryTimes:(NSInteger)times;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube reconnectedSuccessWithRetryTimes:(NSInteger)times;
- (void)messageTubeReconnectedTimeOut:(AgoraMessageTubeKit * _Nonnull)msgTube;

- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube responseJsonFromDataServer:(NSDictionary * _Nonnull)jsonDic;
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube pongJsonFromDataServer:(NSDictionary * _Nonnull)jsonDic;
- (nullable NSDictionary *)messageTubeSendingPingUpdateJson:(AgoraMessageTubeKit * _Nonnull)msgTube;
@end

@interface AgoraMessageTubeKit: NSObject
@property (nonatomic, weak) id<AgoraMessageTubeKitDelegate> delegate;
@property (nonatomic, readonly) BOOL isInChannel;
@property (nonatomic, readonly) BOOL isLogin;
+ (void)setupLogPath:(NSString *)logPath logFileNumber:(NSInteger)number;
+ (instancetype)sharedMessageTubeKitWithAppId:(NSString *)appId workMode:(WorkMode)workMode;
+ (instancetype)getInstance;
+ (void)destroy;
- (void)setupReconnectTimes:(NSInteger)times intervalTime:(NSInteger)seconds;
- (void)loginWithAccount:(NSString *)account;
- (void)logout;
- (void)joinChannelWithChannelId:(NSString *)channelId account:(nullable NSString *)account;
- (void)leaveChannel;
- (void)sendMessageToPeer:(NSString *)account message:(NSString *)message messageId:(nullable NSString *)messageId;
- (void)sendMessageToPeer:(NSString *)account jsonMsgDic:(NSDictionary *)msgDic messageId:(nullable NSString *)messageId;
- (void)sendChannelMessage:(NSString *)message messageId:(nullable NSString *)messageId;
- (void)sendChannelJsonMessage:(NSDictionary *)msgDic messageId:(NSString *)messageId;
- (void)startPingToServer:(NSString *)server intervalSecond:(int)interval jsonDic:(nullable NSDictionary *)jsonDic;
- (void)stopPingToServer;
- (void)requestToServer:(NSString *)server jsonDic:(NSDictionary *)jsonDic;
@end
