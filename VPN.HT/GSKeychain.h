//
//  GSKeychain.h
//
//  Created by Simon Whitaker on 15/07/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSKeychain : NSObject

+ (GSKeychain *)systemKeychain;

- (void)setSecret:(NSString *)secret forKey:(NSString *)key;
- (NSString *)secretForKey:(NSString *)key;
- (void)removeSecretForKey:(NSString *)key;
- (void)removeAllSecrets;

@end
