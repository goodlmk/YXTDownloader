//
//  DownloadItem.m
//  DownLoader
//
//  Created by Limingkai on 16/1/15.
//  Copyright © 2016年 SINOSOFT. All rights reserved.
//

#import "YXTDownloadItem.h"

static NSString * const kFileName = @"kFileName";
static NSString * const kFileType = @"kFileType";
static NSString * const kTargetPath = @"kTargetPath";
static NSString * const kImageURL = @"kImageURL";
static NSString * const kTotalSize = @"kTotalSize";
static NSString * const kDownloadURL = @"kDownloadURL";

@implementation YXTDownloadItem

- (instancetype)initWithFileName:(NSString *)fileName fileType:(NSString *)fileType downloadURL:(NSString *)downloadURL imageURL:(NSString *)imageURL totalSize:(CGFloat)totalSize {
    if (self = [super init]) {
        _fileName = fileName;
        _fileType = fileType;
        _downloadURL = downloadURL;
        _imageURL = imageURL;
        _receivedSize = 0.0f;
        _totalSize = totalSize;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _fileName = [aDecoder decodeObjectForKey:kFileName];
        _fileType = [aDecoder decodeObjectForKey:kFileType];
        _downloadURL = [aDecoder decodeObjectForKey:kDownloadURL];
        _targetPath = [aDecoder decodeObjectForKey:kTargetPath];
        _imageURL = [aDecoder decodeObjectForKey:kImageURL];
        _totalSize = [aDecoder decodeFloatForKey:kTotalSize];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_fileName forKey:kFileName];
    [aCoder encodeObject:_fileType forKey:kFileType];
    [aCoder encodeObject:_downloadURL forKey:kDownloadURL];
    [aCoder encodeObject:_targetPath forKey:kTargetPath];
    [aCoder encodeObject:_imageURL forKey:kImageURL];
    [aCoder encodeFloat:_totalSize forKey:kTotalSize];
}

@end
