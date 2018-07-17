//
//  ViewController.m
//  SignalTest
//
//  Created by CavanSu on 2018/5/28.
//  Copyright © 2018 CavanSu. All rights reserved.
//

#import "ViewController.h"
#import <AgoraMessageTubeKit/AgoraMessageTubeKit.h>
#import "InfoCell.h"
#import "NSString+UUID.h"

@interface ViewController () <AgoraMessageTubeKitDelegate>
@property (weak, nonatomic) IBOutlet UITextField *currentAccountTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelMsgTextField;
@property (weak, nonatomic) IBOutlet UITextField *peerTextField;
@property (weak, nonatomic) IBOutlet UITextField *peerMsgTextField;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *requestSegControl;

@property (nonatomic, strong) AgoraMessageTubeKit *messageTubeKit;
@property (nonatomic, strong) NSTimer *tiemr;
@property (nonatomic, strong) NSMutableArray *infoArray;
@property (nonatomic, assign) BOOL isBacking;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateViews];
    [self setupLogTableView];

    // Done
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [AgoraMessageTubeKit setupLogPath:documentPath logFileNumber:2];
    // Done
    
    WorkMode mode;
    if (self.workMode == ModeJoinChannelOnly) {
        mode = WorkModeJoinChannelOnly;
    } else {
        mode = WorkModeLoginAndJoinChannel;
    }
    
    self.messageTubeKit = [AgoraMessageTubeKit sharedMessageTubeKitWithAppId:@"ce8673eb931840dbbe7fd3848ebc037f" workMode:mode];
    // Done
    self.messageTubeKit.delegate = self;
    // Done
    [self.messageTubeKit setupReconnectTimes:3 intervalTime:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.isBacking = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.isBacking = true;
    
    if (self.workMode == ModeJoinChannelOnly) {
        if (self.messageTubeKit.isInChannel) {
            [self.messageTubeKit leaveChannel];
        }
    } else {
        if (self.messageTubeKit.isLogin) {
            [self.messageTubeKit logout];
        }
    }
    
    dispatch_after(DISPATCH_TIME_NOW + 1 * NSEC_PER_SEC, dispatch_get_main_queue(), ^{
        [AgoraMessageTubeKit destroy];
    });
}

- (void)updateViews {
    BOOL isEnabled = _workMode == ModeJoinChannelOnly? NO : YES;
    self.loginButton.enabled = isEnabled;
    self.logOutButton.enabled = isEnabled;
}

- (void)setupLogTableView {
    self.logTableView.rowHeight = UITableViewAutomaticDimension;
    self.logTableView.estimatedRowHeight = 55;
    self.logTableView.dataSource = self;
}

- (void)appendInfoToLogTable:(NSString *)info {
    [self.infoArray insertObject:info atIndex:0];
    NSInteger row = 0;
    NSInteger section = 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self.logTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
}

- (IBAction)doGenPressed:(UIButton *)sender {
    self.currentAccountTextField.text = [NSString uuidString];
}

- (IBAction)doSwitchPress:(UIButton *)sender {
    NSString *temp = self.peerTextField.text;
    self.peerTextField.text = self.currentAccountTextField.text;
    self.currentAccountTextField.text = temp;
}

- (IBAction)doLoginPress:(UIButton *)sender {
    [self.messageTubeKit loginWithAccount:self.currentAccountTextField.text];
}

- (IBAction)doLogoutPress:(UIButton *)sender {
    [self.messageTubeKit logout];
}

- (IBAction)doJoinChannelPressed:(UIButton *)sender {
    NSString *channelId = self.channelIdTextField.text;
    [self.messageTubeKit joinChannelWithChannelId:channelId account:self.currentAccountTextField.text];
}

- (IBAction)doLeaveChannelPressed:(UIButton *)sender {
    [self.messageTubeKit leaveChannel];
}

- (IBAction)doChannelSendPress:(UIButton *)sender {
    // Done
    [self.messageTubeKit sendChannelMessage:self.channelMsgTextField.text messageId:nil];
}

- (IBAction)doPeerSendPress:(UIButton *)sender {
    // Done
    [self.messageTubeKit sendMessageToPeer:self.peerTextField.text message:self.peerMsgTextField.text messageId:nil];
}

- (IBAction)doChannelJsonSendPress:(UIButton *)sender {
    NSDictionary *msgDic = @{@"channelJson": self.channelMsgTextField.text};
    // Done
    [self.messageTubeKit sendChannelJsonMessage:msgDic messageId:nil];
}

- (IBAction)doPeerJsonPress:(UIButton *)sender {
    NSDictionary *msgDic = @{@"peerJson": self.peerMsgTextField.text};
    // Done
    [self.messageTubeKit sendMessageToPeer:self.peerTextField.text jsonMsgDic:msgDic messageId:nil];
}

- (IBAction)startPing:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.isSelected) {
        NSString *peer = self.peerTextField.text;
        NSDictionary *dic = @{@"Ping Test": @"test"};
        [self.messageTubeKit startPingToServer:peer intervalSecond:2 jsonDic:dic];
        [self appendInfoToLogTable:[NSString stringWithFormat:@"<Cavan> send Ping, peer: %@", peer]];
    } else {
        [self appendInfoToLogTable:[NSString stringWithFormat:@"<Cavan> stop Ping To Server"]];
        [self.messageTubeKit stopPingToServer];
    }
}

