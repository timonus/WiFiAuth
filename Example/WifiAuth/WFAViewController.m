//
//  WFAViewController.m
//  WifiAuth
//
//  Created by krausefx@gmail.com on 12/17/2018.
//  Copyright (c) 2018 krausefx@gmail.com. All rights reserved.
//

#import "WFAViewController.h"
#import <WifiAuth/WifiAuth.h>

@interface WFAViewController ()

@end

@implementation WFAViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[WifiAuth sharedWifiAuth] startMonitoring];
}

@end
