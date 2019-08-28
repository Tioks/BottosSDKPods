//
//  YWBiometManager.h
//  AnyWallet
//
//  Created by Tioks on 2019/8/6.
//  Copyright © 2019 ZZL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YWBiometIDManagerResult) {
    
    YWBiometIDManagerResultSuccess = 0, // 成功
    YWBiometIDManagerResultAuthenticationFailed,      // 验证失败
    YWBiometIDManagerResultUserCancel,   // 用户取消
    YWBiometIDManagerResultUserFallback, // 用户使用密码
    YWBiometIDManagerResultSystemCancel, // 系统取消 (如遇到来电,锁屏,按了Home键等)
    YWBiometIDManagerResultPasscodeNotSet,   // TouchID/FaceID 无法启动,因为用户没有设置密码
    YWBiometIDManagerResultTouchIDNotEnrolled,   // TouchID/FaceID 无法启动,因为用户没有设置TouchID/FaceID
    YWBiometIDManagerResultTouchIDNotAvailable,  // TouchID/FaceID 无效
    YWBiometIDManagerResultTouchIDLockout,       // TouchID/FaceID 被锁定(连续多次验证TouchID失败,系统需要用户手动输入密码)
    YWBiometIDManagerResultAppCancel,            // 当前软件被挂起并取消了授权 (如App进入了后台等)
    YWBiometIDManagerResultInvalidContext        // 当前软件被挂起并取消了授权 (LAContext对象无效)
};

@interface YWBiometManager : NSObject
//创建
+ (instancetype)manager;
//销毁
+ (void)deallocManeger;
/**
 判断设备是否支持生物识别

 @return 是否支持生物识别
 */
- (BOOL)isSupportBiometID;

/**
 设备支持生物识别类型 -1:授权错误 0:都不支持 1:touchID 2:FaceID

 @return 类型
 */
- (NSInteger)supportBiometType;

/**
 验证生物识别

 @param completeHandler 回调结果
 */
- (void)verificationBiometIDCompleteHandler:(void(^)(YWBiometIDManagerResult result,NSString *resultStr))completeHandler;

@end

NS_ASSUME_NONNULL_END
