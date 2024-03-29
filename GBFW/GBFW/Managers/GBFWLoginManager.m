//
//  GBFWLoginManager.m
//  GBFW
//
//  Created by 장재휴 on 12. 11. 14..
//  Copyright (c) 2012년 장재휴. All rights reserved.
//

#import "GBFWLoginManager.h"
#import "GBFWPropertyList.h"
#import "GBFWJSONResult.h"
#import "GBFWNetworkHelper.h"

@interface GBFWLoginManager()
@property (nonatomic, readonly) FFEnvironmentInformationManager *environmentInformationManager;
@property (nonatomic, readonly) id<FFNotificationManagerProtocol> notificationManager;
@end

@implementation GBFWLoginManager

@synthesize environmentInformationManager = _environmentInformationManager;
@synthesize notificationManager = _notificationManager;
@synthesize loginId = _loginId;

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

-(NSString *)loginId
{
    return _loginId;
}

-(void)setLoginId:(NSString *)loginId
{
    _loginId = loginId;
}

-(void)login:(void (^)())success failure:(void (^)(NSError *))failure
{    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[FFURLHelper getFullUrl:[[GBFWPropertyList properties]valueForKey:LOGIN_URL]]]];
    [request setHTTPMethod:@"POST"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:[GBFWNetworkHelper macAddress], @"deviceId",
                           [[NSLocale preferredLanguages] objectAtIndex:0], @"locale",
                           [info objectForKey:@"CFBundleIdentifier"], @"appId",
                           nil];
    [request setHTTPBody:[[param urlEncodedString] dataUsingEncoding:NSUTF8StringEncoding]];        

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        
        if([response statusCode] == 200) {
            GBFWJSONResult *json = [[GBFWJSONResult alloc] initWithJSON:JSON];
            if([json.result isEqualToString:@"success"]) {
                self.loginId = [json.data valueForKey:@"loginId"];
                self.notificationManager.userId = [json.data valueForKey:@"loginId"];
                success();
            } else if([json.result isEqualToString:@"failure"]) {
                [details setValue:json.msg
                           forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"JSONRequestOperationWithRequest"
                                                   code:GBFWRequestResultCodeCustomError
                                               userInfo:details];
                failure(error);
            } else {
                [details setValue:@"json format exception"
                           forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"JSONRequestOperationWithRequest"
                                                   code:GBFWRequestResultCodeJsonError
                                               userInfo:details];
                failure(error);
            }
            
        } else {
            [details setValue:[JSON objectForKey:@"data"] forKey:@"data"];
            [details setValue:[NSString stringWithFormat:@"%d %@", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]]
                       forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"JSONRequestOperationWithRequest"
                                               code:GBFWRequestResultCodeServerError
                                           userInfo:details];
            failure(error);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:[error.userInfo valueForKey:NSLocalizedDescriptionKey]
                   forKey:NSLocalizedDescriptionKey];        
        failure(error);
    }];
    [operation start];
}

@end
