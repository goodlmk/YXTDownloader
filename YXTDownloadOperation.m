//
//  YXTDownloadOperation.m
//  DownLoader
//
//  Created by Limingkai on 16/1/13.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//

#import "YXTDownloadOperation.h"

@interface YXTDownloadOperation ()
/**
 *  用来写数据的文件句柄对象
 */

@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, strong) NSString *tempFilePath;
@property (nonatomic, strong) NSString *destinationPath;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) NSInteger totalLength;
@property (nonatomic, assign) NSInteger currentLength;
@property (nonatomic, strong) NSThread *thread;

@end

@implementation YXTDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(NSURLRequest *)request tempFilePath:(NSString *)tempFilePath destinationPath:(NSString *)destinationPath startBlock:(YXTDownloaderStartBlock)startBlock progress:(YXTDownloaderProgressBlock)progressBlock complted:(YXTDownloaderCompletedBlock)completedBlock error:(YXTDownlaoderErrorBlock)errorBlock {
    if (self = [super init]) {
        
        _request = request;
        _tempFilePath = tempFilePath;
        _destinationPath = destinationPath;
        _startBlock = startBlock;
        _progressBlock = progressBlock;
        _completedBlock = completedBlock;
        _errorBlock = errorBlock;
        _executing = YES;
        _finished = NO;
        _currentLength = (NSInteger)[self fileSizeForPath:tempFilePath];
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        if (self.isCancelled) {
            [self willChangeValueForKey:@"isFinished"];
            _finished  = YES;
            [self didChangeValueForKey:@"isFinished"];
            [self reset];
            return;
        }
        [self willChangeValueForKey:@"isExecuting"];
        _executing = YES;
        [self didChangeValueForKey:@"isExecuting"];
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        self.thread = [NSThread currentThread];
    }
    [self.connection start];
    CFRunLoopRun();
}

- (void)cancel {
    @synchronized (self) {
        if (self.thread) {
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
        else {
            [self cancelInternal];
        }
    }
}

- (void)cancelInternalAndStop {
    NSLog(@"stop");
    [self cancelInternal];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)cancelInternal {
    NSLog(@"stop1");
    if (self.isFinished) return;
    [super cancel];
    if (self.connection) {
        [self.connection cancel];
        if (self.isExecuting) {
            [self willChangeValueForKey:@"isExecuting"];
            _executing = NO;
            [self didChangeValueForKey:@"isExecuting"];
        }
        if (!self.isFinished) {
            [self willChangeValueForKey:@"isFinished"];
            _finished  = YES;
            [self didChangeValueForKey:@"isFinished"];
        }
    } else {
        NSLog(@"self.connection has not find");
    }
    NSLog(@"stop2");
    
    [self reset];
}

- (BOOL) isFinished{
    
    return _finished;
}

- (BOOL) isExecuting{
    
    return _executing;
}


- (BOOL)isConcurrent {
    return YES;
}

- (void)done {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _finished  = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self reset];
}

- (void)reset {
    self.connection = nil;
    self.startBlock = nil;
    self.completedBlock = nil;
    self.progressBlock = nil;
    self.errorBlock = nil;
    self.thread = nil;
    self.writeHandle = nil;
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

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    CFRunLoopStop(CFRunLoopGetCurrent());
    if (self.errorBlock) {
        self.errorBlock();
    }
    NSLog(@"error is %@",error);
    [self done];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"response is %@",response);
    if (![response respondsToSelector:@selector(statusCode)] || [((NSHTTPURLResponse *)response) statusCode] < 400) {
        NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        self.totalLength = expected;
        
        if (self.startBlock) {
            self.startBlock();
        }
        if (self.progressBlock) {
            self.progressBlock(_currentLength, expected);
        }
        
        NSFileManager* mgr = [NSFileManager defaultManager];
        if (![mgr fileExistsAtPath:_tempFilePath]) {
            [mgr createFileAtPath:_tempFilePath contents:nil attributes:nil];
        }
        
        self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFilePath];
        NSLog(@"tempFilePath is %@",self.tempFilePath);
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.writeHandle seekToEndOfFile];
    
    // 将数据写入沙盒
    [self.writeHandle writeData:data];
    
    // 累计写入文件的长度
    self.currentLength += data.length;
    
    if (self.progressBlock) {
        self.progressBlock(_currentLength, self.totalLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    CFRunLoopStop(CFRunLoopGetCurrent());
    
    
    self.currentLength = 0;
    self.totalLength = 0;
    
    // 关闭文件
    [self.writeHandle closeFile];
    self.writeHandle = nil;
    
    [[NSFileManager defaultManager] moveItemAtPath:self.tempFilePath toPath:self.destinationPath error:NULL];
    if(self.completedBlock) {
        self.completedBlock();
    }
    
    [self done];
}


@end
