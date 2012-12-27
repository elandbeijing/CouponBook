//
//  GBFWPropertyList.m
//  GBFW
//
//  Created by 장재휴 on 12. 11. 14..
//  Copyright (c) 2012년 장재휴. All rights reserved.
//

#import "GBFWPropertyList.h"

@implementation GBFWPropertyList

+(NSDictionary *)properties;
{
    if(!_properties)
        _properties = [self loadProperties];
    return _properties;
}


static NSDictionary *_properties;
+(NSDictionary *)loadProperties
{
    @synchronized(self){
        if(!_properties){
            NSString *path = [[NSBundle mainBundle] bundlePath];
            NSString *finalPath = [path stringByAppendingPathComponent:@"GBFW.plist"];
            _properties = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        }
    }
    return _properties;
}

+(NSString *) getPropertyByExecutionMode:(NSString *)gbfwPlistKey{
    NSDictionary *properties = [GBFWPropertyList properties]; 
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dicPlistValues = [properties valueForKey:gbfwPlistKey];
    
    if([[userDefaults valueForKey:@"executionMode"] isEqualToString:@"PRD"])
        return [dicPlistValues objectForKey:@"PRD"];
    else if([[userDefaults valueForKey:@"executionMode"] isEqualToString:@"QAS"])
        return [dicPlistValues objectForKey:@"QAS"];
    else
        return [dicPlistValues objectForKey:@"DEV"];
}

@end
