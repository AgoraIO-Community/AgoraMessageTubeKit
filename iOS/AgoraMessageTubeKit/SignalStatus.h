//
//  SignalStatus.h
//  AgoraSignalKit
//
//  Created by CavanSu on 2018/5/28.
//  Copyright © 2018 CavanSu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ChannelStatus) {
    ChannelStatusJoiningChannel = 0,
    ChannelStatusInChannel = 1,
    ChannelStatusLeaveingChannel = 2,
    ChannelStatusOutChannel = 3
};

typedef NS_ENUM(NSInteger, LoginStatus) {
    LoginStatusLoginIng = 0,
    LoginStatusLogin = 1,
    LoginStatusLogOutIng = 2,
    LoginStatusLogOut = 3
};

typedef NS_ENUM(int, MessageType) {
    MessageTypePeerToPeerCommonMessage = 0,
    MessageTypeChannelCommonMessage = 1,
    MessageTypePeerToPeerReceiveMsgSuccess = 2,
    MessageTypePeerToPeerJsonMessage = 3,
    MessageTypeChannelJsonMessage = 4,
    MessageTypePingPongWithDataServer = 5,
    MessageTypeRequestResponseDataServer = 6
};

