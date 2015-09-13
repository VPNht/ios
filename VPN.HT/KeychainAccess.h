//
//  KeychainAccess.h
//  VPN.HT
//
//  Created by Douwe Bos on 05-06-15.
//  Copyright (c) 2015 Douwe Bos. All rights reserved.
//

#ifndef VPN_HT_KeychainAccess_h
#define VPN_HT_KeychainAccess_h
#import <Foundation/Foundation.h>

@interface KeychainAccess : NSObject
+ (void) storeData: (NSString *)key data:(NSData *)data;
+ (NSData *) getData: (NSString *)key;
+ (int) deleteData: (NSString *)key;

@end

#endif
