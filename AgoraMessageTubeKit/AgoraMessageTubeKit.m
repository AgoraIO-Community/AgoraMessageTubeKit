//
//  AgoraMessageTubeKit.m
//  AgoraMessageTubeKit
//
//  Created by CavanSu on 2018/5/28.
//  Copyright © 2018 CavanSu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraSigKit/AgoraSigKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "AgoraMessageTubeKit.h"
#import "SignalStatus.h"
#import "LCLLogFile.h"
#import "UnRepeatRand.h"

#define isDebug 0

@interface AgoraMessageTubeKit () <NSCopying>
@property (nonatomic, strong) AgoraAPI *agoraKit;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) NSDictionary *lastPingJsonDic;
@property (nonatomic, assign) ChannelStatus channelStatus;
@property (nonatomic, assign) LoginStatus logInStatus;
@property (nonatomic, assign) WorkMode workMode;
@property (nonatomic, assign) NSInteger maxReconnectTimes;
@property (nonatomic, assign) NSInteger currentReconnectTimes;
@property (nonatomic, assign) NSInteger intervalSeconds;
@property (nonatomic, assign) BOOL isInitLogPath;
@property (nonatomic, assign) BOOL isReconnectedToJoinChannel;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *channelId;
@end

@implementation AgoraMessageTubeKit

static AgoraMessageTubeKit *messageTubeKit = nil;
static NSString *customerLogPath = nil;
static NSInteger logFileNumber = -1;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (messageTubeKit == nil) {
        messageTubeKit = [super allocWithZone:zone];
    }
    return messageTubeKit;
}

- (id)copyWithZone:(NSZone *)zone {
    return messageTubeKit;
}

#pragma mark - DidSet
- (void)setAppId:(NSString *)appId {
    _appId = [appId copy];
    [self setupDefaultValue];
    [self observerAgoraKitCallback];
}

- (void)setChannelStatus:(ChannelStatus)channelStatus {
    _channelStatus = channelStatus;
    [self debugLog:[NSString stringWithFormat:@"ChannelStatus: %ld", (long)channelStatus]];
    
    switch (_channelStatus) {
        case ChannelStatusJoiningChannel:
            [self joinChannel];
            break;
        case ChannelStatusInChannel:
            break;
        case ChannelStatusLeaveingChannel:
            [self leaveChannel];
            break;
        case ChannelStatusOutChannel:
            break;
        default:
            break;
    }
}

- (void)setLogInStatus:(LoginStatus)logInStatus {
    _logInStatus = logInStatus;
    [self debugLog:[NSString stringWithFormat:@"LogInStatus: %ld", (long)logInStatus]];
    
    switch (_logInStatus) {
        case LoginStatusLoginIng:
            [self login];
            break;
        case LoginStatusLogin:
            if (self.workMode == WorkModeLoginAndJoinChannel) {
                if ([self.delegate respondsToSelector:@selector(messageTubeDidLoginSuccess:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate messageTubeDidLoginSuccess:self];
                    });
                }
            }
            break;
        case LoginStatusLogOutIng:
            if (self.channelStatus == ChannelStatusInChannel) {
                self.isReconnectedToJoinChannel = false;
                self.channelStatus = ChannelStatusOutChannel;
                if ([self.delegate respondsToSelector:@selector(messageTube:didLeavedChannelWithChannelId:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate messageTube:self didLeavedChannelWithChannelId:self.channelId];
                    });
                }
            }
            [self.agoraKit logout];
            break;
        case LoginStatusLogOut:
            break;
        default:
            break;
    }
}

#pragma mark - Public Api
+ (void)setupLogPath:(NSString *)logPath logFileNumber:(NSInteger)number {
    customerLogPath = logPath;
    logFileNumber = number;
}

+ (instancetype)sharedMessageTubeKitWithAppId:(NSString *)appId workMode:(WorkMode)workMode {
    if (messageTubeKit == nil) {
        messageTubeKit = [[AgoraMessageTubeKit alloc] init];
        messageTubeKit.appId = appId;
        messageTubeKit.workMode = workMode;
    }
    
    return messageTubeKit;
}

+ (instancetype)getInstance {
    return messageTubeKit;
}

