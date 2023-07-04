//
//  WebViewController.m
//  EasyWebBrowser
//
//  Created by fun on 2/12/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//
#import <EasyWebBrowser/MMTabBarView.h>
#import "WebViewController.h"
#import "GlobalObject.h"
#import "TabitemIdentity.h"
#import "PreferenceViewController.h"
#import "WebBrowserWindowController.h"
static WebViewController *singleStone;
@interface WebViewController ()
@end
#define FIX_LEFT    NSViewMinXMargin
#define FIX_RIGHT   NSViewMaxXMargin
#define FIX_TOP     NSViewMinYMargin
#define FIX_BOTTOM  NSViewMaxYMargin
#define FIX_WIDTH   NSViewWidthSizable
#define FIX_HEIGHT  NSViewHeightSizable

@class WebBasePluginPackage;
@interface WebView ( MyFlashPluginHack )
- (WebBasePluginPackage *)_pluginForMIMEType:(NSString *)MIMEType;
@end

@implementation MyWebView


- (WebBasePluginPackage *)_pluginForMIMEType:(NSString *)MIMEType
{
  
    if ( [MIMEType isEqualToString:@"application/x-shockwave-flash"] )
    {
       
            return [super _pluginForMIMEType:@"application/my-plugin-type"];
        
    }
    else
    {
        return [super _pluginForMIMEType:MIMEType];
    }
}
- (id)initWithCoder:(NSCoder *)coder
{
    /*------------------------------------------------------
     Init method called for Interface Builder objects
     --------------------------------------------------------*/
    self=[super initWithCoder:coder];
    if ( self ) {
         self.zoomValue =1.0;
        //register for all the image types we can display
      //  [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        if([[NSUserDefaults standardUserDefaults]boolForKey:MOBILE_MODE_KEY] == YES){
           [self setCustomUserAgent:@"Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"];
            
        }else{
            [self setCustomUserAgent:nil];
        }
        
        
    }
    return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    /*------------------------------------------------------
     accept activation click as click in window
     --------------------------------------------------------*/
    //so source doesn't have to be the active window
    return YES;
}

#pragma mark - Destination Operations
#if 0
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    
    return NSDragOperationCopy;
    
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    @autoreleasepool {
     
        NSPasteboard* pboard = [sender    draggingPasteboard];
        
        //pathes是string
        NSArray* paths = [pboard propertyListForType:NSFilenamesPboardType];
        NSString* filePath = paths.firstObject;
        NSURL* fileURL = [NSURL fileURLWithPath:filePath];
        NSURLRequest* request = [NSURLRequest requestWithURL:fileURL];
        [[self mainFrame] loadRequest:request];
        
      //  GlobalObject *tmpGlobal = [GlobalObject sharedObj];
      //  [tmpGlobal.windowController updateCurrentWebviewMainFrame];
    }
    
    return YES;
}
#endif

