//
//  YXTDownloader.h
//  DownLoader
//
//  Created by Limingkai on 16/1/13.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YXTDownloadDelegate.h"

typedef NS_ENUM(NSInteger,YXTDownloaderFileState) {
    YXTDownloaderFileStateNoDownload  = 0,
    YXTDownloaderFileStateDownloading = 1,
    YXTDownloaderFileStateError       = 2,
    YXTDownloaderFileStateFininshed   = 3
};

@class YXTDownloadOperation;
@class YXTDownloadItem;

typedef void(^YXTDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);
typedef void(^YXTDownloaderStartBlock)(void);
typedef void(^YXTDownloaderCompletedBlock)(void);
typedef void(^YXTDownlaoderErrorBlock)(void);

@interface YXTDownloader : NSObject

@property (nonatomic, weak) id<YXTDownloadDelegate> delegate;
@property (nonatomic, strong) NSArray *filesdownloadingArray;
@property (nonatomic, strong) NSArray *filesfinishedArray;

+ (instancetype)sharedInstant;

- (YXTDownloadOperation *)downloadWithDownloadItem:(YXTDownloadItem *)downloadItem;

- (void)pauseOperationWithDownloadURL:(NSString *)downloadURL;
- (void)resumeOpreationWithDownloadURL:(NSString *)downloadURL;
- (void)resumeAllOperations;

- (void)cancelDownloadOperationDownloadItem:(YXTDownloadItem *)downloadItem;
- (void)cancelAllOperations;

- (BOOL)deleteFinishedFileWithFileName:(NSString *)fileName;

- (NSString *)downloadPathWithFileName:(NSString *)fileName;
- (YXTDownloaderFileState)fileDownloadStateWithFilename:(NSString *)fileName;

@end
