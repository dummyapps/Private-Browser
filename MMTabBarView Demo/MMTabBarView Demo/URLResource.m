//
//  URLRequest.m
//  EasyWebBrowser
//
//  Created by fun on 2/13/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//

#import "GlobalObject.h"
#import "URLResource.h"
#import "FileManagerProxy.h"

@implementation URLResource
-(id)init{
    self  = [super init];
    if(self){
        self.isFinished = NO;
        self.isError = NO;
        self.data = [NSMutableData data];
        /*
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"test"];
        self.targetPath = [path stringByAppendingPathComponent:[targetURL lastPathComponent]];
        self.url = targetURL;
         */
    }
    
    return self;
}



-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    self.finishedLength += bytesWritten;
    
}
/*
 2.恢复下载的时候调用该方法
 fileOffset:恢复之后，要从文件的什么地方开发下载
 expectedTotalBytes：该文件数据的总大小
 */
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}
/*
 3.下载完成之后调用该方法
 */
-(void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location{
    self.isError = NO;
    self.isFinished = YES;
    //  [tmpResource.data appendData:dataSource.data];
    if(self.manualDownloadFilePath){
        NSURL *tmpNURL = [[FileManagerProxy sharedInstance]createUniqueURLFromURL:[NSURL fileURLWithPath:self.manualDownloadFilePath]];
        [[NSFileManager defaultManager]moveItemAtURL:location toURL:tmpNURL error:nil];
        NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], NSFileModificationDate,[NSDate date], NSFileCreationDate ,NULL];
        
        [[NSFileManager defaultManager] setAttributes: attr ofItemAtPath: tmpNURL.path error: NULL];
    }
   [ [GlobalObject sharedObj] finishResource:self];
}
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    self.isError = YES;
    self.isFinished = YES;
    [ [GlobalObject sharedObj] abortResource:self];
}

@end