-(id)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if(self){
        self.zoomValue =1.0;
      //   [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}

//缩小
-(void)zoomOut{
    @autoreleasepool {
        
        
        if((self.zoomValue -0.1) <1.0)
            return;
        
        self.zoomValue -=0.1;
        
        [[[[self mainFrame] frameView] documentView] scaleUnitSquareToSize:NSMakeSize(self.zoomValue, self.zoomValue)];
        [[[[self mainFrame] frameView] documentView] setNeedsDisplay:YES];
        
        NSScrollView *tmpScrollview=  [[[[self mainFrame] frameView] documentView] enclosingScrollView] ;
        if([tmpScrollview respondsToSelector:@selector(magnification)] == YES){
            tmpScrollview.maxMagnification = 5.0;
            tmpScrollview.minMagnification  =1.0;
            tmpScrollview.allowsMagnification = YES;
        }

    }
}

-(void)zoomIn{
    self.zoomValue +=0.1;
    
    [[[[self mainFrame] frameView] documentView] scaleUnitSquareToSize:NSMakeSize(self.zoomValue, self.zoomValue)];
    [[[[self mainFrame] frameView] documentView] setNeedsDisplay:YES];
}
-(void)zoomOrignal{
    self.zoomValue =1.0;
    
    [[[[self mainFrame] frameView] documentView] scaleUnitSquareToSize:NSMakeSize(self.zoomValue, self.zoomValue)];
    [[[[self mainFrame] frameView] documentView] setNeedsDisplay:YES];
}

@end
@implementation WebViewController
+(id)sharedObj{
    if(singleStone == nil){
        singleStone = [[WebViewController alloc] init];
    }
    
    return singleStone;
}


- (void)boundDidChange:(NSNotification *)notification {
    // get the changed content view from the notification
    NSClipView *changedContentView=[notification object];
    WebBrowserWindowController *windowController = [[GlobalObject sharedObj] windowController];
    NSTabViewItem *currentItem = [[windowController getTabView] selectedTabViewItem];
    TabitemIdentity *currID = currentItem.identifier;
    MyWebView *currWebview =(MyWebView *) currID.webview;
    if(currWebview == nil)
        return;
    
#if 0
    NSScrollView *tmpScrollview=  [[[[currWebview mainFrame] frameView] documentView] enclosingScrollView] ;
    /*
    if(tmpScrollview.contentView != changedContentView)
        return;
    */
   // [currWebview.mainFrame.frameView.documentView scaleUnitSquareToSize:NSMakeSize(tmpScrollview.magnification, tmpScrollview.magnification)];
   // [currWebview.mainFrame.frameView.documentView setNeedsDisplay:YES];
    
    NSArray *subViews = [changedContentView.documentView subviews];
    for(WebFrameView *i in subViews){
        [i.documentView scaleUnitSquareToSize:NSMakeSize(tmpScrollview.magnification, tmpScrollview.magnification)];
        [i.documentView setNeedsDisplay:YES];
    }
#endif
    
    [changedContentView setNeedsDisplay:YES];
    [currWebview.mainFrame.frameView.documentView setNeedsDisplay:YES];
    [currWebview.mainFrame.frameView setNeedsDisplay:YES];
    [currWebview setNeedsDisplay:YES];
   // NSScrollView *tmpScrollview=  [[[[wv mainFrame] frameView] documentView] enclosingScrollView] ;
    //if([tmpScrollview respondsToSelector:@selector(magnification)] == YES){
    
    /*
    [[[[webView mainFrame] frameView] documentView] scaleUnitSquareToSize:NSMakeSize(1.5, 1.5)];
    [[[[webView mainFrame] frameView] documentView] setNeedsDisplay:YES];
     */
}

+(id)createNewWebViewWithURL:(NSString *)url{
    MyWebView * wv = [[MyWebView alloc] initWithFrame:NSZeroRect];
    
    id delegate = [self sharedObj];
    [wv setAutoresizingMask:FIX_WIDTH|FIX_HEIGHT];
    if([[NSUserDefaults standardUserDefaults]boolForKey:MOBILE_MODE_KEY] == YES){
        [wv setCustomUserAgent:@"Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"];
        
        
    }else{
        [wv setCustomUserAgent:nil];
    }
    
    
#if 1
    NSScrollView *tmpScrollview=  [[[[wv mainFrame] frameView] documentView] enclosingScrollView] ;
    if([tmpScrollview respondsToSelector:@selector(magnification)] == YES){
        tmpScrollview.maxMagnification = 5.0;
        tmpScrollview.minMagnification  =1.0;
        tmpScrollview.allowsMagnification = YES;
#if 0
        NSView *contentView = [tmpScrollview contentView];
        
       // [contentView setPostsBoundsChangedNotifications:YES];
        [contentView setPostsFrameChangedNotifications:YES];
        
        // a register for those notifications on the content view.
        [[NSNotificationCenter defaultCenter] addObserver:singleStone
                                                 selector:@selector(boundDidChange:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:contentView];
#endif
        
    }
#endif
    //wv.drawsBackground = YES;
    wv.shouldUpdateWhileOffscreen= YES;
    wv.downloadDelegate = delegate;
    wv.frameLoadDelegate = delegate;
    wv.resourceLoadDelegate = delegate;
    wv.UIDelegate = delegate;
    wv.policyDelegate = delegate;
    
    // WebHistory *myHistory = [[WebHistory alloc] init];
    
    //NSString *WebViewProgressEstimateChangedNotification = @"WebViewProgressStartedNotification";
    // [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(webpageFinishedNotification:) name:WebViewProgressFinishedNotification object:wv];
    if(url)
        [[wv mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    
    else{
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [[wv mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[tmpGlobal.preferenceController defaultURL]]]];
    }
    
    return wv;
}

+(id)createNewWebViewWithRequest:(NSURLRequest *)request{
    MyWebView * wv = [[MyWebView alloc] initWithFrame:NSZeroRect];
   
    id delegate = [self sharedObj];
    [wv setAutoresizingMask:FIX_WIDTH|FIX_HEIGHT];
    
    wv.shouldUpdateWhileOffscreen= YES;
    wv.downloadDelegate = delegate;
    wv.frameLoadDelegate = delegate;
    wv.resourceLoadDelegate = delegate;
    wv.UIDelegate = delegate;
    wv.policyDelegate = delegate;
    if([[NSUserDefaults standardUserDefaults]boolForKey:MOBILE_MODE_KEY] == YES){
        [wv setCustomUserAgent:@"Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"];
        
        
        
    }else{
        [wv setCustomUserAgent:nil];
    }
   
    NSScrollView *tmpScrollview=  [[[[wv mainFrame] frameView] documentView] enclosingScrollView] ;
    if([tmpScrollview respondsToSelector:@selector(magnification)] == YES){
        tmpScrollview.maxMagnification = 5.0;
        tmpScrollview.minMagnification  =1.0;
        tmpScrollview.allowsMagnification = YES;
    }
    
    //NSString *WebViewProgressEstimateChangedNotification = @"WebViewProgressStartedNotification";
    // [[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(webpageFinishedNotification:) name:WebViewProgressFinishedNotification object:wv];
    if(request)
        [[wv mainFrame] loadRequest:request];
    else{
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [[wv mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[tmpGlobal.preferenceController defaultURL]]]];
    }
    
    
    return wv;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

//notifications
- (void)webpageFinishedNotification:(NSNotification*)theNotification {
    GlobalObject *tmpObj = [GlobalObject sharedObj];
    for(TabitemIdentity *i in tmpObj.tabItemIdentities){
        if(i.webview == theNotification.object){
            i.isProcessing = NO;
        }
    }
}

-(BOOL)isValidPic:(NSURL *)url{
    if(url == nil)
        return NO;
    
    NSString *fileExt = [url pathExtension];
    return [[NSWorkspace sharedWorkspace] filenameExtension:fileExt isValidForType:(__bridge NSString *)kUTTypeImage];
}

//frame delegate
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    @autoreleasepool {
        
    
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        
        for(TabitemIdentity *i in tmpObj.tabItemIdentities){
            if(i.webview == sender){
                i.title = [title copy];
            }
        }
    }
    }
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image
       forFrame:(WebFrame *)frame
{
    @autoreleasepool {
        
    
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        
        for(TabitemIdentity *i in tmpObj.tabItemIdentities){
            if(i.webview == sender){
                i.icon = [image copy];
            }
        }
    }
    }

}
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame{
    @autoreleasepool {
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        [tmpObj.windowController updateCurrentWebviewMainFrame];
        for(TabitemIdentity *i in tmpObj.tabItemIdentities){
            if(i.webview == sender){
                i.isProcessing = YES;
            }
        }
    }
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    @autoreleasepool {
        
    
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        
        for(TabitemIdentity *i in tmpObj.tabItemIdentities){
            if(i.webview == sender){
                i.isProcessing = NO;
            }
        }
    }
    }
}
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame
                                                         *)frame
{
    @autoreleasepool {
        
    
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        
        for(TabitemIdentity *i in tmpObj.tabItemIdentities){
            if(i.webview == sender){
                i.isProcessing = NO;
            }
        }
    }
    }
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    @autoreleasepool {
        
    
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        
        for(TabitemIdentity *i in tmpObj.tabItemIdentities){
            if(i.webview == sender){
                i.isProcessing = NO;
            }
        }
    }
    }
}