+ (void)destroy {
    messageTubeKit = nil;
}

- (void)setupReconnectTimes:(NSInteger)times intervalTime:(NSInteger)seconds{
    self.maxReconnectTimes = times;
    self.intervalSeconds = seconds;
}

- (void)loginWithAccount:(NSString *)account {
    if (self.workMode == WorkModeJoinChannelOnly) {
        return;
    }
    
    self.account = account;
    self.logInStatus = LoginStatusLoginIng;
}

- (void)logout {
    if (self.workMode == WorkModeJoinChannelOnly) {
        return;
    }
    
    self.logInStatus = LoginStatusLogOutIng;
}

- (void)joinChannelWithChannelId:(NSString *)channelId account:(NSString *)account {
    if (_channelStatus == ChannelStatusInChannel) {
        if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
            [self.delegate messageTube:self didOccurErrorCode:SignalEcodeAlreadyInChannel errorName:@"AlreadyInChannel" errorDesc:@"AlreadyInChannel"];
        }
        return;
    }
    self.channelId = channelId;
    self.account = account;
    self.channelStatus = ChannelStatusJoiningChannel;
}

- (void)leaveChannel {
    BOOL isInsideChannel = [self isInsideChannel];
    if (!isInsideChannel) return;
    [self.agoraKit channelLeave:self.channelId];
}

- (void)sendMessageToPeer:(NSString *)account message:(NSString *)message messageId:(NSString *)messageId {
    BOOL isInsideLogin = [self isInsideLogin];
    if (!isInsideLogin) return;

    NSDictionary *msgDic = @{@"ADCType": @(MessageTypePeerToPeerCommonMessage), @"account":self.account, @"message": message};
    NSString *jsonString = [self OutKeyValueDicExceptionCheck:msgDic];
    if (jsonString == nil || jsonString.length == 0) {
        return;
    }
    
    [self.agoraKit messageInstantSend:account uid:0 msg:jsonString msgID:messageId];
}

- (void)sendMessageToPeer:(NSString *)account jsonMsgDic:(NSDictionary *)msgDic messageId:(NSString *)messageId {
    BOOL isInsideLogin = [self isInsideLogin];
    if (!isInsideLogin) return;
    
    NSDictionary *jsonDic = @{@"ADCType": @(MessageTypePeerToPeerJsonMessage), @"account":self.account, @"message": msgDic};
    NSString *jsonString = [self OutKeyValueDicExceptionCheck:jsonDic];
    if (jsonString == nil || jsonString.length == 0) {
        return;
    }
    
    [self.agoraKit messageInstantSend:account uid:0 msg:jsonString msgID:messageId];
}

- (void)sendChannelMessage:(NSString *)message messageId:(NSString *)messageId {
    BOOL isInsideChannel = [self isInsideChannel];
    if (!isInsideChannel) return;
    
    NSDictionary *msgDic = @{@"ADCType": @(MessageTypeChannelJsonMessage), @"account":self.account, @"channelId":self.channelId, @"message": message};
    NSString *jsonString = [self OutKeyValueDicExceptionCheck:msgDic];
    if (jsonString == nil || jsonString.length == 0) {
        return;
    }
    
    [self.agoraKit messageChannelSend:self.channelId msg:jsonString msgID:messageId];
}

- (void)sendChannelJsonMessage:(NSDictionary *)msgDic messageId:(NSString *)messageId {
    BOOL isInsideChannel = [self isInsideChannel];
    if (!isInsideChannel) return;
    
    NSDictionary *jsonDic = @{@"ADCType": @(MessageTypeChannelJsonMessage), @"account":self.account, @"channelId":self.channelId, @"message": msgDic};
    NSString *jsonString = [self OutKeyValueDicExceptionCheck:jsonDic];
    if (jsonString == nil || jsonString.length == 0) {
        return;
    }
    
    [self.agoraKit messageChannelSend:self.channelId msg:jsonString msgID:messageId];
}

- (void)startPingToServer:(NSString *)server intervalSecond:(int)interval jsonDic:(NSDictionary *)jsonDic {
    BOOL isInsideLogin = [self isInsideLogin];
    if (!isInsideLogin) return;
    
    if (self.timer) return;
    
    [self createTimerOnSendPingToServer:server intervalSecond:interval jsonDic:jsonDic];
}