- (IBAction)doRequestPressed:(UIButton *)sender {
    NSInteger selected = self.requestSegControl.selectedSegmentIndex;
    NSDictionary *dic = nil;
    NSString *current = self.currentAccountTextField.text;
    NSString *channelId = self.channelIdTextField.text;
   
    switch (selected) {
        case 0:
            dic = @{@"Request Test": @"test"};
            break;
        case 1: // build room request
            dic = @{@"requestId": @0, @"account": current, @"roomType": @0};
            break;
        case 2:
            dic = @{@"requestId": @1, @"channelId": channelId};
            break;
        case 3:
            dic = @{@"Request Test": @"test"};
            break;
        case 4:
            dic = @{@"Request Test": @"test"};
            break;
        case 5:
            dic = @{@"Request Test": @"test"};
            break;
        default:
            break;
    }
    
    NSString *peer = self.peerTextField.text;
    [self.messageTubeKit requestToServer:peer jsonDic:dic];
    [self appendInfoToLogTable:[NSString stringWithFormat:@"<Cavan> Request, peer: %@", peer]];
}

- (IBAction)doClearPressed:(UIButton *)sender {
    [self.infoArray removeAllObjects];
    [self.logTableView reloadData];
}

#pragma mark - <AgoraMessageTubeKitDelegate>
// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didJoinedChannelSuccessWithChannelId:(NSString *)channelId {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didJoinedChannelSuccessWithChannelId: %@", channelId];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didJoinedChannelFailedWithChannelId:(NSString *)channelId error:(SignalEcode)error {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didJoinedChannelFailedWithChannelId: %@, error: %lu", channelId, (unsigned long)error];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didLeavedChannelWithChannelId:(NSString *)channelId {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didLeavedChannelWithChannelId: %@", channelId];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didUserJoinedChannelWithChannelId:(NSString *)channelId userAccount:(NSString *)userAccount {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didUserJoinedChannelWithChannelId: %@, userAccount: %@", channelId, userAccount];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didUserLeavedChannelWithChannelId:(NSString *)channelId userAccount:(NSString *)userAccount {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didUserLeavedChannelWithChannelId: %@, userAccount: %@", channelId, userAccount];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didReceivedPeerMessage:(NSString *)message remoteAccount:(NSString *)account {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didReceivedPeerMessage: %@, remoteAccount: %@", message, account];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didReceivedChannelMessage:(NSString *)message channelId:(NSString *)channelId remoteAccount:(NSString *)account {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didReceivedChannelMessage: %@, channelId: %@, remoteAccount: %@", message, channelId, account];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didReceivedPeerJsonMessage:(NSDictionary *)msgDic remoteAccount:(NSString *)account {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didReceivedPeerJsonMessage: %@, remoteAccount: %@", msgDic, account];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didReceivedChannelJsonMessage:(NSDictionary *)msgDic channelId:(NSString *)channelId remoteAccount:(NSString *)account {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didReceivedChannelJsonMessage: %@, channelId: %@, remoteAccount: %@", msgDic, channelId, account];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didRemotePeerReceviedMessageSuccess:(NSString *)account {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didRemotePeerReceviedMessageSuccess: remoteAccount: %@", account];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube didChannelMessageSendSuccessWithChannelId:(NSString *)channelId {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didChannelMessageSendSuccessWithChannelId: %@", channelId];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

- (void)messageTube:(AgoraMessageTubeKit *)msgTube didSendPeerOrChannelMessageFailedWithError:(SignalEcode)error messageId:(nullable NSString *)messageId {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didSendPeerOrChannelMessageFailedWithError: %lu", error];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

- (void)messageTube:(AgoraMessageTubeKit *)msgTube didOccurErrorCode:(SignalEcode)code errorName:(NSString *)name errorDesc:(NSString *)desc {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didOccurErrorCode: %lu, errorName: %@, errorDesc: %@", code, name, desc];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube reconnectingWithRetryTimes:(NSInteger)times {
    NSString *info = [NSString stringWithFormat:@"<Cavan>reconnectingWithRetryTimes: %ld", (long)times];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit *)msgTube reconnectedSuccessWithRetryTimes:(NSInteger)times {
    NSString *info = [NSString stringWithFormat:@"<Cavan>reconnectedSuccessWithRetryTimes: %ld", (long)times];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTubeConnectionDidLost:(AgoraMessageTubeKit *)msgTube {
    NSString *info = [NSString stringWithFormat:@"<Cavan>messageTubeKitConnectionDidLost"];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTubeDidLoginSuccess:(AgoraMessageTubeKit * _Nonnull)msgTube {
    NSString *info = [NSString stringWithFormat:@"<Cavan>messageTubeDidLoginSuccess"];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTubeDidLogout:(AgoraMessageTubeKit * _Nonnull)msgTube {
    NSString *info = [NSString stringWithFormat:@"<Cavan>messageTubeDidLogout"];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube didLoginFailedWithError:(SignalEcode)error {
    NSString *info = [NSString stringWithFormat:@"<Cavan>didLoginFailedWithError: %lu", (unsigned long)error];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube responseJsonFromDataServer:(NSDictionary *)jsonDic {
    NSString *info = [NSString stringWithFormat:@"<Cavan>responseJsonFromDataServer: %@", jsonDic];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

// Done
- (void)messageTube:(AgoraMessageTubeKit * _Nonnull)msgTube pongJsonFromDataServer:(NSDictionary *)jsonDic {
    NSString *info = [NSString stringWithFormat:@"<Cavan>pongFromDataServer: %@", jsonDic];
    NSLog(@"%@", info);
    [self appendInfoToLogTable:info];
}

#pragma mark - <LogTableView UITableViewDataSource>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
    
    return self.infoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    InfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
    cell.infoLabel.text = _infoArray[indexPath.row];
    return cell;
}

- (NSMutableArray *)infoArray {
    if (!_infoArray) {
        _infoArray = [NSMutableArray array];
    }
    
    return _infoArray;
}

@end
