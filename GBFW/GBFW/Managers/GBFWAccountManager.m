//
//  GBFWAccountManager.m
//  GBFW
//
//  Created by 장재휴 on 12. 11. 14..
//  Copyright (c) 2012년 장재휴. All rights reserved.
//

#import "GBFWAccountManager.h"
#import "GBFWPropertyList.h"
#import "GBFWJSONResult.h"
#import <Cordova/JSONKit.h>

@interface GBFWAccountManager()
@property (nonatomic, readonly) FFEnvironmentInformationManager *environmentInformationManager;
@property (nonatomic, readonly) id<FFLoginManagerProtocol> loginManager;
@property (nonatomic, strong) NSString *currentMenuVersion;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *name;
@end

@implementation GBFWAccountManager

@synthesize environmentInformationManager = _environmentInformationManager;
@synthesize loginManager = _loginManager;
@synthesize menuSections = _menuSections;
@synthesize currentMenuVersion = _currentMenuVersion;
@synthesize email = _email;
@synthesize name = _name;

#pragma mark - Setter/Getter Method

-(FFEnvironmentInformationManager *)environmentInformationManager
{
    if(!_environmentInformationManager)
        _environmentInformationManager = [FFEnvironmentInformationManager environmentInformationManager];
    return _environmentInformationManager;
}

-(id<FFLoginManagerProtocol>)loginManager
{
    if(!_loginManager)
        _loginManager = [NSClassFromString(self.environmentInformationManager.loginManagerClassName) loginManager];
    return _loginManager;
}

-(void)setMenuSections:(NSOrderedSet *)menuSections
{
    if(_menuSections != menuSections)
        _menuSections = menuSections;
}

-(NSString *)currentMenuVersion
{
    return @"0"; // 무조건 메뉴 정보를 갱신하도록 하드코딩 함. 제거해야 함
    if(!_currentMenuVersion){
        _currentMenuVersion = [[NSUserDefaults standardUserDefaults]valueForKey:@"GBFW_CURRENT_MENU_VERSION"];
    }
    return _currentMenuVersion;
}