- (void)stopPingToServer {
    [self removeTimerOnSendPingToServer];
}

- (void)requestToServer:(NSString *)server jsonDic:(NSDictionary *)jsonDic {
    BOOL isInsideLogin = [self isInsideLogin];
    if (!isInsideLogin) return;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:jsonDic];
    dic[@"ADCType"] = @(MessageTypeRequestResponseDataServer);
    NSString *jsonString = [self OutKeyValueDicExceptionCheck:dic];
    if (jsonString == nil || jsonString.length == 0) {
        return;
    }
    
    [self.agoraKit messageInstantSend:server uid:0 msg:jsonString msgID:nil];
}

#pragma mark - Private Api
- (BOOL)isInChannel {
    if (self.channelStatus == ChannelStatusOutChannel) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isLogin {
    if (self.logInStatus == LoginStatusLogOut) {
        return NO;
    } else {
        return YES;
    }
}

- (void)login {
    [self.agoraKit login2:self.appId account:self.account token:@"_no_need_token" uid:0 deviceID:nil retry_time_in_s:30 retry_count:3];
}

- (void)joinChannel {
    // retry_time_in_s: retry_count:
    if (self.workMode == WorkModeJoinChannelOnly) {
        [self.agoraKit login2:self.appId account:self.account token:@"_no_need_token" uid:0 deviceID:nil retry_time_in_s:30 retry_count:3];
    } else {
        [self.agoraKit channelJoin:self.channelId];
    }
}

- (NSString *)getJsonStringWithDic:(NSDictionary *)dic {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (BOOL)isInsideChannel {
    if (_channelStatus == ChannelStatusOutChannel) {
        if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
            [self.delegate messageTube:self didOccurErrorCode:SignalEcodeOutChannel errorName:@"OutChannel" errorDesc:@"OutChannel"];
        }
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isInsideLogin {
    if (_logInStatus == LoginStatusLogOut) {
        if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
            [self.delegate messageTube:self didOccurErrorCode:SignalEcodeLogoutAlreadyLogout errorName:@"Already Logout" errorDesc:@"Already Logout"];
        }
        return NO;
    } else {
        return YES;
    }
}

// Send a notification to remote peer which send success
- (void)sendNotificationToRemotePeerThatSendMsgSuucessWithAccount:(NSString *)account {
    NSDictionary *msgDic = @{@"ADCType": @(MessageTypePeerToPeerReceiveMsgSuccess), @"account":self.account, @"message": @"1"};
    NSString *jsonString = [self getJsonStringWithDic:msgDic];
    [self.agoraKit messageInstantSend:account uid:0 msg:jsonString msgID:nil];
}

- (void)setupDefaultValue {
    self.channelStatus = ChannelStatusOutChannel;
    self.logInStatus = LoginStatusLogOut;
    self.maxReconnectTimes = 0;
    self.currentReconnectTimes = 0;
    self.isInitLogPath = NO;
}

- (void)createLogFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *logFolderPath = nil;
    NSString *logFolderName = @"TubeLog";
    
    if (customerLogPath) {
        logFolderPath = [customerLogPath stringByAppendingPathComponent:logFolderName];
    } else {
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        logFolderPath = [documentPath stringByAppendingPathComponent:logFolderName];
    }
    
    [self debugLog:[NSString stringWithFormat:@"logFolderPath: %@", logFolderPath]];
    
    if (![manager fileExistsAtPath:logFolderPath]) {
        [manager createDirectoryAtPath:logFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else { // if logFolderPath exited, get all files under this folder
        NSDirectoryEnumerator *direcEnumerator = [manager enumeratorAtPath:logFolderPath];
        NSMutableArray *logFilesArray = [NSMutableArray array];
        NSString *file = nil;
        while (file = [direcEnumerator nextObject]) {
            NSString *fullPath = logFolderPath;
            fullPath = [fullPath stringByAppendingPathComponent:file];
            [logFilesArray addObject:fullPath];
        }
        
        NSInteger maxFileNumber = 5;
        if (logFileNumber != -1 && logFileNumber > 0) {
            maxFileNumber = logFileNumber;
        }
        
        // if files number great than , delete earliest file
        if (logFilesArray.count >= maxFileNumber) {
            NSInteger earliest = 0;
            NSDate *lastFileCreatedDate = nil;
            
            for (NSInteger i = 0; i < logFilesArray.count; i ++) {
                NSString *filePath = logFilesArray[i];
                NSDictionary *fileDic = [manager attributesOfItemAtPath:filePath error:nil];
                
                if (fileDic != nil) {
                    NSDate *fileCreatedDate = [fileDic objectForKey:NSFileCreationDate];

                    if (lastFileCreatedDate != nil) {
                        NSComparisonResult result = [lastFileCreatedDate compare:fileCreatedDate];
                        if (result == NSOrderedDescending) {
                            lastFileCreatedDate = fileCreatedDate;
                            earliest = i;
                        }
                    } else {
                        lastFileCreatedDate = fileCreatedDate;
                    }
                }
            }
            NSError *error = nil;
            [manager removeItemAtPath:logFilesArray[earliest] error:&error];
            if (error) {
                if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
                    [self.delegate messageTube:self didOccurErrorCode:SignalEcodeRemoveEarliestLogError errorName:@"SignalEcodeRemoveEarliestLogError" errorDesc:@"Remove Earliest Log File Error"];
                }
            }
        }
    }
    
    NSString *time = [self.dateFormatter stringFromDate:[NSDate date]];
    NSString *logFilePath = [NSString stringWithFormat:@"%@/AgoraTubeLog_%@.log", logFolderPath, time];
    
    [LCLLogFile setPath:logFilePath];
    self.isInitLogPath = YES;
}

- (void)reconnecting {
    if (self.currentReconnectTimes == 0) {
        if ([self.delegate respondsToSelector:@selector(messageTubeConnectionDidLost:)]) {
            [self.delegate messageTubeConnectionDidLost:self];
        }
    }
    
    if (self.maxReconnectTimes <= self.currentReconnectTimes) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.intervalSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.workMode == WorkModeJoinChannelOnly) {
            self.channelStatus = ChannelStatusJoiningChannel;
        } else {
            self.logInStatus = LoginStatusLoginIng;
        }
    });
    
    self.currentReconnectTimes += 1;
    
    if ([self.delegate respondsToSelector:@selector(messageTube:reconnectingWithRetryTimes:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate messageTube:self reconnectingWithRetryTimes:self.currentReconnectTimes];
        });
    }
}

