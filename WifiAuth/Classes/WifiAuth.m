//
//  WifiAuth.m
//  Pods-WifiAuth_Example
//
//  Created by Felix Krause on 12/17/18.
//

#import "WifiAuth.h"

#import <SafariServices/SafariServices.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

@interface WifiAuth ()

@property (nonatomic, assign) BOOL currentlyShowingAlert;

@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t reachabilitySerialQueue;

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;

@end

// Start listening for reachability notifications on the current run loop
static void WAReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    [[WifiAuth sharedWifiAuth] reachabilityChanged:flags];
}

@implementation WifiAuth

+ (instancetype)sharedWifiAuth
{
    static dispatch_once_t once;
    static WifiAuth *sharedWifiAuth;
    dispatch_once(&once, ^ { sharedWifiAuth = [[self alloc] initPrivate]; });
    return sharedWifiAuth;
}

- (instancetype)initPrivate
{
    if (self = [super init]) {
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
        self.reachabilityRef = ref;
        self.reachabilitySerialQueue = dispatch_queue_create("fx.krause.wifiauth", NULL);
    }
    return self;
}

- (BOOL)startMonitoring
{
    // Copped from Reachbility -startNotifier
    SCNetworkReachabilityContext context = { 0, NULL, NULL, NULL, NULL };
    if (SCNetworkReachabilitySetCallback(self.reachabilityRef, WAReachabilityCallback, &context)) {
        // Set it as our reachability queue, which will retain the queue
        if (SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue)) {
            // Perform initial observation.
            SCNetworkReachabilityFlags flags;
            if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
                [self reachabilityChanged:flags];
            }
            return YES;
        }
    }
    return NO;
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    if (self.currentlyShowingAlert || ![self isInterventionRequiredWithFlags:flags]) {
        return;
    }
    
    self.currentlyShowingAlert = YES;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Wi-Fi Authentication needed"
                                                                   message:@"It looks like the Wi-Fi you're connected to requires some sort of login. Open the login page now?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    __weak __typeof(self) weakSelf = self;
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Open login page" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          weakSelf.currentlyShowingAlert = NO;
                                                          NSURL *const url = [NSURL URLWithString:@"http://captive.apple.com/hotspot-detect.html"];
                                                          if (@available(iOS 9.0, *)) {
                                                              SFSafariViewController *const safariViewController = [[SFSafariViewController alloc] initWithURL:url];
                                                              [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:safariViewController animated:YES completion:nil];
                                                          } else {
                                                              [[UIApplication sharedApplication] openURL:url];
                                                          }
                                                      }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * action) {
                                                         weakSelf.currentlyShowingAlert = NO;
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
