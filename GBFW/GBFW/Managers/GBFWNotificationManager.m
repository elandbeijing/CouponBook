//
//  GBFWNotificationManager.m
//  GBFW
//
//  Created by 장재휴 on 12. 11. 15..
//  Copyright (c) 2012년 장재휴. All rights reserved.
//

#import "GBFWNotificationManager.h"
#import "GBFWPropertyList.h"
#import "GBFWNotificationMessage.h"
#import "GBFWNetworkHelper.h"

@interface GBFWNotificationManager()<UIAlertViewDelegate>{
    BOOL isSetPushInfo;
}
@property (nonatomic, readonly) FFEnvironmentInformationManager *environmentInformationManager;
@property (nonatomic, readonly) id<FFLoginManagerProtocol> loginManager;
@property (nonatomic, strong) id<FFAccountManagerProtocol> accountManager;
@property (nonatomic, strong) GBFWNotificationMessage *notificationMessage;
@property (nonatomic) UIApplicationState state;
@end

@implementation GBFWNotificationManager

@synthesize environmentInformationManager = _environmentInformationManager;
@synthesize loginManager = _loginManager;
@synthesize accountManager = _accountManager;
@synthesize pushToken = _pushToken;
@synthesize userId = _userId;
@synthesize notificationMessage = _notificationMessage;
@synthesize state = _state;

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

-(id<FFAccountManagerProtocol>)accountManager
{
    if(!_accountManager){
        _accountManager = [NSClassFromString(self.environmentInformationManager.accountManagerClassName) accountManager];
    }
    return _accountManager;
}

-(BOOL)useNotificationView
{
    return [[[GBFWPropertyList properties]valueForKey:USE_NOTIFICATION_VIEW] boolValue];
}

-(void)setPushToken:(NSString *)pushToken
{
    if(_pushToken != pushToken){
        _pushToken = pushToken;
        if(!isSetPushInfo && self.userId)
            [self setPushInfo];
    }
}

-(void)setUserId:(NSString *)userId
{
    if(_userId != userId){
        _userId = userId;
        if(!isSetPushInfo && self.pushToken)
            [self setPushInfo];
    }
}

-(void)receiveRemoteNotification:(UIApplicationState)state
{
    self.notificationMessage = [[GBFWNotificationMessage alloc]initWithDictionary:self.userInfo];
    self.state = state;
    NSLog(@"receiveRemoteNotification - state:%d, message:%@", self.state, [self.notificationMessage toString]);
    
    // Active or Background일때, alert action 수행
    if(self.state == UIApplicationStateActive || self.state == UIApplicationStateBackground)
        [self alertNotificationMessage];
    
    // Inactive일때, 바로 background action 수행
    else
        [self startBackgroundAction];    
    
    // background menu reload type
    if (self.notificationMessage.menuReloadType == GBFWNotificationMenuReloadTypeReload) {
        // 메뉴 리로딩, background에서 smooth하게 진행
//        [self.accountManager setMenuInfo:^(void){
//            NSLog(@"Menu Reload Success!!!");
//        } failure:^(NSError *error){
//            NSLog(@"Menu Reload Failure!!!");
//        }];
    }
}

-(void)showNotificationView
{
    NSLog(@"showNotificationView - state:%d, message:%@", self.state, [self.notificationMessage toString]);
    UIViewController *topViewController = [self topViewController];
    
    FFRootWebViewController *rootWebViewController = [[FFRootWebViewController alloc]init];
    rootWebViewController.urlString = [GBFWPropertyList getPropertyByExecutionMode:NOTIFICATION_INFO_URL];
    rootWebViewController.title = NSLocalizedString(@"Notice", @"Notice");
    rootWebViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideNotificationView:)];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:rootWebViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    [topViewController presentViewController:navigationController animated:YES completion:^(void){}];
}

#pragma mark - private method

-(void)alertNotificationMessage
{
    NSLog(@"alertNotificationMessage - state:%d, message:%@", self.state, [self.notificationMessage toString]);
    GBFWNotificationAlertType alertType = (self.state == UIApplicationStateActive) ? self.notificationMessage.foregroundAlertType : self.notificationMessage.backgroundAlertType;
    if(alertType == GBFWNotificationAlertTypeToast)
        [[[iToast makeText:self.notificationMessage.msg] setGravity:iToastGravityBottom] show];
    else if(alertType == GBFWNotificationAlertTypeAlertView)
        [[[UIAlertView alloc] initWithTitle:@"알림"
                                    message:self.notificationMessage.msg
                                   delegate:self
                          cancelButtonTitle:[FFLocalizationHelper getAppleLocalizableLanguage:@"OK"]
                          otherButtonTitles:nil]
         show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // InActive상태일때는, receiveRemoteNotification에서 바로 BackgroundAction 수행
    if(self.state == UIApplicationStateBackground)
        [self startBackgroundAction];
}

-(void)startBackgroundAction
{
    NSLog(@"startBackgroundAction - state:%d, message:%@", self.state, [self.notificationMessage toString]);
    if(self.notificationMessage.backgroundActionType == GBFWNotificationActionTypeShowNotiList)
        [self showNotificationView];
    else if(self.notificationMessage.backgroundActionType == GBFWNotificationActionTypeRedirect)
        [self redirect:self.notificationMessage.redirectId];
}

-(void)setPushInfo
{
    NSLog(@"set push info");
    isSetPushInfo = YES;
    
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:[[GBFWPropertyList properties]valueForKey:APPID], @"appId",
                           self.loginManager.loginId, @"loginId",
                           [GBFWNetworkHelper macAddress], @"deviceId",
                           @"0", @"deviceType",
                           self.pushToken, @"deviceToken",
                           nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[FFURLHelper getFullUrl:[GBFWPropertyList getPropertyByExecutionMode:SET_NOTIFICATION_INFO_URL]
                                                                                                          withParam:param]]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:(NSURLRequest *)request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
//        NSLog(@"success to regester pushtoken. %@",JSON);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
        NSLog(@"fail to regester pushtoken. \nERROR:%@\nDATA:%@",error,JSON);
    }];
    [operation start];        
}

-(void)redirect:(NSString *)redirectId
{
    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:[[GBFWPropertyList properties]valueForKey:APPID], @"appId",
                           redirectId, @"pushInfoId",
                           self.loginManager.loginId, @"loginId",
                           nil];
        
    FFRootWebViewController *rootWebViewController = [[FFRootWebViewController alloc]init];
    rootWebViewController.urlString = [FFURLHelper getFullUrl:[GBFWPropertyList getPropertyByExecutionMode:NOTIFICATION_REDIRECT_URL] withParam:param];
    rootWebViewController.title = NSLocalizedString(@"Notice", @"Notice");
    rootWebViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideNotificationView:)];
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:rootWebViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    [[self topViewController] presentViewController:navigationController animated:YES completion:^(void){}];    
}

-(void)hideNotificationView:(id)sender
{
    UIViewController *currentViewController = [self topViewController];
    if ([currentViewController isMemberOfClass:[UINavigationController class]])
        [currentViewController dismissViewControllerAnimated:YES completion:^(void){}];
}

-(UIViewController *)topViewController
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

@end
