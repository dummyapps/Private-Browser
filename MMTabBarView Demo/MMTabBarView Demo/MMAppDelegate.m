//
//  MMAppDelegate.m
//  MMTabBarView Demo
//
//  Created by Michael Monscheuer on 9/19/12.
//  Copyright (c) 2012 Michael Monscheuer. All rights reserved.
//

#import "MMAppDelegate.h"

#import "WebBrowserWindowController.h"
#import "GlobalObject.h"
#import "FileManagerProxy.h"



@implementation MMAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)pNotification {
    @autoreleasepool {
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
        
      
        NSDate *allTypeRegTime = [[NSUserDefaults standardUserDefaults]objectForKey:MY_TIMESTAMP_KEY];
        if(allTypeRegTime){
            NSDate *currDate = [NSDate date];
            NSTimeInterval timeInterval = [currDate timeIntervalSinceDate:allTypeRegTime];
            if(timeInterval >= (60*60*24*5))
                [[NSUserDefaults standardUserDefaults]setBool:YES forKey:IMAGE_ALL_TYPE_KEY];
        }else{
            [[NSUserDefaults standardUserDefaults]setObject:[NSDate date] forKey:MY_TIMESTAMP_KEY];
        }
        
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0)
            return ;
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
        
        //#define OLD_SAVE_TO_FOLDER @"EasyWebBrowser"
        //#define SAVE_TO_FOLDER @"PrivateBrowser"
        NSString *oldSaveHomePath1 = [homepath stringByAppendingPathComponent:@"EasyWebBrowser"];
        NSString *oldSaveHomePath2 = [homepath stringByAppendingPathComponent:@"PrivateBrowser"];
        
        if([[FileManagerProxy sharedInstance] isUrlExist:[NSURL fileURLWithPath:savedHomePath]] == NO){
            if([[FileManagerProxy sharedInstance] isUrlExist:[NSURL fileURLWithPath:oldSaveHomePath2]] == YES){
                [[FileManagerProxy sharedInstance] moveURL:[NSURL fileURLWithPath:oldSaveHomePath2] toURL:[NSURL fileURLWithPath:savedHomePath] removeUpper:NO];
            }
        }
        
        if([[FileManagerProxy sharedInstance] isUrlExist:[NSURL fileURLWithPath:savedHomePath]] == NO){
            if([[FileManagerProxy sharedInstance] isUrlExist:[NSURL fileURLWithPath:oldSaveHomePath1]] == YES){
                [[FileManagerProxy sharedInstance] moveURL:[NSURL fileURLWithPath:oldSaveHomePath1] toURL:[NSURL fileURLWithPath:savedHomePath] removeUpper:NO];
            }
        }
        
        WebHistory *newHistory = [[WebHistory alloc]init];
        [WebHistory setOptionalSharedHistory:newHistory];
        NSURLCache *newCache = [[NSURLCache alloc]init];
        [NSURLCache setSharedURLCache:newCache];
        
        
        [self newWindow:self];
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        BOOL hasPasword = [[NSUserDefaults standardUserDefaults] boolForKey: PASSWORD_ENABLE_KEY];
        if(hasPasword == YES){
            [tmpGlobal.windowController.authTabView selectTabViewItemAtIndex:1];
        }else{
            [tmpGlobal.windowController.authTabView selectTabViewItemAtIndex:0];
        }
      //  [GlobalObject showAlert:RESTRICT_URL_STRING];
       
    }
}
- (IBAction)newWindow:(id)sender {
        // create window controller
	WebBrowserWindowController *newWindowController = [[WebBrowserWindowController alloc] initWithWindowNibName:@"MainWindow"];
        // load window (as we need the nib file to be loaded before we can proceed
    [newWindowController loadWindow];
        // add the default tabs
	[newWindowController addDefaultTabs];
        // finally show the window
	[newWindowController showWindow:self];
  //  self.mainwindowController = newWindowController;
    self.mainWindow = newWindowController.window;
}
/*
- (IBAction)newTab:(id)sender {
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    [tmpGlobal.windowController addDefaultTabs];
}

- (IBAction)closeTab:(id)sender {
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    [tmpGlobal.windowController closeTab:nil];
}
 


- (IBAction)showPreference:(id)sender {
}
*/
- (IBAction)productHelp:(id)sender {
    @autoreleasepool {
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
       // [tmpGlobal.windowController addNewTabWithURL:PRODUCT_WEBBROWSER_URL_STRING];
       
    [tmpGlobal.windowController addNewTabWithURL: @"https://www.jianshu.com/p/0a4ae3fd7018"];
    }
}


