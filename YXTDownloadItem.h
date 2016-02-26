//
//  DownloadItem.h
//  DownLoader
//
//  Created by Limingkai on 16/1/15.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

typedef NS_ENUM(NSInteger,YXTDownloadState) {
    YXTDownloadStateWaiting = 0,
    YXTDownloadStateStarting = 1,
    YXYDownloadStatePause = 2,
    YXTDownloadStateError = 3,
    YXTDownloadStateFinished = 4
};

@interface YXTDownloadItem : NSObject <NSCoding>

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fileType;
@property (nonatomic, strong) NSString *downloadURL;
@property (nonatomic, assign) YXTDownloadState downloadState;
@property (nonatomic, strong) NSString *targetPath;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, assign) CGFloat receivedSize;
@property (nonatomic, assign) CGFloat totalSize;

- (instancetype)initWithFileName:(NSString *)fileName fileType:(NSString *)fileType downloadURL:(NSString *)downloadURL imageURL:(NSString *)imageURL totalSize:(CGFloat)totalSize;

@end
