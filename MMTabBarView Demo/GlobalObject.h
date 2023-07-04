//
//  GlobalObject.h
//  EasyWebBrowser
//
//  Created by fun on 2/13/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebViewController.h"
#import "WebBrowserWindowController.h"
#import "URLResource.h"
#import "PreferenceViewController.h"
#import "MMBookmarkController.h"
@interface GlobalObject : NSObject
@property NSMutableArray *tabItemIdentities;
@property WebBrowserWindowController *windowController;
@property WebViewController *webviewController;
@property NSMutableArray *resources;
@property NSMutableArray *unfinishedResources;
@property NSMutableDictionary *resourceHash;
@property NSTableView *taskTableview;
@property PreferenceViewController *preferenceController;
@property MMBookmarkController *bookmarkController;
+(void)showAlert:(NSString *)alertMessage;
+(id)sharedObj;
+(BOOL)isURLAllow:(NSURL *)url;
-(BOOL)addResource:(URLResource *)resource;
-(URLResource *)getResourceByID:(NSNumber *)ID;
-(void)finishResource:(URLResource *)resource;
-(void)abortResource:(URLResource *)resource;
-(void)abortAllResource;
-(NSString *)goodFileName:(NSString *)oldFileName;
-(void)playSlideshowSounds;
@end
