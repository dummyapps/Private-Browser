//
//  URLRequest.h
//  EasyWebBrowser
//
//  Created by fun on 2/13/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TabitemIdentity.h"
#import "AFNetworking.h"
@interface URLResource : NSObject <NSURLSessionDelegate>
-(id)init;
@property id parent;
@property NSString *mimeType;
@property NSImage *icon;
@property NSURL *url;
@property NSNumber *id;
@property NSUInteger length;
@property NSUInteger finishedLength;
//@property AFHTTPRequestOperation* operation;
@property NSMutableData *data;
@property NSString *filename;
@property BOOL isFinished;
@property BOOL isError;
@property NSURL *hostURL;
@property NSString *manualDownloadFilePath;//for manual downloading

@property NSURLSession *session;
@property NSURLSessionDownloadTask *downloadTask;
@end
