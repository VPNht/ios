//
//  KeychainAccess.m
//  VPN.HT
//
//  Created by Douwe Bos on 05-06-15.
//  Copyright (c) 2015 Douwe Bos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeychainAccess.h"

@implementation KeychainAccess : NSObject

+ (void) storeData: (NSString * )key data:(NSData *)data {
	NSLog(@"Store Data");
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
	[dict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	NSData *encodedKey = [key dataUsingEncoding:NSUTF8StringEncoding];
	[dict setObject:encodedKey forKey:(__bridge id)kSecAttrGeneric];
	[dict setObject:encodedKey forKey:(__bridge id)kSecAttrAccount];
	[dict setObject:@"VPNHT" forKey:(__bridge id)kSecAttrService];
	[dict setObject:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
	[dict setObject:data forKey:(__bridge id)kSecValueData];
	
	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dict, NULL);

	if(errSecSuccess != status) {
		NSLog(@"Unable add item with key = %@ error:%d",key,(int)status);
		if(status == errSecDuplicateItem) {
			OSStatus statusDelete = [self deleteData:key];
			
			if(errSecSuccess == statusDelete) {
				[self storeData:key data:data];
			}
		}
	}
	else {
		NSLog(@"Add succesful item with key = %@",key);
	}
}

+ (NSData *) getData: (NSString *)key {
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
	[dict setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	NSData *encodedKey = [key dataUsingEncoding:NSUTF8StringEncoding];
	[dict setObject:encodedKey forKey:(__bridge id)kSecAttrGeneric];
	[dict setObject:encodedKey forKey:(__bridge id)kSecAttrAccount];
	[dict setObject:@"VPNHT" forKey:(__bridge id)kSecAttrService];
	[dict setObject:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
	[dict setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
	[dict setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef];
	
	CFTypeRef result = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dict,&result);
	
	if( status != errSecSuccess) {
		NSLog(@"Unable to fetch item for key %@ with error:%d",key,(int)status);
		return nil;
	}
	
	NSData *resultData = (__bridge NSData *)result;
    
	return resultData;
}

+ (int) deleteData:(NSString *)key {
	NSMutableDictionary * query = [[NSMutableDictionary alloc] init];
	[query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	NSData *encodedKey2 = [key dataUsingEncoding:NSUTF8StringEncoding];
	[query setObject:encodedKey2 forKey:(__bridge id)kSecAttrGeneric];
	[query setObject:encodedKey2 forKey:(__bridge id)kSecAttrAccount];
	[query setObject:@"VPNHT" forKey:(__bridge id)kSecAttrService];

	OSStatus statusDelete = SecItemDelete((__bridge CFDictionaryRef)(query));
	
	if(errSecSuccess != statusDelete) {
		NSLog(@"Unable delete item with key = %@ error:%d",key,(int)statusDelete);
	}
	else {
		NSLog(@"Delete succesful item with key = %@",key);
	}
	
	return statusDelete;
}

@end
