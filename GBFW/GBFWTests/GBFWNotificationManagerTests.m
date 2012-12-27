//
//  GBFWNotificationManagerTests.m
//  GBFW
//
//  Created by 장재휴 on 12. 11. 22..
//  Copyright (c) 2012년 장재휴. All rights reserved.
//

#import "GBFWNotificationManagerTests.h"
#import "FFEnvironmentInformationManager.h"
#import "FFNotificationManagerProtocol.h"

@interface GBFWNotificationManagerTests()
@property (nonatomic, readonly) FFEnvironmentInformationManager *environmentInformationManager;
@property (nonatomic, readonly) id<FFNotificationManagerProtocol> notificationManager;
@end

@implementation GBFWNotificationManagerTests

@synthesize environmentInformationManager = _environmentInformationManager;
@synthesize notificationManager = _notificationManager;

-(FFEnvironmentInformationManager *)environmentInformationManager
{
    if(!_environmentInformationManager)
        _environmentInformationManager = [FFEnvironmentInformationManager environmentInformationManager];
    return _environmentInformationManager;
}

-(id<FFNotificationManagerProtocol>)notificationManager
{
    if(!_notificationManager)
        _notificationManager = [NSClassFromString(self.environmentInformationManager.notificationManagerClassName) notificationManager];
    return _notificationManager;
}

-(void)testPush
{
    [self.notificationManager setBadgeCount:1];
}

@end