- (void)webViewClose:(WebView *)sender{
    
    GlobalObject *tmpObj = [GlobalObject sharedObj];
    
    NSArray *unfinishedArray = [NSArray arrayWithArray: tmpObj.unfinishedResources];
    for(URLResource *j in unfinishedArray){
        if(j.parent == sender)
            if(j.manualDownloadFilePath == nil)
                [tmpObj abortResource:j];
    }
}
- (void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame{
    @autoreleasepool {
    return;
        
    if (frame == [sender mainFrame]) {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        
        NSArray *unfinishedArray = [NSArray arrayWithArray: tmpObj.unfinishedResources];
        for(URLResource *j in unfinishedArray){
            if(j.parent == sender)
                if(j.manualDownloadFilePath == nil)
                    [tmpObj abortResource:j];
        }
    }
    }
}
/*
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge fromDataSource:(WebDataSource *)dataSource{
    return;
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource{
    return request;
}
 */
//ui delegate
/*
- (void)webView:(WebView *)sender setFrame:(NSRect)frame{
    return;
}
- (BOOL)webViewIsResizable:(WebView *)sender{
    return YES;
}
*/

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    
   // if ([[NSApp currentEvent] type] == NSLeftMouseUp)
   // NSEvent *theEvent = [NSApp currentEvent ];
    GlobalObject *tmpObj = [GlobalObject sharedObj];
    bool ret = [[NSUserDefaults standardUserDefaults] boolForKey:ALWAYS_CREATE_NEW_WEBVIEW];
    if(ret == YES)
        return  [tmpObj.windowController addNewTabWithRequest:request];
    else{
        [[sender mainFrame] loadRequest:request];
        return sender;
    }
}
- (WebView *)webView:(WebView *)sender createWebViewModalDialogWithRequest:(NSURLRequest *)request{
    GlobalObject *tmpObj = [GlobalObject sharedObj];
    bool ret = [[NSUserDefaults standardUserDefaults] boolForKey:ALWAYS_CREATE_NEW_WEBVIEW];
    if(ret == YES)
        return  [tmpObj.windowController addNewTabWithRequest:request];
    else{
        [[sender mainFrame] loadRequest:request];
        return sender;
    }
}