- (NSString *)OutKeyValueDicExceptionCheck:(NSDictionary *)dic {
    NSString *jsonString = nil;
    @try {
        jsonString = [self getJsonStringWithDic:dic];
    }
    @catch(NSException *exception) {
        if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
            [self.delegate messageTube:self didOccurErrorCode:SignalEcodeInputJsonError errorName:exception.name errorDesc:exception.reason];
        }
    }
    return jsonString;
}

- (void)createTimerOnSendPingToServer:(NSString *)server intervalSecond:(int)interval jsonDic:(NSDictionary *)jsonDic {
    dispatch_queue_t queue = dispatch_queue_create("PingQueue", DISPATCH_QUEUE_CONCURRENT);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, 0);
    uint64_t intervalTime = (uint64_t)(interval * NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, start, intervalTime, 0);

    dispatch_source_set_event_handler(self.timer, ^{
        if ([self.delegate respondsToSelector:@selector(messageTubeSendingPingUpdateJson:)]) {
            NSDictionary *newJsonDic = [self.delegate messageTubeSendingPingUpdateJson:self];
            if (newJsonDic != nil) {
                [self sendPingToServer:server jsonDic:newJsonDic];
            } else {
                if (jsonDic != nil) {
                    [self sendPingToServer:server jsonDic:jsonDic];
                } else {
                    if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
                        [self.delegate messageTube:self didOccurErrorCode:SignalEcodePingJsonError errorName:@"Ping Json nil" errorDesc:@"Ping Json nil"];
                    }
                }
            }
        } else {
            if (jsonDic != nil) {
                [self sendPingToServer:server jsonDic:jsonDic];
            } else {
                if ([self.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
                    [self.delegate messageTube:self didOccurErrorCode:SignalEcodePingJsonError errorName:@"Ping Json nil" errorDesc:@"Ping Json nil"];
                }
            }
        }
    });
    dispatch_resume(self.timer);
}

