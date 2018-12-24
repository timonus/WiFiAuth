//
//  WifiAuth.m
//  Pods-WifiAuth_Example
//
//  Created by Felix Krause on 12/17/18.
//

#import "WifiAuth.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

@interface WifiAuth()

@property (nonatomic, assign) Boolean currentlyShownPopup;
@property (nonatomic, assign) Boolean offeredToShowPopup;

@property (nonatomic, assign) SCNetworkReachabilityRef  reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t          reachabilitySerialQueue;

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;

@end

// Start listening for reachability notifications on the current run loop
static void WAReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    [[WifiAuth sharedWifiAuth] reachabilityChanged:flags];
}

@implementation WifiAuth

+ (instancetype)sharedWifiAuth {
    static dispatch_once_t once;
    static WifiAuth *sharedWifiAuth;
    dispatch_once(&once, ^ { sharedWifiAuth = [[self alloc] init]; });
    return sharedWifiAuth;
}

- (BOOL)startMonitoring {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    self.reachabilityRef = ref;
    
    self.reachabilitySerialQueue = dispatch_queue_create("fx.krause.wifiauth", NULL);
    
    // Copped from Reachbility -startNotifier
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, WAReachabilityCallback, &context)) {
        // Set it as our reachability queue, which will retain the queue
        return SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue);
    }
    
    return NO;
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    if (![self isInterventionRequiredWithFlags:flags]) {
        return;
    }
    if (self.currentlyShownPopup) {
        return;
    }
    if (self.offeredToShowPopup) {
        return;
    }
    
    // TODO: replace all those variables with other ones
    self.currentlyShownPopup = YES;
    self.offeredToShowPopup = YES;
    
    // Login here
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WiFi Authentication needed"
                                                                   message:@"Looks like the WiFi you're connected to requires some sort of login. Open the login page now?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    __weak __typeof(self) weakSelf = self;
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {
                                                              weakSelf.currentlyShownPopup = NO;
                                                              
                                                              // TODO: replace with in-app browser
                                                              // In-app browser allows us to detect once the WiFi connection is established
                                                              // And show the `Done` button
                                                              NSURL *urlToOpen = [NSURL URLWithString:@"http://captive.apple.com/hotspot-detect.html"];
                                                              [[UIApplication sharedApplication] openURL:urlToOpen];
                                                          }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              weakSelf.currentlyShownPopup = NO;
                                                          }];
    
    [alert addAction:yesAction];
    [alert addAction:noAction];
    
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];

}


// Taken from https://github.com/tonymillion/Reachability
// BSD licensed
- (BOOL)isInterventionRequiredWithFlags:(SCNetworkReachabilityFlags)flags
{
    return (flags & kSCNetworkReachabilityFlagsConnectionRequired &&
            flags & kSCNetworkReachabilityFlagsInterventionRequired);
}

@end
