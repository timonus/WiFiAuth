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
- (BOOL)startMonitoring;

@end

NS_ASSUME_NONNULL_END
