//
//  SignalEcode.h
//  AgoraSignalKit
//
//  Created by CavanSu on 2018/5/28.
//  Copyright © 2018 CavanSu. All rights reserved.
//

#ifndef SignalEcode_h
#define SignalEcode_h

typedef NS_ENUM(NSUInteger, SignalEcode){
    SignalEcodeSUCCESS = 0,
    SignalEcodeLogoutUnkonwError = 100,
    SignalEcodeLogoutUserError = 101,
    SignalEcodeLogoutNetError = 102,
    SignalEcodeLogoutKicked = 103,
    SignalEcodeLogoutPacketError = 104,
    SignalEcodeLogoutTokenExpiredError = 105,
    SignalEcodeLogoutOldVersionError = 106,
    SignalEcodeLogoutTokenWrongError = 107,
    SignalEcodeLogoutAlreadyLogout = 108,
    SignalEcodeLogoutUnkonwOtherError = 200,
    
    SignalEcodeLoginFailed = 202,
    SignalEcodeLoginCancel = 203,
    SignalEcodeLoginTokenEexpired = 204,
    SignalEcodeLoginOldVersion = 205,
    SignalEcodeLoginTokenWrong = 206,
    SignalEcodeLoginTokenKicked = 207,
    SignalEcodeLoginAlreadyLogin = 208,
    SignalEcodeLoginInvalidIUser = 209,
    SignalEcodeJoinChannelOtherError = 300,
    SignalEcodeSendMessageOtherError = 400,
    SignalEcodeSendMessageTimeOut = 401,
    SignalEcodeQueryUserNumberUnkownError = 500,
    SignalEcodeQueryUserNumberTimeOutError = 501,
    SignalEcodeQueryUserNumberByUser = 502,
    SignalEcodeLeaveChannelOther = 600,
    SignalEcodeLeaveChannelByKicked = 601,
    SignalEcodeLeaveChannelOutChannel = 602,
    SignalEcodeLeaveChannelLogout = 603,
    SignalEcodeLeaveChannelDisconnect = 604,
    SignalEcodeInviteUnkownError = 700,
    SignalEcodeInviteReinvite = 701,
    SignalEcodeInviteNet = 702,
    SignalEcodeInviteRemotePeerOffLine = 703,
    SignalEcodeInviteTimeOut = 704,
    SignalEcodeInvieteCantrecv = 705,
    SignalEcodeGeneralError = 1000,
    SignalEcodeGeneralFailed = 1001,
    SignalEcodeGeneralUnknow = 1002,
    SignalEcodeGeneralNotLogiin = 1003,
    SignalEcodeGeneralWrongParam = 1004,
    SignalEcodeGeneralLargeParam = 1005,
    
    SignalEcodeJoinChannelNetError = 201,
    SignalEcodeAlreadyInChannel = 801,
    SignalEcodeOutChannel = 802,
    SignalEcodeRemoveEarliestLogError = 803,
    SignalEcodeInputJsonError = 804,
    SignalEcodePingJsonError = 805
};

#endif /* SignalEcode_h */
