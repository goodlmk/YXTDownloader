//
//  YXTDownloader.m
//  DownLoader
//
//  Created by Limingkai on 16/1/13.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//

#import "YXTDownloader.h"
#import "YXTDownloadOperation.h"
#import "YXTDownloadItem.h"

@interface YXTDownloader ()

@property (nonatomic, strong) NSMutableArray *finishedArray;
@property (nonatomic, strong) NSMutableArray *downloadingArray;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary *operations;

@end

@implementation YXTDownloader

+ (instancetype)sharedInstant {
    
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (NSMutableArray *)downloadingArray {
    if (!_downloadingArray) {
        NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:[self downloadPathWithFileName:@"downloadingList"]];
        if (!array) {
            array = [NSMutableArray arrayWithCapacity:3];
        }
        _downloadingArray = array;
    }
    return _downloadingArray;
}

- (NSMutableArray *)finishedArray {
    if (!_finishedArray) {
        NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile:[self downloadPathWithFileName:@"finishedList"]];
        if (!array) {
            array = [NSMutableArray arrayWithCapacity:3];
        }
        _finishedArray = array;
    }
    return _finishedArray;
}

- (NSArray *)filesfinishedArray {
    @synchronized(self) {
        return [self.finishedArray copy];
    }
}

- (NSArray *)filesdownloadingArray {
    @synchronized(self) {
         return [self.downloadingArray copy];   
    }
}

- (id)init {
    if ((self = [super init])) {
        _operationQueue = [NSOperationQueue new];
        _operationQueue.maxConcurrentOperationCount = 1;
        _operations = [[NSMutableDictionary alloc] init];

    }
    return self;
}


#pragma mark - Public Methods

- (YXTDownloadOperation *)downloadWithDownloadItem:(YXTDownloadItem *)downloadItem {
    return [self downloadWithDownloadItem:downloadItem isAddItemToDownloadList:YES];
}

- (YXTDownloadOperation *)downloadWithDownloadItem:(YXTDownloadItem *)downloadItem isAddItemToDownloadList:(BOOL)isAdd {
    
    if (isAdd) {
        for (YXTDownloadItem *item in self.downloadingArray) {
            if ([item.downloadURL isEqualToString:downloadItem.downloadURL]) {
                return nil;
            }
        }
        [self.downloadingArray addObject:downloadItem];
        [self saveDownloadingList];
    }
    YXTDownloadOperation *operation;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:downloadItem.downloadURL]];
    //存在缓存文件则断点下载
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getCacheFileWithName:downloadItem.fileName] isDirectory:nil]) {
        unsigned long long downloadedBytes = [self fileSizeForPath:[self getCacheFileWithName:downloadItem.fileName]];
        if (downloadedBytes > 1) {
            downloadedBytes--;
            ;
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            [request setValue:requestRange forHTTPHeaderField:@"Range"];
        }
    }
    __weak typeof(self) weakSelf = self;
    downloadItem.downloadState = YXTDownloadStateWaiting;
    operation = [[YXTDownloadOperation alloc] initWithRequest:request tempFilePath:[self getCacheFileWithName:downloadItem.fileName] destinationPath:[self downloadPathWithFileName:downloadItem.fileName] startBlock:^{
        downloadItem.downloadState = YXTDownloadStateStarting;
        if ([weakSelf.delegate respondsToSelector:@selector(startDownload:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate startDownload:downloadItem];
            });
        }
    } progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        downloadItem.totalSize = expectedSize;
        downloadItem.receivedSize = receivedSize;
        if ([weakSelf.delegate respondsToSelector:@selector(updateProgress:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate updateProgress:downloadItem];
            });
        }
    } complted:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            downloadItem.downloadState = YXTDownloadStateFinished;
            downloadItem.targetPath = [weakSelf downloadPathWithFileName:downloadItem.fileName];
            [weakSelf.finishedArray addObject:downloadItem];
            if ([weakSelf.downloadingArray containsObject:downloadItem]) {
                [weakSelf.downloadingArray removeObject:downloadItem];
            }
            [weakSelf saveDownloadingList];
            [weakSelf saveFinishList];
            
            if ([weakSelf.delegate respondsToSelector:@selector(finishedDownload)]) {
                [weakSelf.delegate finishedDownload];
            }
        });
        
    } error:^{
        downloadItem.downloadState = YXTDownloadStateError;
        [weakSelf saveDownloadingList];
        if ([weakSelf.delegate respondsToSelector:@selector(downloadError:)]) {
           dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate downloadError:downloadItem];
           });
        }
    }];
    
    [self.operations setValue:operation forKey:downloadItem.downloadURL];
    [self.operationQueue addOperation:operation];
    return operation;
}

- (void)pauseOperationWithDownloadURL:(NSString *)downloadURL {
    YXTDownloadOperation *operation = self.operations[downloadURL];
    if (operation) {
        [operation cancel];
        [self.operations removeObjectForKey:downloadURL];
        operation = nil;
    }
    for (YXTDownloadItem *downloadItem in self.downloadingArray) {
        if ([downloadURL isEqualToString:downloadItem.downloadURL]) {
            downloadItem.downloadState = YXTDownloadStateWaiting;
        }
    }
    [self saveDownloadingList];
}

