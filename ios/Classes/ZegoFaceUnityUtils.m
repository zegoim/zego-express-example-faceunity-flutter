//
//  ZegoFaceUnityUtils.m
//  Pods-Runner
//
//  Created by Patrick Fu on 2020/11/18.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "ZegoFaceUnityUtils.h"

@implementation ZegoFaceUnityUtils

+ (BOOL)boolValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? NO : [number boolValue];
}

+ (int)intValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0 : [number intValue];
}

+ (unsigned int)unsignedIntValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0 : [number unsignedIntValue];
}

+ (long)longValue:(NSNumber *)number {
    return [number isKindOfClass:[NSNull class]] ? 0 : [number longValue];
}

+ (unsigned long)unsignedLongValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0 : [number unsignedLongValue];
}

+ (unsigned long long)unsignedLongLongValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0 : [number unsignedLongLongValue];
}

+ (long long)longLongValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0 : [number longLongValue];
}

+ (float)floatValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0.f : [number floatValue];
}

+ (double)doubleValue:(NSNumber *)number {

    return [number isKindOfClass:[NSNull class]] ? 0.0 : [number doubleValue];
}

+ (BOOL)isNullObject:(id)object {
    return [object isKindOfClass:[NSNull class]];
}

@end