- (void)removeTimerOnSendPingToServer {
    if (self.timer) {
        dispatch_cancel(self.timer);
        self.timer = nil;
    }
}

- (void)sendPingToServer:(NSString *)server jsonDic:(NSDictionary *)jsonDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:jsonDic];
    dic[@"ADCType"] = @(MessageTypePingPongWithDataServer);
    dic[@"requestId"] = @([UnRepeatRand rand]);
    NSString *jsonString = [self OutKeyValueDicExceptionCheck:dic];
    if (jsonString == nil || jsonString.length == 0) {
        return;
    }
    [self.agoraKit messageInstantSend:server uid:0 msg:jsonString msgID:nil];
    [NSThread currentThread].name = @"PingServerThread";
    
    [self debugLog:[NSString stringWithFormat:@"currentThread: %@", [NSThread currentThread]]];
}

- (void)observerAgoraKitCallback {
    AgoraMessageTubeKit* __weak weakself = self;
    
    // LogIn and Join channel
    weakself.agoraKit.onLoginSuccess = ^(uint32_t uid, int fd) {
        [weakself debugLog:[NSString stringWithFormat:@"onLoginSuccess, uid: %lu, fd: %d", (unsigned long)uid, fd]];
        
        if (weakself.workMode == WorkModeJoinChannelOnly) { // skip login, and join channel directly
            [weakself.agoraKit channelJoin:weakself.channelId];
        }
        
        if (weakself.isReconnectedToJoinChannel == YES && weakself.workMode == WorkModeLoginAndJoinChannel) { // need to reconnect to channel
            [weakself.agoraKit channelJoin:weakself.channelId];
        }
        
        weakself.logInStatus = LoginStatusLogin;
    };
    
    _agoraKit.onLogout = ^(AgoraEcode ecode) {
        [weakself debugLog:[NSString stringWithFormat:@"onLogout, AgoraEcode: %lu", (unsigned long)ecode]];
        
        if (weakself.workMode == WorkModeJoinChannelOnly) { // skip login, and join channel directly
            weakself.channelStatus = ChannelStatusOutChannel;
            weakself.logInStatus = LoginStatusLogOut;
            
            if (ecode == AgoraEcode_LOGOUT_E_USER) { // normal exit
                if ([weakself.delegate respondsToSelector:@selector(messageTube:didLeavedChannelWithChannelId:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.delegate messageTube:weakself didLeavedChannelWithChannelId:weakself.channelId];
                    });
                }
            } else if (ecode == AgoraEcode_LOGOUT_E_NET) {
                [weakself reconnecting];
            } else if (ecode == AgoraEcode_LOGOUT_E_KICKED) {
                if ([weakself.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.delegate messageTube:weakself didOccurErrorCode:SignalEcodeLogoutKicked errorName:@"Logout by kicked" errorDesc:@"Logout by kicked"];
                    });
                }
            }
        } else {
            weakself.logInStatus = LoginStatusLogOut;
            
            if (ecode == AgoraEcode_LOGOUT_E_USER) { // normal exit
                if ([weakself.delegate respondsToSelector:@selector(messageTubeDidLogout:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.delegate messageTubeDidLogout:weakself];
                    });
                }
            } else if (ecode == AgoraEcode_LOGOUT_E_NET) {
                [weakself reconnecting];
            } else if (ecode == AgoraEcode_LOGOUT_E_KICKED) {
                if ([weakself.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself.delegate messageTube:weakself didOccurErrorCode:SignalEcodeLogoutKicked errorName:@"Logout by kicked" errorDesc:@"Logout by kicked"];
                    });
                }
            }
        }
    };
    
    _agoraKit.onLoginFailed = ^(AgoraEcode ecode) {
        [weakself debugLog:[NSString stringWithFormat:@"onLoginFailed, AgoraEcode: %lu", (unsigned long)ecode]];
        
        if (weakself.workMode == WorkModeJoinChannelOnly) {
            weakself.channelStatus = ChannelStatusOutChannel;
            weakself.logInStatus = LoginStatusLogOut;
            
            if (ecode == AgoraEcode_LOGIN_E_NET) {
                if (weakself.channelStatus != ChannelStatusInChannel) {
                    [weakself reconnecting];
                }
            }
            if ([weakself.delegate respondsToSelector:@selector(messageTube:didJoinedChannelFailedWithChannelId:error:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.delegate messageTube:weakself didJoinedChannelFailedWithChannelId:weakself.channelId error:(SignalEcode)ecode];
                });
            }
        } else {
            weakself.logInStatus = LoginStatusLogOut;
            
            if (ecode == AgoraEcode_LOGIN_E_NET) {
                [weakself reconnecting];
            }
            if ([weakself.delegate respondsToSelector:@selector(messageTube:didLoginFailedWithError:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.delegate messageTube:weakself didLoginFailedWithError:(SignalEcode)ecode];
                });
            }
        }
    };
    
    _agoraKit.onChannelJoined = ^(NSString* channelID) {
        [weakself debugLog:[NSString stringWithFormat:@"onChannelJoinFailed, channelID: %@", channelID]];
        
        weakself.channelStatus = ChannelStatusInChannel;
        weakself.isReconnectedToJoinChannel = YES;
        
        if (weakself.currentReconnectTimes != 0) {
            if ([weakself.delegate respondsToSelector:@selector(messageTube:reconnectedSuccessWithRetryTimes:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.delegate messageTube:weakself reconnectedSuccessWithRetryTimes:weakself.currentReconnectTimes];
                    weakself.currentReconnectTimes = 0;
                });
            } else {
                weakself.currentReconnectTimes = 0;
            }
        } else {
            if ([weakself.delegate respondsToSelector:@selector(messageTube:didJoinedChannelSuccessWithChannelId:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.delegate messageTube:weakself didJoinedChannelSuccessWithChannelId:channelID];
                });
            }
        }
    };
    
    _agoraKit.onChannelJoinFailed = ^(NSString *channelID, AgoraEcode ecode) {
        [weakself debugLog:[NSString stringWithFormat:@"onChannelJoinFailed, channelID: %@, AgoraEcode: %lu", channelID, (unsigned long)ecode]];
        
        weakself.channelStatus = ChannelStatusOutChannel;
        if ([weakself.delegate respondsToSelector:@selector(messageTube:didJoinedChannelFailedWithChannelId:error:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate messageTube:weakself didJoinedChannelFailedWithChannelId:channelID error:(SignalEcode)ecode];
            });
        }
    };
    
    _agoraKit.onChannelLeaved = ^(NSString* channelID, AgoraEcode ecode) {
        [weakself debugLog:[NSString stringWithFormat:@"onChannelLeaved, channelID: %@, AgoraEcode: %lu", channelID, (unsigned long)ecode]];

        weakself.isReconnectedToJoinChannel = NO;
        
        if (weakself.workMode == WorkModeJoinChannelOnly) {
            [weakself.agoraKit logout];
        } else {
            weakself.channelStatus = ChannelStatusOutChannel;
            if ([weakself.delegate respondsToSelector:@selector(messageTube:didLeavedChannelWithChannelId:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.delegate messageTube:weakself didLeavedChannelWithChannelId:weakself.channelId];
                });
            }
        }
    };
    
    _agoraKit.onChannelUserJoined = ^(NSString* account, uint32_t uid) {
        [weakself debugLog:[NSString stringWithFormat:@"onChannelUserJoined, account: %@, uid: %u", account, uid]];
        
        if ([weakself.delegate respondsToSelector:@selector(messageTube:didUserJoinedChannelWithChannelId:userAccount:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate messageTube:weakself didUserJoinedChannelWithChannelId:weakself.channelId userAccount:account];
            });
        }
    };
    
    _agoraKit.onChannelUserLeaved = ^(NSString* account, uint32_t uid) {
        [weakself debugLog:[NSString stringWithFormat:@"onChannelUserLeaved, account: %@, uid: %u", account, uid]];
        
        if (![account isEqualToString: weakself.account]) {
            if ([weakself.delegate respondsToSelector:@selector(messageTube:didUserLeavedChannelWithChannelId:userAccount:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.delegate messageTube:weakself didUserLeavedChannelWithChannelId:weakself.channelId userAccount:account];
                });
            }
        }
    };
    
    // Send / Recevie Peer and Channel Message
    _agoraKit.onMessageInstantReceive = ^(NSString* account, uint32_t uid, NSString* msg) {
        NSData *jsonData = [msg dataUsingEncoding:NSUTF8StringEncoding];
        
        if (jsonData) {
            NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            if (jsonDic) {
                MessageType type = [[jsonDic objectForKey:@"ADCType"] intValue];
                
                // App with Server communication
                if (MessageTypePingPongWithDataServer == type) {
                    if ([weakself.delegate respondsToSelector:@selector(messageTube:pongJsonFromDataServer:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:jsonDic];
                            [dic removeObjectForKey:@"ADCType"];
                            [weakself.delegate messageTube:weakself pongJsonFromDataServer:dic];
                        });
                    }
                } else if (MessageTypeRequestResponseDataServer == type) {
                    if ([weakself.delegate respondsToSelector:@selector(messageTube:responseJsonFromDataServer:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:jsonDic];
                            [dic removeObjectForKey:@"ADCType"];
                            [weakself.delegate messageTube:weakself responseJsonFromDataServer:dic];
                        });
                    }
                }
                
                // Peer With Peer communication
                if (MessageTypePeerToPeerCommonMessage == type) {
                    [weakself sendNotificationToRemotePeerThatSendMsgSuucessWithAccount:account];
                    // Callback Message
                    if ([weakself.delegate respondsToSelector:@selector(messageTube:didReceivedPeerMessage:remoteAccount:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *account = [jsonDic objectForKey:@"account"];
                            NSString *message = [jsonDic objectForKey:@"message"];
                            [weakself.delegate messageTube:weakself didReceivedPeerMessage:message remoteAccount:account];
                        });
                    }
                } else if (MessageTypePeerToPeerReceiveMsgSuccess == type) {
                    if ([weakself.delegate respondsToSelector:@selector(messageTube:didRemotePeerReceviedMessageSuccess:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *account = [jsonDic objectForKey:@"account"];
                            [weakself.delegate messageTube:weakself didRemotePeerReceviedMessageSuccess:account];
                        });
                    }
                } else if (MessageTypePeerToPeerJsonMessage == type) {
                    [weakself sendNotificationToRemotePeerThatSendMsgSuucessWithAccount:account];
                    if ([weakself.delegate respondsToSelector:@selector(messageTube:didReceivedPeerJsonMessage:remoteAccount:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *account = [jsonDic objectForKey:@"account"];
                            NSDictionary *msgDic = [jsonDic objectForKey:@"message"];
                            [weakself.delegate messageTube:weakself didReceivedPeerJsonMessage:msgDic remoteAccount:account];
                        });
                    }
                }
            }
        }
    };
    
    _agoraKit.onMessageChannelReceive = ^(NSString* channelID, NSString* account, uint32_t uid, NSString* msg) {
        NSData *jsonData = [msg dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            if (jsonDic) {
                NSString *account = [jsonDic objectForKey:@"account"];
                MessageType type = [[jsonDic objectForKey:@"ADCType"] intValue];
                
                if ([account isEqualToString:weakself.account]) {
                    if ([weakself.delegate respondsToSelector:@selector(messageTube:didChannelMessageSendSuccessWithChannelId:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *channelId = [jsonDic objectForKey:@"channelId"];
                            [weakself.delegate messageTube:weakself didChannelMessageSendSuccessWithChannelId:channelId];
                        });
                    }
                } else {
                    NSString *channelId = [jsonDic objectForKey:@"channelId"];
                    if (MessageTypeChannelCommonMessage == type) {
                        if ([weakself.delegate respondsToSelector:@selector(messageTube:didReceivedChannelMessage:channelId:remoteAccount:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *message = [jsonDic objectForKey:@"message"];
                                [weakself.delegate messageTube:weakself didReceivedChannelMessage:message channelId:channelId remoteAccount:account];
                            });
                        }
                    } else if (MessageTypeChannelJsonMessage == type) {
                        if ([weakself.delegate respondsToSelector:@selector(messageTube:didReceivedChannelJsonMessage:channelId:remoteAccount:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSDictionary *msgDic = [jsonDic objectForKey:@"message"];
                                [weakself.delegate messageTube:weakself didReceivedChannelJsonMessage:msgDic channelId:channelId remoteAccount:account];
                            });
                        }
                    }
                }
            }
        }
    };
    
    _agoraKit.onMessageSendError = ^(NSString* messageID, AgoraEcode ecode) {
        if ([weakself.delegate respondsToSelector:@selector(messageTube:didSendPeerOrChannelMessageFailedWithError:messageId:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate messageTube:weakself didSendPeerOrChannelMessageFailedWithError:(SignalEcode)ecode messageId:messageID];
            });
        }
    };
    
    // Error
    _agoraKit.onError = ^(NSString* name, AgoraEcode ecode, NSString* desc) {
        if ([weakself.delegate respondsToSelector:@selector(messageTube:didOccurErrorCode:errorName:errorDesc:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate messageTube:weakself didOccurErrorCode:(SignalEcode)ecode errorName:name errorDesc:desc];
            });
        }
    };
    
    _agoraKit.onReconnecting = ^(uint32_t nretry) {
    };
    
    _agoraKit.onReconnected = ^(int fd) {
    };
    
    _agoraKit.onChannelUserList = ^(NSMutableArray* accounts, NSMutableArray* uids) {
    };
    
    _agoraKit.onChannelQueryUserNumResult = ^(NSString* channelID, AgoraEcode ecode, int num) {
    };
    
    _agoraKit.onChannelQueryUserIsIn = ^(NSString *channelID, NSString *account, int isIn) {
    };
    
    _agoraKit.onChannelAttrUpdated = ^(NSString* channelID, NSString* name, NSString* value, NSString* type) {
    };
    
    _agoraKit.onInviteReceived = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
    };
    
    _agoraKit.onInviteReceivedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid) {
    };
    
    _agoraKit.onInviteAcceptedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
    };
    
    _agoraKit.onInviteRefusedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
    };
    
    _agoraKit.onInviteFailed = ^(NSString* channelID, NSString* account, uint32_t uid, AgoraEcode ecode, NSString *extra) {
    };
    
    _agoraKit.onInviteEndByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
    };
    
    _agoraKit.onInviteEndByMyself = ^(NSString* channelID, NSString *account, uint32_t uid) {
    };
    
    _agoraKit.onInviteMsg = ^(NSString* channelID, NSString* account, uint32_t uid, NSString* msgType, NSString* msgData, NSString* extra) {
    };
    
    _agoraKit.onMessageSendProgress = ^(NSString* account, NSString* messageID, NSString* type, NSString* info) {
    };
    
    _agoraKit.onMessageSendSuccess = ^(NSString *messageID) {
    };
    
    _agoraKit.onMessageAppReceived = ^(NSString* msg) {
    };
    
    _agoraKit.onInvokeRet = ^(NSString* callID, NSString* err, NSString* resp) {
    };
    
    _agoraKit.onMsg = ^(NSString* from, NSString* t, NSString* msg) {
    };
    
    _agoraKit.onUserAttrResult = ^(NSString* account, NSString* name, NSString* value) {
    };
    
    _agoraKit.onUserAttrAllResult = ^(NSString* account, NSString* value) {
    };
    
    _agoraKit.onQueryUserStatusResult = ^(NSString *name, NSString *status) {
    };
    
    _agoraKit.onDbg = ^(NSString *a, NSString *b) {
    };
    
    _agoraKit.onBCCall_result = ^(NSString *reason, NSString *json_ret, NSString *callID) {
    };
    
    _agoraKit.onLog = ^(NSString *txt){
        if (txt == nil) {
            txt = @"";
        }
        
        if (weakself.isInitLogPath == NO) {
            [weakself createLogFile];
        }
        [LCLLogFile logWithIdentifier:"" level:0 path:nil line:0 function:nil message:txt];
    };
}

- (void)debugLog:(NSString *)log {
#if isDebug
    NSLog(@"<Tube> %@", log);
#endif
}

#pragma mark - Lazy load
- (AgoraAPI *)agoraKit {
    if (!_agoraKit) {
        _agoraKit = [AgoraAPI getInstanceWithoutMedia:self.appId];
    }
    return _agoraKit;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    }
    return _dateFormatter;
}

@end