- (void)resumeOpreationWithDownloadURL:(NSString *)downloadURL {
    
    for (YXTDownloadItem *downloadItem in self.downloadingArray) {
        if ([downloadURL isEqualToString:downloadItem.downloadURL] && downloadItem.downloadState == YXTDownloadStateWaiting) {
            [self downloadWithDownloadItem:downloadItem isAddItemToDownloadList:NO];
        }
    }
}

- (void)resumeAllOperations {
    for (YXTDownloadOperation *operation in self.operations.allValues) {
        [operation cancel];
    }
    [self.operations removeAllObjects];
    for (YXTDownloadItem *downloadItem in self.downloadingArray) {
        [self downloadWithDownloadItem:downloadItem isAddItemToDownloadList:NO];
    }
}

- (void)cancelDownloadOperationDownloadItem:(YXTDownloadItem *)downloadItem {
    YXTDownloadOperation *operation = self.operations[downloadItem.downloadURL];
    if (operation) {
        [operation cancel];
        [self.operations removeObjectForKey:downloadItem.downloadURL];
    }
    [self.finishedArray filterUsingPredicate:[NSPredicate predicateWithFormat:@"downloadURL!=%@", downloadItem.downloadURL]];
    [self deleteFileWithFilePath:[self getCacheFileWithName:downloadItem.fileName]];
    [self saveDownloadingList];
}

- (void)cancelAllOperations {
    
    for (YXTDownloadOperation *operation in self.operations.allValues) {
        [operation cancel];
    }
    [self.operations removeAllObjects];
    for (YXTDownloadItem *downloadItem in self.downloadingArray) {
        [self deleteFileWithFilePath:[self getCacheFileWithName:downloadItem.fileName]];
    }
    [self.downloadingArray removeAllObjects];
    [self saveDownloadingList];
}


- (BOOL)deleteFinishedFileWithFileName:(NSString *)fileName {
    
    [self.finishedArray filterUsingPredicate:[NSPredicate predicateWithFormat:@"fileName!=%@", fileName]];
    [self saveFinishList];
    return [self deleteFileWithFilePath:[self downloadPathWithFileName:fileName]];
}

- (YXTDownloaderFileState)fileDownloadStateWithFilename:(NSString *)fileName {
    NSFileManager *mamager = [NSFileManager new];
    
    if ([mamager fileExistsAtPath:[self downloadPathWithFileName:fileName]]) {
        return YXTDownloaderFileStateFininshed;
    } else if ([self fileIsDownloadingWithFileName:fileName]) {
        YXTDownloadItem *downloadItem = [self fileIsDownloadingWithFileName:fileName];
        switch (downloadItem.downloadState) {
            case YXTDownloadStateWaiting:
            case YXTDownloadStateStarting:
                return YXTDownloaderFileStateDownloading;
                break;
            case YXTDownloadStateError:
                return YXTDownloaderFileStateError;
                break;
            default:
                return YXTDownloaderFileStateNoDownload;
                break;
        }
    }
    return YXTDownloaderFileStateNoDownload;
}

#pragma mark - Private Methods

- (BOOL)deleteFileWithFilePath:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    return YES;
}



- (YXTDownloadItem *)fileIsDownloadingWithFileName:(NSString *)fileName {
    
    for (YXTDownloadItem *item in self.downloadingArray) {
        if ([item.fileName isEqualToString:fileName]) {
            return item;
        }
    }
    return nil;
}

- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

- (void)saveDownloadingList {
    [NSKeyedArchiver archiveRootObject:self.downloadingArray toFile:[self downloadPathWithFileName:@"downloadingList"]];
}

- (void)saveFinishList {
    [NSKeyedArchiver archiveRootObject:self.finishedArray toFile:[self downloadPathWithFileName:@"finishedList"]];
}

+ (NSString *)cacheFolder {
    NSFileManager *filemgr = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        cacheFolder = [cacheDir stringByAppendingPathComponent:@"yxttemp"];
    }
    
    // ensure all cache directories are there
    NSError *error = nil;
    if(![filemgr createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

+ (NSString *)documentsFolder {
    @synchronized(self) {
        NSFileManager *filemgr = [NSFileManager new];
        static NSString *cacheFolder;
        
        if (!cacheFolder) {
            NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            cacheFolder = [cacheDir stringByAppendingPathComponent:@"yxtdownload"];
        }
        
        // ensure all cache directories are there
        NSError *error = nil;
        if(![filemgr createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create cache directory at %@", cacheFolder);
            cacheFolder = nil;
        }
        return cacheFolder;
    }
}

- (NSString *)getCacheFileWithName:(NSString *)fileName {
    return [[[self class] cacheFolder] stringByAppendingPathComponent:fileName];
}

- (NSString *)downloadPathWithFileName:(NSString *)filename {
    return [[[self class] documentsFolder] stringByAppendingPathComponent:filename];
}



@end
