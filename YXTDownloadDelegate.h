//
//  YXTDownloadDelegate.h
//  DownLoader
//
//  Created by Limingkai on 16/1/15.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YXTDownloadItem.h"

@protocol YXTDownloadDelegate <NSObject>

@optional
- (void)startDownload:(YXTDownloadItem *)downloadItem;
- (void)updateProgress:(YXTDownloadItem *)downloadItem;
- (void)finishedDownload;
- (void)downloadError:(YXTDownloadItem *)downloadItem;

@end