-(IBAction)checkProduct:(id)sender{
    NSURL *tmpURL = [NSURL URLWithString:@"https://apps.apple.com/cn/developer/dummy-apps/id525194985"];
    
    [[NSWorkspace sharedWorkspace] openURL:tmpURL];
}

- (IBAction)checkAllAPPs:(id)sender {
    @autoreleasepool {
        
    
        
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.windowController addNewTabWithURL:PRODUCT_ALL_URL_STRING];
    }
}
- (IBAction)checkPDFAlbum:(id)sender {
    @autoreleasepool {
        
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.windowController addNewTabWithURL:PRODUCT_IMAGESPDF_URL_STRING];
    }
}
- (IBAction)checkImageResizer:(id)sender {
    @autoreleasepool {
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.windowController addNewTabWithURL:PRODUCT_IMAGESRESIZER_URL_STRING];
    }
}
- (IBAction)checkDuplicateCleaner:(id)sender {
    @autoreleasepool {
        
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.windowController addNewTabWithURL:PRODUCT_DUPLICATECLEANER_URL_STRING];
    }
}
- (IBAction)checkIsee:(id)sender {
    @autoreleasepool {
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.windowController addNewTabWithURL:PRODUCT_ISEE_URL_STRING];
    }
}

- (IBAction)openLocalFile:(id)sender{
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    
    [tmpGlobal.windowController openLocalFile:sender];
}
- (IBAction)ShareWithFriends:(id)sender {
    /*
    NSString *mailtoAddress = [[NSString stringWithFormat:@"mailto:%@?Subject=%@&body=%@",@"myfriends@gmail.com",PRODUCT_EMAIL_TITLE_STRING,PRODUCT_EMAIL_BODY_STRING] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:mailtoAddress]];
    */
    @autoreleasepool {
        
    
    NSString *encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@", [PRODUCT_EMAIL_TITLE_STRING stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedBody = [NSString stringWithFormat:@"BODY=%@", [PRODUCT_EMAIL_BODY_STRING stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedTo = [@"MyFriends@gmail.com" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, encodedBody];
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
    }
}

- (IBAction)clearHistory:(id)sender
{
    @autoreleasepool {
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        tmpGlobal.resourceHash =  [NSMutableDictionary dictionary];
        [[WebHistory optionalSharedHistory] removeAllItems];
        [[NSURLCache sharedURLCache]removeAllCachedResponses];
    }
}


-(IBAction)lockWindow:(id)sender{
     GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    [tmpGlobal.windowController lockWindow];
}

-(IBAction)restoreWindow:(id)sender{
    @autoreleasepool {
        [self.mainWindow makeKeyAndOrderFront:self];
        
    }
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag{
    if (!flag){
        //主窗口显示
        
        [NSApp activateIgnoringOtherApps:NO];
        [self.mainWindow makeKeyAndOrderFront:self];
    }
    return YES;
}


-(IBAction)showBookMarkFile:(id)sender{
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    NSString *plistpath = [tmpGlobal.bookmarkController bookmarkFilePath];
    if(plistpath){
       [ [NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:plistpath]]];
    }
}

/*menu handle*/
@end


//for ssl url access
@implementation NSURLRequest(DataController)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return YES;
}
@end
