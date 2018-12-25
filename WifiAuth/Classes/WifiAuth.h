//
//  WifiAuth.h
//  Pods-WifiAuth_Example
//
//  Created by Felix Krause on 12/17/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WifiAuth : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sharedWifiAuth;

/// Continuously observes network changes and prompts if needed.
- (BOOL)startMonitoring;

/// Checks the current network state and prompts if needed.
/// Returns YES if a prompt was shown.
- (BOOL)tryShowPrompt;

@end

NS_ASSUME_NONNULL_END
