//
//  LKDBRecoverSQLite3.h
//  LKDBRecover
//
//  Created by ljh on 2025/4/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKDBRecoverSQLite3 : NSObject

/// srcPath: 损坏的数据库路径
/// dstPath: 修复后的存放路径
+ (NSError *)recoverWithPath:(NSString *)srcPath
                      toPath:(NSString *)dstPath;

@end

NS_ASSUME_NONNULL_END
