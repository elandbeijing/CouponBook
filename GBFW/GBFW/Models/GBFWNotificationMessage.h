//
//  GBFWNotificationMessage.h
//  GBFW
//
//  Created by 장재휴 on 12. 11. 21..
//  Copyright (c) 2012년 장재휴. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSInteger GBFWNotificationAlertType;
typedef NSInteger GBFWNotificationActionType;
typedef NSInteger GBFWNotificationMenuReloadType;

enum {
    GBFWNotificationAlertTypeNone = 0,
    GBFWNotificationAlertTypeToast,
    GBFWNotificationAlertTypeAlertView
};

enum {
    GBFWNotificationActionTypeNone = 0,
    GBFWNotificationActionTypeShowNotiList,
    GBFWNotificationActionTypeRedirect
};

enum {
    GBFWNotificationMenuReloadTypeNone = 0,
    GBFWNotificationMenuReloadTypeReload
};

/**
 APN Push에 alert, sound, badge외에 추가로 전달받는 message parser
 "cf"에 설정값이 담겨 온다. (1234|5)
 
 1. foregroundAlertType
 - 아무일없음
 - toast
 - alertview
 2. backgroundAlertType
 - 아무일없음
 - toast
 - alertview
 3. backgroundActionType
 - 아무일없음
 - 알림창 페이지 이동
 - 특정 URL로 이동
 4. menuReloadType
 - 아무일없음
 - 리로드
 5. redirect id
 - 알람 이동시 사용할 id
 
 - 예제
 {
 "aps":{
 "alert":"메시지",
 "sound":"default",
 "badge":123,
 },
 "cf":{
 "1111|123"
 }
 }
 */
@interface GBFWNotificationMessage : NSObject

@property (nonatomic, strong) NSNumber *badge;
@property (nonatomic, strong) NSString *msg;
@property (nonatomic, strong) NSString *sound;

@property (nonatomic, assign) GBFWNotificationAlertType foregroundAlertType;
@property (nonatomic, assign) GBFWNotificationAlertType backgroundAlertType;
@property (nonatomic, assign) GBFWNotificationActionType backgroundActionType;
@property (nonatomic, assign) GBFWNotificationMenuReloadType menuReloadType;
@property (nonatomic, strong) NSString *redirectId;

- (id)initWithDictionary:(NSDictionary *)dic;
- (void)parseDictionary:(NSDictionary *)dic;
- (NSString *)toString;

@end