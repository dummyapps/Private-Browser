//
//  WebViewController.h
//  EasyWebBrowser
//
//  Created by fun on 2/12/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@interface WebViewController : NSViewController
+(id)createNewWebViewWithURL:(NSString *)url;
+(id)createNewWebViewWithRequest:(NSURLRequest *)request;
- (void)webpageFinishedNotification:(NSNotification*)theNotification;
@end

@interface MyWebView : WebView
@property double zoomValue;
@property (weak) NSScrollView *outScrollView;


-(void)zoomOut;
-(void)zoomIn;
-(void)zoomOrignal;
@end