-(void)setCurrentMenuVersion:(NSString *)currentMenuVersion
{
    if(_currentMenuVersion != currentMenuVersion){
        [[NSUserDefaults standardUserDefaults]setValue:currentMenuVersion forKey:@"GBFW_CURRENT_MENU_VERSION"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _currentMenuVersion = currentMenuVersion;
    }
}

-(void)setName:(NSString *)name
{
    if(_name != name){
        [[NSUserDefaults standardUserDefaults]setValue:name forKey:@"GBFW_USER_NAME"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _name = name;
    }
}

-(void)setEmail:(NSString *)email
{
    if(_email != email){
        [[NSUserDefaults standardUserDefaults]setValue:email forKey:@"GBFW_USER_EMAIL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _email = email;
    }
}

#pragma mark - FFAccountManagerProtocol method

-(void)setMenuInfo:(void (^)())success failure:(void (^)(NSError *))failure
{
    [self initializeAccountInfo:success failure:failure];
}

#pragma mark - private method

-(void)initializeAccountInfo:(void (^)())success failure:(void (^)(NSError *error))failure
{    
    NSDictionary *properties = [GBFWPropertyList properties];    
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:[properties valueForKey:@"AppId"],@"appId",
                           self.loginManager.loginId, @"loginID",
                           self.currentMenuVersion, @"currentMenuVersion",
                           [[NSLocale preferredLanguages] objectAtIndex:0], @"locale",
                           nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[FFURLHelper getFullUrl:[GBFWPropertyList getPropertyByExecutionMode:ACCOUNT_REQUEST_URL]
                                                                                                          withParam:param]]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                         {
                                             GBFWJSONResult *jsonResult = [[GBFWJSONResult alloc]initWithJSON:JSON];
                                             if([jsonResult.result isEqualToString:@"failure"]){
                                                 NSMutableDictionary* details = [NSMutableDictionary dictionary];
                                                 [details setValue:jsonResult.msg
                                                            forKey:NSLocalizedDescriptionKey];
                                                 NSError *error = [NSError errorWithDomain:@"JSONRequestOperationWithRequest"
                                                                                      code:GBFWRequestResultCodeCustomError
                                                                                  userInfo:details];
                                                 failure(error);
                                             } else {
                                                 self.name = [jsonResult.data valueForKeyPath:@"AccountInfo.Name"];
                                                 self.email = [jsonResult.data valueForKeyPath:@"AccountInfo.Email"];
                                                 NSString *menuVersion = [[jsonResult.data objectForKey:@"MenuInfo"] objectForKey:@"MenuVersion"];
                                                 if([self.currentMenuVersion isEqualToString:menuVersion]){
                                                     success();
                                                 } else {
                                                     self.currentMenuVersion = menuVersion;
                                                     [self saveAccountInfo:jsonResult.data success:success];
                                                 }
                                             }
                                         } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                         {
                                             NSLog(@"<<ERRROR>> \nCurrentAction:%@ \nErrorInfo:%@ \nJSON:%@",@"initializeAccountInfo", error, JSON);
                                         }];
    [operation start];
}

-(void)saveAccountInfo:(id)JSON success:(void (^)())success
{        
    [FFCoreDataHelper openDocument:USER_PROFILE_DOCUMENT usingBlock:^(NSManagedObjectContext *context){
        
        // delete all menus
        NSArray *sections = [Section sectionsInManagedObjectContext:context];
        for(Section *section in sections)
            [Section deleteSection:section inManagedObjectContext:context];
        
        // save new menus
        NSArray *menuInfos = [[JSON objectForKey:@"MenuInfo"] objectForKey:@"Menus"];
        
        for (id menuInfo in menuInfos) {
            
            id sectionInfo = [menuInfo objectForKey:@"Section"];
            Section *section = [Section sectionWithCode:[sectionInfo valueForKey:@"DisplaySeq"] inManagedObjectContext:context];
            section.name = [sectionInfo valueForKey:@"Name"];
            
            id menuInfos = [menuInfo objectForKey:@"Menu"];
            for (id menuInfo in menuInfos) {
                Menu *menu = [Menu menuWithCode:[[menuInfo valueForKey:@"DisplaySeq"] description] inManagedObjectContext:context];
                menu.name = [menuInfo valueForKey:@"Name"];
                menu.icon = [menuInfo valueForKey:@"Icon"];
                menu.type = [[menuInfo valueForKey:@"MenuType"]intValue] == 1 ? MENUTYPE_NODE : MENUTYPE_FOLDER;
                menu.url = [FFURLHelper getFullUrl:[self getURL:[menuInfo valueForKey:@"ViewUrl"]]];
                menu.badge = [[menuInfo valueForKey:@"count"] description];
                menu.section = [Section sectionWithCode:[[menuInfo valueForKey:@"ParentSeq"] description] inManagedObjectContext:context];
            }
        }
        
        [self setMenuSections:[NSOrderedSet orderedSetWithArray:[Section sectionsInManagedObjectContext:context]]];
        success();
    }];
}

-(NSString *)getURL:(NSString *)urlString
{
    NSDictionary *params;
    NSRange paramRange = [urlString rangeOfString:@"?param"];
    if(paramRange.length > 0) {
        NSString *parameterString = [[[urlString substringFromIndex:paramRange.location + 7] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSData *parameterData = [parameterString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *jsonError = nil;

        if ([NSJSONSerialization class]) {
            params = [NSJSONSerialization JSONObjectWithData:parameterData options:0 error:&jsonError];
        } else {
            params = [[CDVJSONDecoder decoder] objectWithData:parameterData error:&jsonError];
        }        
    }
    return [params valueForKey:@"url"];
}
@end