//resource delegate
- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource{
    if([[NSUserDefaults standardUserDefaults] boolForKey:START_DOWNLOAD_KEY] == YES){
        static NSUInteger identifyNumber = 0;
        NSNumber *newIDNumber = [NSNumber numberWithInteger:identifyNumber];
        identifyNumber ++;
        return newIDNumber;
    }else
        return nil;
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource{
    @autoreleasepool {
         if([GlobalObject isURLAllow:[NSURL URLWithString:sender.mainFrameURL]] == NO) return;
#if 0
        if([response.URL.pathExtension.lowercaseString isEqualToString:@"mp4"] == YES){
            return;
        }
#endif
        if([[NSUserDefaults standardUserDefaults] boolForKey:START_DOWNLOAD_KEY] == YES){
            if(identifier){
                GlobalObject *tmpObj = [GlobalObject sharedObj];
                if([response.suggestedFilename length] && (response.expectedContentLength)){
                    NSString *mimeType = response.MIMEType;
                    if(mimeType==nil) return;
                    
                   
                    
                    //   if([mimeType hasPrefix:@"image"] == YES||[mimeType hasPrefix:@"video"] == YES){
                 //   if([WebView  canShowMIMEType:mimeType] == YES)
                    {
                        if([mimeType hasPrefix:@"image"] == NO) return;
                        
                        URLResource *newResource = [[URLResource alloc]init ];
                        newResource.parent = sender;
                        newResource.id  = identifier;
                        newResource.mimeType = [mimeType.lowercaseString copy];
                        newResource.url = response.URL;
                        newResource.hostURL = [NSURL URLWithString:[sender mainFrameURL] ];
                        newResource.length = response.expectedContentLength;
                        newResource.filename = response.suggestedFilename;
                        // NSLog(@"Add filename: %@  length: %ld url:%@",newResource.filename, newResource.length, newResource.url);
                        [tmpObj  addResource:newResource];
                        
#if 0
                        if([newResource.mimeType hasPrefix:@"image"] == NO){
                            //1.确定请求路径
                            if([newResource.mimeType hasPrefix:@"video"] == NO){
                                [tmpObj abortResource:newResource];
                                return;
                            }
                            
                            NSString *destinationFilename;
                            /*
                             NSString *homeDirectory = NSHomeDirectory();
                             
                             destinationFilename = [[homeDirectory stringByAppendingPathComponent:@"Desktop"]
                             stringByAppendingPathComponent:newResource.filename];
                             */
                            
                            destinationFilename= [tmpObj.preferenceController resourceSavedPath:newResource];
                            if(destinationFilename){
                                newResource.manualDownloadFilePath = [destinationFilename copy];
                            }else{
                                return;
                            }
                            
                            //2.创建请求对象
                            //请求对象内部默认已经包含了请求头和请求方法（GET）
                            NSURLRequest *request = [NSURLRequest requestWithURL:newResource.url];
                            if(request == nil){
                                [tmpObj abortResource:newResource];
                                return;
                                
                            }
                            //3.获得会话对象,并设置代理
                            /*
                             第一个参数：会话对象的配置信息defaultSessionConfiguration 表示默认配置
                             第二个参数：谁成为代理，此处为控制器本身即self
                             第三个参数：队列，该队列决定代理方法在哪个线程中调用，可以传主队列|非主队列
                             [NSOperationQueue mainQueue]   主队列：   代理方法在主线程中调用
                             [[NSOperationQueue alloc]init] 非主队列： 代理方法在子线程中调用
                             */
                            newResource.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:newResource  delegateQueue:[NSOperationQueue mainQueue]];
                            if(newResource.session == nil){
                                [tmpObj abortResource:newResource];
                                return;
                            }
                            
                            //4.根据会话对象创建一个Task(发送请求）
                            newResource.downloadTask = [newResource.session downloadTaskWithURL:newResource.url];
                            
                            //5.执行任务
                            [newResource.downloadTask resume];
                        }
#endif
                    }
                }
            }
        }
    }
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveContentLength:(NSInteger)length fromDataSource:(WebDataSource *)dataSource{
    @autoreleasepool {
    if(identifier){
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        URLResource *tmpResource = [tmpObj getResourceByID:identifier];
        //if(tmpResource && [tmpResource.mimeType hasPrefix:@"image"] == YES){
            tmpResource.finishedLength += length;
           // NSLog(@"receive filename: %@  length: %ld url:%@",tmpResource.filename, length, tmpResource.url);
          //  [tmpResource.data appendData:dataSource.data];
        //}
    }
    }
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource{
    @autoreleasepool {
        
        if(identifier){
            GlobalObject *tmpObj = [GlobalObject sharedObj];
            URLResource *tmpResource = [tmpObj getResourceByID:identifier];
            if(tmpResource){
                //  NSURL *url = [NSURL URLWithString:[[webView windowScriptObject] evaluateWebScript:]];
                NSURL *url = tmpResource.url;
                if(url){
                    if ([dataSource subresourceForURL:url]) {
                        // NSLog(@"Finish filename: %@  length: %ld url:%@",tmpResource.filename, tmpResource.length, tmpResource.url);
                        NSData *dataToSave = [[dataSource subresourceForURL:url] data];
                        tmpResource.isError = NO;
                        tmpResource.isFinished = YES;
                        [tmpResource.data appendData:dataToSave];
                        [tmpObj finishResource:tmpResource];
                    }else{
                        
                        /*
                         NSArray *tmpArray = [dataSource subresources];
                         for(WebResource *i in tmpArray){
                         NSData *dataToSave = i.data;
                         if(dataToSave.length)
                         [tmpResource.data appendData:dataToSave];
                         }
                         
                         if(tmpResource.data){
                         tmpResource.isFinished = YES;
                         //  [tmpResource.data appendData:dataSource.data];
                         [tmpObj finishResource:tmpResource];
                         }else{
                         [tmpObj abortResource:tmpResource];
                         }
                         */
                        
                        [tmpObj abortResource:tmpResource];
                    }
                }else{
                    [tmpObj abortResource:tmpResource];
                }
            }
        }
    }
    return;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource{
    @autoreleasepool {
        if(identifier){
            GlobalObject *tmpObj = [GlobalObject sharedObj];
            URLResource *tmpResource = [tmpObj getResourceByID:identifier];
            if(tmpResource){
                tmpResource.isFinished = YES;
                tmpResource.isError = YES;
                [tmpObj abortResource:tmpResource];
            }
        }
    }
    return;
}

//policy delegate
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    @autoreleasepool {
        if (WebNavigationTypeLinkClicked == [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue])
        {
            
            if([[actionInformation valueForKey:WebActionModifierFlagsKey] integerValue] &NSCommandKeyMask){
                GlobalObject *tmpGlobal = [GlobalObject sharedObj];
                [tmpGlobal.windowController addNewTabWithRequest:request];
                return;
            }
        }
        [listener use]; // Say for webview to do it work...
    }
}

- (void)webView:(WebView *)webView
decidePolicyForMIMEType:(NSString *)type
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
    if ([WebView canShowMIMEType:type] == YES){
        [listener use  ];
    }else{
        [listener download  ];
    }
#if 0
   if([type isEqualToString:@"text/html"])
   {
       // [listener download];
         [listener use  ];
    }else
         [listener download  ];
#endif
    //just ignore all other types; the default behaviour will be used
}
/*
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id )listener
{
    
    [listener use];
}
*/
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename{
    
}
- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response{
   
    @autoreleasepool {
        GlobalObject *tmpGlobalObj = [GlobalObject sharedObj];
        if([response.suggestedFilename length] && response.expectedContentLength){
            // NSLog(@"%@", response.suggestedFilename);
            URLResource *newResource = [[URLResource alloc]init];
            if(newResource){
                WebBrowserWindowController *tmpWindowController = tmpGlobalObj.windowController;
                NSTabViewItem *currentItem = [[tmpWindowController getTabView] selectedTabViewItem];
                TabitemIdentity *currID = currentItem.identifier;
                WebView *currWebview = currID.webview;
                
                if([GlobalObject isURLAllow:[NSURL URLWithString: currWebview.mainFrameURL] ] == NO) return;
                newResource.mimeType = [response.MIMEType.lowercaseString copy];
                newResource.url = response.URL;
                newResource.length = response.expectedContentLength;
                newResource.filename = response.suggestedFilename;
                newResource.parent = download;
                newResource.hostURL = [NSURL URLWithString:[currWebview mainFrameURL]];
                NSString *destinationFilename;
                /*
                 NSString *homeDirectory = NSHomeDirectory();
                 
                 destinationFilename = [[homeDirectory stringByAppendingPathComponent:@"Desktop"]
                 stringByAppendingPathComponent:newResource.filename];
                 */
                
                destinationFilename= [tmpGlobalObj.preferenceController resourceSavedPath:newResource];
                if(destinationFilename){
                     newResource.manualDownloadFilePath = destinationFilename;
                    [download setDestination:destinationFilename allowOverwrite:NO];
                   
                    [tmpGlobalObj  addResource:newResource];
                    
                }
            }
        }
    }
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
    @autoreleasepool {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        NSArray *unfinishedArray = [NSArray arrayWithArray:tmpObj.unfinishedResources];
        
        for(URLResource *i in unfinishedArray){
            if(i.parent == download && [download.request.URL.absoluteString isEqualToString:i.url.absoluteString] == YES){
                i.finishedLength += length;
                break;
            }
        }
    }
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    @autoreleasepool {
        
        
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        NSArray *unfinishedArray = [NSArray arrayWithArray:tmpObj.unfinishedResources];
        
        for(URLResource *i in unfinishedArray){
            if((i.parent == download)&& [download.request.URL.absoluteString isEqualToString:i.url.absoluteString] == YES){
                i.isError = YES;
                i.isFinished = YES;
                [tmpObj abortResource:i];
                break;
            }
        }
    }
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    @autoreleasepool {
        GlobalObject *tmpObj = [GlobalObject sharedObj];
        NSArray *unfinishedArray = [NSArray arrayWithArray:tmpObj.unfinishedResources];
        
        for(URLResource *i in unfinishedArray ){
            if((i.parent == download)&& [download.request.URL.absoluteString isEqualToString:i.url.absoluteString] == YES){
                i.isError = NO;
                i.isFinished = YES;
                [tmpObj finishResource:i];
                if(i.manualDownloadFilePath){
                    if([[NSFileManager defaultManager] fileExistsAtPath: i.manualDownloadFilePath]==YES){
                        NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], NSFileModificationDate,[NSDate date], NSFileCreationDate ,NULL];
                        
                        [[NSFileManager defaultManager] setAttributes: attr ofItemAtPath: i.manualDownloadFilePath error: NULL];
                    }
                }
                break;
            }
        }
    }
}

@end


