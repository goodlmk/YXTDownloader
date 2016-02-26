//
//  YXTDownloadOperation.h
//  DownLoader
//
//  Created by Limingkai on 16/1/13.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "YXTDownloader.h"

@interface YXTDownloadOperation : NSOperation

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (nonatomic, copy) YXTDownloaderProgressBlock progressBlock;
@property (nonatomic, copy) YXTDownloaderCompletedBlock completedBlock;
@property (nonatomic, copy) YXTDownloaderStartBlock startBlock;
@property (nonatomic, copy) YXTDownlaoderErrorBlock errorBlock;

- (id)initWithRequest:(NSURLRequest *)request tempFilePath:(NSString *)tempFilePath destinationPath:(NSString *)destinationPath startBlock:(YXTDownloaderStartBlock)startBlock progress:(YXTDownloaderProgressBlock)progressBlock complted:(YXTDownloaderCompletedBlock)completedBlock error:(YXTDownlaoderErrorBlock)errorBlock;

@end
