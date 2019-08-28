//
//  YWBiometManager.m
//  AnyWallet
//
//  Created by Tioks on 2019/8/6.
//  Copyright © 2019 ZZL. All rights reserved.
//

#import "YWBiometManager.h"
#import <LocalAuthentication/LocalAuthentication.h>

static YWBiometManager *_manager = nil;

@interface YWBiometManager()
@property (nonatomic, strong) LAContext *context;

/**
 生物识别类型 -1:验证错误 0:都不支持 1:touchID 2:faceID
 */
@property (nonatomic, assign) NSInteger type;
@end

@implementation YWBiometManager

//创建单例
+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_manager) {
            _manager = [[self alloc] init];
        }
    });
    return _manager;
}

//销毁单例
+ (void)deallocManeger {
    _manager.context = nil;
    _manager = nil;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_manager) {
            _manager = [super allocWithZone:zone];
        }
    });
    return _manager;
}

- (id)copyWithZone:(NSZone *)zone {
    return _manager;
}

- (NSInteger)supportBiometType {
    [self isSupportBiometID];
    return self.type;
}

- (BOOL)isSupportBiometID {
    
    //首先判断版本 小于8.0 touchID都不支持
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_8_0) {
        NSLog(@"系统版本不支持TouchID");
        self.type = -1;
        return NO;
    }
    
    self.context = [[LAContext alloc]init];
    NSError *authError = nil;
    BOOL isCanEvaluatePolicy = [self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError];
    if (authError) {
        //验证失败
        NSLog(@"检测设备是否支持TouchID或者FaceID失败！\n error : == %@",authError.localizedDescription);
        self.type = - 1;
        return NO;
    } else {
        if (isCanEvaluatePolicy) {
            //判断设备是支持TouchID还是FaceID
            if (@available(iOS 11.0, *)) {
                switch (self.context.biometryType) {
                    case LABiometryNone: {
                        //都不支持
                        NSLog(@"该设备不支持FaceID和TouchID");
                        self.type = 0;
                        return NO;
                    }
                        break;
                    case LABiometryTypeTouchID: {
                        //touch ID
                        NSLog(@"该设备支持TouchID");
                        self.type = 1;
                        return YES;
                    }
                        break;
                    case LABiometryTypeFaceID: {
                        //face ID
                        NSLog(@"该设备支持FaceID");
                        self.type = 2;
                        return YES;
                    }
                        break;
                        
                    default:
                        break;
                }
            } else {
                // 因为iPhoneX起始系统版本都已经是iOS11.0，所以iOS11.0系统版本下不需要再去判断是否支持faceID，直接走支持TouchID逻辑即可。
                NSLog(@"该设备支持TouchID");
                self.type = 1;
            }
        } else {
            self.type = 0;
            return NO;
        }
    }
    return YES;
}

- (void)verificationBiometIDCompleteHandler:(void(^)(YWBiometIDManagerResult result,NSString *resultStr))completeHandler {
    
    if ([self isSupportBiometID]) {
        
        //返回信息必须放在主线程 不然会报错
        //LAPolicyDeviceOwnerAuthentication:自动弹出密码输入框 输入正确密码 即走验证成功回调
        [self.context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"请验证" reply:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"TouchID/FaceID 验证成功");
                    completeHandler(YWBiometIDManagerResultSuccess,@"验证成功");
                });
            } else if(error) {
                switch (error.code) {
                    case LAErrorAuthenticationFailed:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"TouchID/FaceID 验证失败");
                            completeHandler(YWBiometIDManagerResultAuthenticationFailed,@"验证失败");
                        });
                        break;
                    }
                    case LAErrorUserCancel:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"TouchID/FaceID 被用户手动取消");
                            completeHandler(YWBiometIDManagerResultUserCancel,@"");
                        });
                    }
                        break;
                    case LAErrorUserFallback:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"用户不使用TouchID/FaceID,选择手动输入密码");
                            completeHandler(YWBiometIDManagerResultUserFallback,@"");
                        });
                    }
                        break;
                    case LAErrorSystemCancel:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"TouchID/FaceID 被系统取消 (如遇到来电,锁屏,按了Home键等)");
                            completeHandler(YWBiometIDManagerResultSystemCancel,@"");
                        });
                    }
                        break;
                    case LAErrorPasscodeNotSet:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"TouchID/FaceID 无法启动,因为用户没有设置密码");
                            completeHandler(YWBiometIDManagerResultPasscodeNotSet,@"未设定");
                        });
                    }
                        break;
                    case LAErrorTouchIDNotEnrolled:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"TouchID/FaceID 无法启动,因为用户没有设置TouchID");
                            NSString *str;
                            if (self->_type == 1) {
                                str = @"未开启指纹识别，暂时无法使用该功能";
                            } else if(self->_type == 2) {
                                str = @"未开启人脸识别，暂时无法使用该功能";
                            }
                            completeHandler(YWBiometIDManagerResultTouchIDNotEnrolled,str);
                        });
                    }
                        break;
                    case LAErrorTouchIDNotAvailable:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"TouchID/FaceID 无效");
                            completeHandler(YWBiometIDManagerResultTouchIDNotAvailable,@"");
                        });
                    }
                        break;
                    case LAErrorTouchIDLockout:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *str;
                            if (self->_type == 1) {
                                str = @"指纹识别功能被锁定，请锁屏后再解锁启用";
                            } else if(self->_type == 2) {
                                str = @"人脸识别功能被锁定，暂时无法使用该功能";
                            }
                            completeHandler(YWBiometIDManagerResultTouchIDLockout,str);
                            NSLog(@"TouchID/FaceID 被锁定，请锁屏后再解锁启用");
                        });
                    }
                        break;
                    case LAErrorAppCancel:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completeHandler(YWBiometIDManagerResultAppCancel,@"");
                            NSLog(@"当前软件被挂起并取消了授权 (如App进入了后台等)");
                        });
                    }
                        break;
                    case LAErrorInvalidContext:{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completeHandler(YWBiometIDManagerResultInvalidContext,@"");
                            NSLog(@"当前软件被挂起并取消了授权 (LAContext对象无效)");
                        });
                    }
                        break;
                    default:
                        break;
                }
            }
        }];
    } else {
        NSLog(@"该设备暂时不支持生物识别(模拟器或未开启生物识别)");
        completeHandler(YWBiometIDManagerResultAuthenticationFailed,@"该设备暂时不支持生物识别");
    }
    
}

@end
