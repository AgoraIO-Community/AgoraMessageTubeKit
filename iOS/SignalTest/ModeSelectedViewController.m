//
//  ModeSelectedViewController.m
//  SignalTest
//
//  Created by CavanSu on 2018/7/5.
//  Copyright © 2018 CavanSu. All rights reserved.
//

#import "ModeSelectedViewController.h"
#import "Mode.h"
#import "ViewController.h"

@interface ModeSelectedViewController ()
@property (weak, nonatomic) IBOutlet UIButton *joinChannelOnlyButton;
@property (weak, nonatomic) IBOutlet UIButton *LogJoinButton;
@property (nonatomic, assign) Mode workMode;
@end

@implementation ModeSelectedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ViewController *vc = segue.destinationViewController;
    
    if ([segue.identifier isEqualToString:@"JoinChannelOnly"]) {
        vc.workMode = ModeJoinChannelOnly;
    } else {
        vc.workMode = ModeLoginAndJoinChannel;
    }
}

@end
