//
//  GSKeychain.m
//
//  Created by Simon Whitaker on 15/07/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSKeychain.h"
#import <Security/Security.h>

@implementation GSKeychain

#pragma mark - Singleton accessor

+ (GSKeychain *)systemKeychain
{
    static dispatch_once_t once;
    static GSKeychain *singleton;
    dispatch_once(&once, ^{ singleton = [[GSKeychain alloc] init]; });
    return singleton;
}

#pragma mark - Private methods

- (NSMutableDictionary *)genericLookupDictionaryForIdentifier:(NSString *)identifier
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (identifier) {
        NSData *identifierData = [identifier dataUsingEncoding:NSUTF8StringEncoding];
        // Set the specified identifier
        [dict setObject:identifierData forKey:(__bridge id)kSecAttrAccount];
    }
    
    // Save/retrieve the secrets we're given as generic passwords.
    [dict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

    // Set the service identifier to the current bundle ID, if there is one
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    if (service) {
        [dict setObject:service forKey:(__bridge id)kSecAttrService];
    }
    
    return dict;
}

- (void)updateSecret:(NSString *)secret forKey:(NSString *)key
{
    NSDictionary *query = [self genericLookupDictionaryForIdentifier:key];
    NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
    [attributesToUpdate setObject:[secret dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
        
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    if (status != errSecSuccess) {
        // TODO: error handling
    }
}

#pragma mark - Public methods

- (void)setSecret:(NSString *)secret forKey:(NSString *)key
{
    NSMutableDictionary *dict = [self genericLookupDictionaryForIdentifier:key];
    
    // Set the value we want to store
    [dict setObject:[secret dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
    if (status == errSecDuplicateItem) {
        [self updateSecret:secret forKey:key];
    }
}

- (NSString *)secretForKey:(NSString *)key
{
    NSMutableDictionary *dict = [self genericLookupDictionaryForIdentifier:key];
    NSString *result = nil;
    
    // Only get one secret
    [dict setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    // Return the secret data by value
    [dict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    CFTypeRef resultRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict, &resultRef);
    if (status == errSecSuccess) {
        // __bridge_transfer transfers ownership of resultRef into ARC, so ARC will
        // release it when it's done.
        // See http://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html
        result = [[NSString alloc] initWithData:(__bridge_transfer id)resultRef encoding:NSUTF8StringEncoding];
    } else if (status != errSecItemNotFound) {
        // TODO: error handling
    }

    return result;
}

- (void)removeSecretForKey:(NSString *)key
{
    NSDictionary *dict = [self genericLookupDictionaryForIdentifier:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dict);
    if (status != errSecSuccess) {
        // TODO: error handling
    }
}

- (void)removeAllSecrets
{
    // Set up dictionary for no specific key
    NSMutableDictionary *dict = [self genericLookupDictionaryForIdentifier:nil];
    [dict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)dict);
    if (status != errSecSuccess) {
        // TODO: error handling
    }
}
@end
