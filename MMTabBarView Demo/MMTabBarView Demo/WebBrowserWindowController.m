//
//  WindowController.m
//  MMTabBarView Demo
//
//  Created by John Pannell on 4/6/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import <EasyWebBrowser/MMTabBarView.h>
#import <EasyWebBrowser/MMTabStyle.h>
#import <Quartz/Quartz.h>

#import "WebBrowserWindowController.h"
#import "TabitemIdentity.h"
#import "GlobalObject.h"
#import "PreferenceViewController.h"
#import "FileManagerProxy.h"
 static dispatch_queue_t SaveTaskQueue = NULL;

@interface WebBrowserWindowController (PRIVATE)
- (void)configureTabBarInitially;
@end

@interface WebBrowserWindowController(ConfigActions)

// tab bar config
- (IBAction)configStyle:(id)sender;
- (IBAction)configOnlyShowCloseOnHover:(id)sender;
- (IBAction)configCanCloseOnlyTab:(id)sender;
- (IBAction)configDisableTabClose:(id)sender;
- (IBAction)configAllowBackgroundClosing:(id)sender;
- (IBAction)configHideForSingleTab:(id)sender;
- (IBAction)configAddTabButton:(id)sender;
- (IBAction)configTabMinWidth:(id)sender;
- (IBAction)configTabMaxWidth:(id)sender;
- (IBAction)configTabOptimumWidth:(id)sender;
- (IBAction)configTabSizeToFit:(id)sender;
- (IBAction)configTearOffStyle:(id)sender;
- (IBAction)configUseOverflowMenu:(id)sender;
- (IBAction)configAutomaticallyAnimates:(id)sender;
- (IBAction)configAllowsScrubbing:(id)sender;
@end

static bool isSaveAs = NO;
@implementation NSSplitView (Animation)

/**
 * Animate the split view panels such that the view at viewIndex has the width or height dimension.
 * Note that animating a panel to zero width or height will cause it to 'disappear', and such a panel will not animate again. Animating to no less than 1 pixel wide or high is sufficient to make a panel appear hidden.
 * @param viewIndex The index of the view to animate to dimension wide or high
 * @param dimension The width or height, depending on whether the NSSplitView is horizontally or vertically split, to animate to
 */
- (void) animateView:(int)viewIndex toDimension:(CGFloat)dimension {
    @autoreleasepool {
        NSView *targetView = [[self subviews] objectAtIndex:viewIndex];
        NSRect endFrame = [targetView frame];
        
        if (![self isVertical]) {
            endFrame.size.height = dimension;
        } else {
            endFrame.size.width = dimension;
        }
        
        NSDictionary *windowResize;
        
        windowResize = [NSDictionary dictionaryWithObjectsAndKeys: targetView, NSViewAnimationTargetKey,
                        [NSValue valueWithRect: endFrame], NSViewAnimationEndFrameKey, nil];
        
        NSViewAnimation *animation = [[NSViewAnimation alloc]
                                      initWithViewAnimations:[NSArray arrayWithObject:windowResize]];
        
        
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation setDuration:0.5];
        [animation startAnimation];
    }
}

@end

@implementation WebBrowserWindowController
-(void)resetFirstResponder{
    
}


-(BOOL)isAuthencating{
    NSTabViewItem *item =  [self.authTabView selectedTabViewItem];
    NSUInteger idx = [self.authTabView indexOfTabViewItem:item];
    if(idx >0){
        return  YES;
    }
    
    return NO;
}

- (IBAction)passwordEntered:(id)sender {
    if([[NSUserDefaults standardUserDefaults] boolForKey:PASSWORD_ENABLE_KEY] == NO){
        [passwordField setStringValue:@""];
        [self.authTabView selectTabViewItemAtIndex:0];
        return;
    }
    
    NSString *inputPwd = [passwordField stringValue];
    NSString *curPwd =[[NSUserDefaults standardUserDefaults] stringForKey:PASSWORD_VALUE_KEY];
    if(curPwd){
        if([curPwd length] == 0){
            [passwordField setStringValue:@""];
            [self.authTabView selectTabViewItemAtIndex:0];
            return;
        }
        
        // NSString *md5TMP = [[FileManagerProxy sharedInstance]MD5String:inputPwd];
        if([inputPwd isEqualToString:curPwd] == NO){
            [passwordField setStringValue:@""];
            return;
        }
        
    }else{
        [passwordField setStringValue:@""];
        [self.authTabView selectTabViewItemAtIndex:0];
        return;
    }
    
    [passwordField setStringValue:@""];
    [self.authTabView selectTabViewItemAtIndex:0];
}


- (void)lockWindow {
    if([self isAuthencating] == YES) return;
    
    [self.authTabView selectTabViewItemAtIndex:1];
}


-(IBAction)openDefaultDownloadFolder:(id)sender{
    if([self isAuthencating] == YES) return;
    @autoreleasepool {
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        
        
        WebBrowserWindowController *windowController = [[GlobalObject sharedObj] windowController];
        NSTabViewItem *currentItem = [[windowController getTabView] selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        MyWebView *currWebview =(MyWebView *) currID.webview;
        if(currWebview == nil)
            return;
        
        NSURL *currURL = [NSURL URLWithString:currWebview.mainFrameURL];
        [tmpGlobal.preferenceController openFileNodeInFinder:[currURL host] ];
    }
}

-(IBAction)zoomOutWebView:(id)sender{
    NSTabViewItem *currentItem = [tabView selectedTabViewItem];
    TabitemIdentity *currID = currentItem.identifier;
    MyWebView *currWebview =(MyWebView *) currID.webview;
    if(currWebview == nil)
        return;
     NSScrollView *tmpScrollview=  [[[[currWebview mainFrame] frameView] documentView] enclosingScrollView] ;
    NSClipView *tmpClipView = tmpScrollview.contentView;
    [currWebview zoomOut];
}

-(IBAction)zoomInWebView:(id)sender{
    NSTabViewItem *currentItem = [tabView selectedTabViewItem];
    TabitemIdentity *currID = currentItem.identifier;
    MyWebView *currWebview = (MyWebView *)currID.webview;
    if(currWebview == nil)
        return;
    
    [currWebview zoomIn];
}
-(IBAction)printImage:(id)sender{
    //  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:GLOBAL_IS_PROCESSING_KEY];
        NSView *webFrameViewDocView = [[[currWebview mainFrame] frameView] documentView];
        NSRect cacheRect = [webFrameViewDocView bounds];
        
        NSBitmapImageRep *bitmapRep = [webFrameViewDocView bitmapImageRepForCachingDisplayInRect:cacheRect];
        if(bitmapRep == nil)
        {
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
            return;
        }
        [webFrameViewDocView cacheDisplayInRect:cacheRect toBitmapImageRep:bitmapRep];
        /*
         NSSize imgSize = cacheRect.size;
         
         if (imgSize.height > imgSize.width)
         {
         imgSize.height = imgSize.width;
         }*/
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0){
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
            
            return;
        }
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
      //  savedHomePath = [savedHomePath stringByAppendingPathComponent:@"WebPageToImage"];
        NSURL *currURL = [NSURL URLWithString:currWebview.mainFrameURL];
        if([[currURL host] length]){
            savedHomePath = [savedHomePath stringByAppendingPathComponent:[currURL host]];
        }
        
        
        NSString *fileName = [currWebview mainFrameTitle];
        if([fileName length] == 0)
            fileName = currURL.host;
        
        fileName = [[GlobalObject sharedObj] goodFileName:fileName];
        NSString *targetPath = [savedHomePath  stringByAppendingPathComponent:fileName];
        targetPath = [targetPath stringByAppendingPathExtension:@"jpg"];
        
        
        
        //[[FileManagerProxy sharedInstance] createDirectoryAt:[NSURL URLWithString: savedHomePath]];
        [[NSFileManager defaultManager] createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
        
        bool writeFileRet = NO;
        NSUInteger tmpNum = 1;
        NSString * testTargetPath = [NSString stringWithString:targetPath];
        while ([[NSFileManager defaultManager] fileExistsAtPath:testTargetPath] == YES){
            NSString *pathFirstComponent = [targetPath stringByDeletingPathExtension];
            pathFirstComponent = [pathFirstComponent stringByAppendingFormat:@"_%ld",tmpNum];
            testTargetPath = [pathFirstComponent stringByAppendingPathExtension:[targetPath pathExtension]];
            tmpNum ++;
        }
        
        //  [[bitmapRep TIFFRepresentation]writeToFile:testTargetPath atomically:YES];
        CGFloat imageCompression = 0.5; //between 0 and 1; 1 is maximum quality, 0 is maximum compression
        
        // set up the options for creating a JPEG
        NSDictionary* jpegOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithDouble:imageCompression], NSImageCompressionFactor,
                                     [NSNumber numberWithBool:NO], NSImageProgressive,
                                     nil];
        
        NSData *tmpData = [bitmapRep representationUsingType:NSJPEGFileType properties:jpegOptions];
        if(tmpData){
            if(isSaveAs == YES){
                testTargetPath = [self doSaveAs:testTargetPath];
            }
            if(testTargetPath)
                writeFileRet =  [tmpData writeToFile:testTargetPath atomically:YES];
        }
        
        if(writeFileRet == NO && isSaveAs == NO){
            NSString *tmpFileExt = [testTargetPath pathExtension];
            NSString *tmpLastFileName = [[testTargetPath stringByDeletingPathExtension] lastPathComponent] ;
            NSString *tmpLastFileFolder = [testTargetPath stringByDeletingLastPathComponent];
            
            tmpLastFileName =  [[tmpLastFileName componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:FILENAME_REPLACE_STRING];
            
            if([tmpLastFileName length] == 0){
                tmpLastFileName  = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
            }
            
            tmpLastFileName  =[tmpLastFileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            tmpLastFileFolder = [tmpLastFileFolder stringByAppendingPathComponent:[tmpLastFileName stringByAppendingPathExtension:tmpFileExt]];
            
            if(tmpLastFileFolder)
                writeFileRet = [tmpData writeToFile:tmpLastFileFolder atomically:YES];
        }
        
        if(writeFileRet == YES)
            [[GlobalObject sharedObj]playSlideshowSounds];
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
    }
    //   });
}

- (NSString *)doSaveAs:(NSString *)oldPath{
    if(oldPath == nil)
        return nil;
    
    NSSavePanel *tvarNSSavePanelObj	= [NSSavePanel savePanel];
    if(tvarNSSavePanelObj == nil)
        return nil;
    
    NSURL *fullURL = [NSURL fileURLWithPath:oldPath];
    NSURL *folder = [fullURL URLByDeletingLastPathComponent];
    NSString *fileName = [fullURL lastPathComponent];
    
    [tvarNSSavePanelObj setExtensionHidden:YES];
    [tvarNSSavePanelObj setDirectoryURL:folder];
    [tvarNSSavePanelObj setNameFieldStringValue:fileName];
    
    NSInteger tvarInt	= [tvarNSSavePanelObj runModal];
    if(tvarInt == NSOKButton){
     	
    } else if(tvarInt == NSCancelButton) {
     	return nil;
    } else {
     	return nil;
    } // end if
    
    NSURL * tvarDirectory = [tvarNSSavePanelObj directoryURL];
    if(tvarDirectory == nil)
        return nil;
    
    if([[FileManagerProxy sharedInstance] isUrlExist:tvarDirectory] == NO){
        if([[NSFileManager defaultManager] createDirectoryAtPath:tvarDirectory.path withIntermediateDirectories:YES attributes:nil error:NULL] != YES){
            return nil;
        }
    }
    
    NSString * tvarFilename = [[tvarNSSavePanelObj URL] path];
    if([tvarFilename length] == 0)
        return nil;
    
    return tvarFilename;
    
} // end doSaveAs

-(IBAction)printAllToImage:(id)sender{
    @autoreleasepool {
        NSTabViewItem *savedCurrentItem = [tabView selectedTabViewItem];
        NSArray *allTabviewItems = [tabView tabViewItems];
        for(NSTabViewItem *i in allTabviewItems){
            [tabView selectTabViewItem:i];
            [self printImage:nil];
        }
        
        [tabView selectTabViewItem:savedCurrentItem];
    }
}

-(IBAction)printWebPage:(id)sender{
    NSUInteger saveType = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULT_WEBPAGE_SAVE_TYPE_KEY];
    if(saveType == DEFAULT_WEBPAGE_SAVE_TYPE_PDF){
        [self printPDF:nil];
    }else if(saveType == DEFAULT_WEBPAGE_SAVE_TYPE_JPG){
        [self printImage:nil];
    }else{
        [self printWebAchieve:nil];
    }
}

-(IBAction)printWebPageAs:(id)sender{
    isSaveAs = YES;
    NSUInteger saveType = [[NSUserDefaults standardUserDefaults] integerForKey:DEFAULT_WEBPAGE_SAVE_TYPE_KEY];
    if(saveType == DEFAULT_WEBPAGE_SAVE_TYPE_PDF){
        [self printPDF:nil];
    }else if(saveType == DEFAULT_WEBPAGE_SAVE_TYPE_JPG){
        [self printImage:nil];
    }else{
        [self printWebAchieve:nil];
    }
    isSaveAs = NO;
}

-(IBAction)printPDF:(id)sender{
    //  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
        //get a pointer to the document view so that we render the entire web page, not just the visible portion.NSView *docView = [[[webview mainFrame] frameView] documentView];
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        
        
      
        
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:GLOBAL_IS_PROCESSING_KEY];
        WebPreferences *preferences = [[WebPreferences alloc] initWithIdentifier:@"testing"] ;
        [preferences setShouldPrintBackgrounds:YES];
        [currWebview setPreferences:preferences];
        // [currWebview lockFocus];
        //create the pdf
        //NSData *data = [currWebview dataWithPDFInsideRect:[currWebview bounds]];
        
        //   NSData *pdfData = [[[[currWebview mainFrame] frameView] documentView] dataWithPDFInsideRect:[[[currWebview mainFrame] frameView] documentView].frame];
        NSData *pdfData = [[[[currWebview mainFrame] frameView] documentView] dataWithPDFInsideRect:[[[currWebview mainFrame] frameView] documentView].bounds];
        //   NSData *pdfData = [[[[currWebview mainFrame] frameView] documentView] dataWithPDFInsideRect:NSMakeRect(0, 0, 500, 500)];
        // NSData *pdfData = [currWebview  dataWithPDFInsideRect:currWebview.frame];
        //[currWebview unlockFocus];
        
        PDFDocument *document = [[PDFDocument alloc] initWithData:pdfData];
        if(document == nil){
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
            return;
        }
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0){
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
            return;
        }
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
       // savedHomePath = [savedHomePath stringByAppendingPathComponent:@"WebPageToPDF"];
        NSURL *currURL = [NSURL URLWithString:currWebview.mainFrameURL];
        if([[currURL host] length]){
            savedHomePath = [savedHomePath stringByAppendingPathComponent:[currURL host]];
        }
        
        
        NSString *fileName = [currWebview mainFrameTitle];
        if([fileName length] == 0)
            fileName = currURL.host;
        
        fileName = [[GlobalObject sharedObj] goodFileName:fileName];
        
        NSString *targetPath = [savedHomePath  stringByAppendingPathComponent:fileName];
        targetPath = [targetPath stringByAppendingPathExtension:@"pdf"];
        
        
        [[NSFileManager defaultManager] createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
        
        NSUInteger tmpNum = 1;
        NSString * testTargetPath = [NSString stringWithString:targetPath];
        while ([[NSFileManager defaultManager] fileExistsAtPath:testTargetPath] == YES){
            NSString *pathFirstComponent = [targetPath stringByDeletingPathExtension];
            pathFirstComponent = [pathFirstComponent stringByAppendingFormat:@"_%ld",tmpNum];
            testTargetPath = [pathFirstComponent stringByAppendingPathExtension:[targetPath pathExtension]];
            tmpNum ++;
        }
        /*
         {
         //this will point to our NSPrintInfo object
         NSPrintInfo *printInfo;//this will point to the default printer info object
         NSPrintInfo *sharedInfo;//thi will point to our settings for the NSPrintInfo object
         NSMutableDictionary *printInfoDict;//this will point to the settings for the default NSPrintInfo object
         NSMutableDictionary *sharedDict;
         
         sharedInfo = [NSPrintInfo sharedPrintInfo];
         sharedDict = [sharedInfo dictionary];
         printInfoDict = [NSMutableDictionary dictionaryWithDictionary:sharedDict];
         
         //below we set the type of printing job to a save job.
         [printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
         
         //set the path to the file you want to print to
         [printInfoDict setObject:testTargetPath forKey:NSPrintSavePath];
         
         //create our very own NSPrintInfo object with the settings we specified in printInfoDict
         printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict] ;
         
         //create the NSPrintOperation object, specifying docView from the previous post as the NSView to print from.
         NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:currWebview printInfo:printInfo];
         
         //we don't want to show the printing panel
         //[printOp setShowprintPanels:NO];
         [printOp setShowsPrintPanel:NO];
         [printOp setShowsProgressPanel:NO];
         
         //run the print operation
         [printOp runOperation];
         }*/
        
        // [document writeToFile:testTargetPath];
        BOOL writeFileRet = NO;
        NSDictionary *options = nil;
        bool isPasswordEnabled = [[NSUserDefaults standardUserDefaults]boolForKey:PDF_PASSWORD_ENABLE_KEY];
        if(isPasswordEnabled == YES){
            NSString *passwordStr = [[NSUserDefaults standardUserDefaults] stringForKey:PDF_PASSWORD_VALUE_KEY];
            if([passwordStr length]){
                bool isAllowCopy = [[NSUserDefaults standardUserDefaults] boolForKey:PDF_ALLOW_COPY_KEY];
                bool isAllowPrint = [[NSUserDefaults standardUserDefaults] boolForKey:PDF_ALLOW_PRINT_KEY];
                options = [NSDictionary dictionaryWithObjectsAndKeys: passwordStr, kCGPDFContextOwnerPassword,passwordStr,kCGPDFContextUserPassword,[NSNumber numberWithBool:isAllowCopy],kCGPDFContextAllowsCopying,[NSNumber numberWithBool:isAllowPrint],kCGPDFContextAllowsPrinting, nil];
            }
        }
        
        
        if(isSaveAs == YES){
            testTargetPath = [self doSaveAs:testTargetPath];
        }
        
        if(testTargetPath){
            writeFileRet =  [document writeToFile: testTargetPath withOptions: options];
            
#if 0
            //分页打印
            {
                NSMutableDictionary *dict = [[NSPrintInfo sharedPrintInfo] dictionary];
                [dict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
                [dict setObject: [NSURL fileURLWithPath:testTargetPath] forKey:NSPrintJobSavingURL];
                NSPrintInfo *pi = [[NSPrintInfo alloc] initWithDictionary:dict];
                [pi setHorizontalPagination:NSFitPagination];
                [pi setVerticalPagination:NSFitPagination];
                
                NSPrintOperation *op = [NSPrintOperation printOperationWithView:[[[currWebview mainFrame] frameView] documentView] printInfo:pi];
                //  [pi release];
                [op setShowsPrintPanel:NO];
                [op setShowsProgressPanel:NO];
                
                if ([op runOperation] ){
                    PDFDocument *doc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath: testTargetPath]];
                    NSString *dplitdocPath = [testTargetPath stringByDeletingPathExtension];
                    dplitdocPath  = [NSString stringWithFormat:@"%@.bak", dplitdocPath];
                    dplitdocPath = [dplitdocPath stringByAppendingPathExtension:@"pdf"];
                    [doc writeToFile:dplitdocPath];
                    // do with doc what you want, remove file, etc.
                }
            }
#endif
            
        }
        
        
        if(writeFileRet == NO && isSaveAs == NO){
            NSString *tmpFileExt = [testTargetPath pathExtension];
            NSString *tmpLastFileName = [[testTargetPath stringByDeletingPathExtension] lastPathComponent] ;
            NSString *tmpLastFileFolder = [testTargetPath stringByDeletingLastPathComponent];
            
            tmpLastFileName =  [[tmpLastFileName componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:FILENAME_REPLACE_STRING];
            
            if([tmpLastFileName length] == 0){
                tmpLastFileName  = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
            }
            
            tmpLastFileName  =[tmpLastFileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            tmpLastFileFolder = [tmpLastFileFolder stringByAppendingPathComponent:[tmpLastFileName stringByAppendingPathExtension:tmpFileExt]];
            writeFileRet = [document writeToFile:  tmpLastFileFolder   ] ;
        }
        
        if(writeFileRet == YES)
            [[GlobalObject sharedObj]playSlideshowSounds];
        
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
        
    }
    //  });
}

-(IBAction)printAllTOPDF:(id)sender{
    @autoreleasepool {
         NSTabViewItem *savedCurrentItem = [tabView selectedTabViewItem];
        NSArray *allTabviewItems = [tabView tabViewItems];
        for(NSTabViewItem *i in allTabviewItems){
            [tabView selectTabViewItem:i];
            [self printPDF:nil];
        }
        
        [tabView selectTabViewItem:savedCurrentItem];
    }
}
-(IBAction)printWebAchieve:(id)sender{
    //  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
        //get a pointer to the document view so that we render the entire web page, not just the visible portion.NSView *docView = [[[webview mainFrame] frameView] documentView];
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:GLOBAL_IS_PROCESSING_KEY];
        NSData *webContent =  [[[[currWebview mainFrame]dataSource] webArchive]data] ;
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0){
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
            return;
        }
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
      //  savedHomePath = [savedHomePath stringByAppendingPathComponent:@"WebPageToArchive"];
        NSURL *currURL = [NSURL URLWithString:currWebview.mainFrameURL];
        if([[currURL host] length]){
            savedHomePath = [savedHomePath stringByAppendingPathComponent:[currURL host]];
        }
        
        
        NSString *fileName = [currWebview mainFrameTitle];
        if([fileName length] == 0)
            fileName = [currURL host];
        
        fileName = [[GlobalObject sharedObj] goodFileName:fileName];
        
        NSString *targetPath = [savedHomePath  stringByAppendingPathComponent:fileName];
        targetPath = [targetPath stringByAppendingPathExtension:@"webarchive"];
        
        
        [[NSFileManager defaultManager] createDirectoryAtPath:[targetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
        
        bool writeFileRet = NO;
        
        NSUInteger tmpNum = 1;
        NSString * testTargetPath = [NSString stringWithString:targetPath];
        while ([[NSFileManager defaultManager] fileExistsAtPath:testTargetPath] == YES){
            NSString *pathFirstComponent = [targetPath stringByDeletingPathExtension];
            pathFirstComponent = [pathFirstComponent stringByAppendingFormat:@"_%ld",tmpNum];
            testTargetPath = [pathFirstComponent stringByAppendingPathExtension:[targetPath pathExtension]];
            tmpNum ++;
        }
        
        if(isSaveAs == YES){
            testTargetPath = [self doSaveAs:testTargetPath];
        }
        
        if(testTargetPath)
            writeFileRet = [webContent writeToFile:testTargetPath atomically:YES] ;
        
        
        if(writeFileRet == NO && isSaveAs == NO){
            NSString *tmpFileExt = [testTargetPath pathExtension];
            NSString *tmpLastFileName = [[testTargetPath stringByDeletingPathExtension] lastPathComponent] ;
            NSString *tmpLastFileFolder = [testTargetPath stringByDeletingLastPathComponent];
            
            tmpLastFileName =  [[tmpLastFileName componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:FILENAME_REPLACE_STRING];
            
            if([tmpLastFileName length] == 0){
                tmpLastFileName  = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
            }
            
            tmpLastFileName  =[tmpLastFileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            tmpLastFileFolder = [tmpLastFileFolder stringByAppendingPathComponent:[tmpLastFileName stringByAppendingPathExtension:tmpFileExt]];
            writeFileRet = [webContent writeToFile:tmpLastFileFolder atomically:YES] ;
        }
        
        if(writeFileRet == YES)
            [[GlobalObject sharedObj]playSlideshowSounds];
        
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
        
    }
    //  });
}
-(IBAction)printAllTOArchive:(id)sender{
    @autoreleasepool {
        NSTabViewItem *savedCurrentItem = [tabView selectedTabViewItem];
        NSArray *allTabviewItems = [tabView tabViewItems];
        for(NSTabViewItem *i in allTabviewItems){
            [tabView selectTabViewItem:i];
            [self printWebAchieve:nil];
        }
        
        [tabView selectTabViewItem:savedCurrentItem];
    }
}

-(IBAction)saveAllBookmark:(id)sender{
    @autoreleasepool {
        NSArray *allTabviewItems = [tabView tabViewItems];
        for(NSTabViewItem *i in allTabviewItems){
            TabitemIdentity *currID = i.identifier;
            WebView *currWebview = currID.webview;
            
            GlobalObject *tmpGlobal = [GlobalObject sharedObj];
            [tmpGlobal.bookmarkController addBookmarkWithURL:[currWebview mainFrameURL] Title:[currWebview mainFrameTitle] Icon:[currWebview mainFrameIcon]];
        }

    }
}

-(IBAction)addAsDefaultPage:(id)sender{
    @autoreleasepool {
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        if([currWebview.mainFrameURL length]){
            [[NSUserDefaults standardUserDefaults] setObject:currWebview.mainFrameURL forKey:DEFAULT_URL_KEY];
        }
    }
}

- (void)awakeFromNib {
    @autoreleasepool {
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        tmpGlobal.preferenceController = self.preferenceViewController;
        
        tmpGlobal.windowController = self;
        tmpGlobal.taskTableview = taskTableView;
        
        [self configureTabBarInitially];
        if([[NSUserDefaults standardUserDefaults] boolForKey:START_DOWNLOAD_KEY] == YES){
            self.startDownloadButton.selectedSegment = 0;
        }else
            self.startDownloadButton.selectedSegment = 1;
    

        /*
         // toolbar
         NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"DemoToolbar"];
         
         [toolbar setDelegate:self];
         [toolbar setAllowsUserCustomization:YES];
         [toolbar setAutosavesConfiguration:YES];
         [toolbar setShowsBaselineSeparator:NO];
         
         [[self window] setToolbar:toolbar];
         */
        [tabBar addObserver:self forKeyPath:@"orientation" options:NSKeyValueObservingOptionNew context:NULL];
        
        // remove any tabs present in the nib
        
        for (NSTabViewItem *item in [tabView tabViewItems]) {
            [tabView removeTabViewItem:item];
        }
        
        [self toggleDownload:nil];
        [self toggleBookMark:nil];
        
        // open drawer
        //[drawer toggle:self];
        // [taskDrawer close];
        
        if(SaveTaskQueue == NULL){
            SaveTaskQueue = dispatch_queue_create("com.dummyapp.easyWebBrowser.savetask", NULL);
        }
    }
}

- (void)addNewTabWithURL:(NSString *)url {
    @autoreleasepool {
        
        
        GlobalObject *tmpGolbalObj = [GlobalObject sharedObj];
        if(url == nil){
            url = [tmpGolbalObj.preferenceController defaultURL];
        }
        TabitemIdentity *newId = [[TabitemIdentity alloc] init];
        if(url == nil)
            [newId setTitle:INVALID_TITLE];
        newId.requestURL = url;
        
        if(url)
            newId.isProcessing = YES;
        
        [tmpGolbalObj.tabItemIdentities addObject:newId];
        
        
        NSTabViewItem *newTabItem = [[NSTabViewItem alloc] initWithIdentifier:newId];
        [[newTabItem view] setAutoresizesSubviews:YES];
        WebView *tmpWebView = [WebViewController createNewWebViewWithURL:url];
        [[newTabItem view] addSubview:tmpWebView];
        newId.webview = tmpWebView;
        [tabView addTabViewItem:newTabItem];
        
        BOOL ret = [[NSUserDefaults standardUserDefaults] boolForKey:ALWAYS_SELECT_NEW_WEBVIEW];
        if(ret == YES)
            [tabView selectTabViewItem:newTabItem];
        
        [self updateCurrentWebviewMainFrame];
    }
}

- (id)addNewTabWithRequest:(NSURLRequest *)request {
    WebView *tmpWebView = nil;
    @autoreleasepool {
        
    
	TabitemIdentity *newId = [[TabitemIdentity alloc] init];
    if(request.URL == nil)
        [newId setTitle:INVALID_TITLE];
    newId.requestURL = [request.URL absoluteString];
    
    if(request.URL)
        newId.isProcessing = YES;
    GlobalObject *tmpGolbalObj = [GlobalObject sharedObj];
    [tmpGolbalObj.tabItemIdentities addObject:newId];
    
    
	NSTabViewItem *newItem = [[NSTabViewItem alloc] initWithIdentifier:newId];
    [[newItem view] setAutoresizesSubviews:YES];
     tmpWebView = [WebViewController createNewWebViewWithRequest:request];
    [[newItem view] addSubview:tmpWebView];
    newId.webview = tmpWebView;
	[tabView addTabViewItem:newItem];
    BOOL ret = [[NSUserDefaults standardUserDefaults] boolForKey:ALWAYS_SELECT_NEW_WEBVIEW];
    if(ret == YES)
        [tabView selectTabViewItem:newItem];
    
    [self updateCurrentWebviewMainFrame];
    }
    return tmpWebView;
}

- (IBAction)urlEntered:(id)sender {
    @autoreleasepool {
        
        
        NSString *enteredURLString = [self.urlTextField.stringValue  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if([enteredURLString length] == 0)
            return;
        
        NSURL *newURL =[NSURL URLWithString:enteredURLString];
        if(newURL == nil)
            return;
        
        if([newURL.scheme length] == 0){
            NSString *newString =[ @"http://" stringByAppendingString:enteredURLString];
            newURL = [NSURL URLWithString:newString];
            
        }
        
        /*
         if ([[newURL absoluteString] isEqualToString:[currWebview mainFrameURL]] == YES) {
         return;
         }
         */
        
        
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        if(currentItem){
            TabitemIdentity *currID = currentItem.identifier;
            WebView *currWebview = currID.webview;
            [[currWebview mainFrame] loadRequest:[NSURLRequest requestWithURL:newURL]];
        }else{
            [self addNewTabWithURL:[newURL absoluteString]];
        }
        [self updateCurrentWebviewMainFrame];
    }
}

- (IBAction)pageForwardAndBack:(id)sender {
    @autoreleasepool {
        
    NSUInteger segIndex = [(NSSegmentedControl *)sender selectedSegment];
    if(segIndex == 0){
        [self pageBack:sender];
    }else{
        [self pageForward:sender];
    }
    }
}

-(IBAction)pageForward:(id)sender{
    @autoreleasepool {
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
    
            [currWebview goForward];
        
        if([currWebview mainFrameURL])
            self.urlTextField.stringValue=[currWebview mainFrameURL];
    }
    
}

-(NSTabView*)getTabView{
    return tabView;
}

-(IBAction)pageBack:(id)sender{
    @autoreleasepool {
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        
        [currWebview goBack];
        
        if([currWebview mainFrameURL])
            self.urlTextField.stringValue=[currWebview mainFrameURL];
    }
}

-(IBAction)refreshCurrentPage:(id)sender{
    @autoreleasepool {
        //reload page
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        [currWebview reloadFromOrigin:nil];
    }
}

-(IBAction)addCurrentPageToBookmark:(id)sender{
    @autoreleasepool {
        //new tab
        // [self addNewTab:nil];
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        self.urlTextField.stringValue=[currWebview mainFrameURL];
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.bookmarkController addBookmarkWithURL:[currWebview mainFrameURL] Title:[currWebview mainFrameTitle] Icon:[currWebview mainFrameIcon]];
    }
}

- (IBAction)webViewAction:(id)sender {
    @autoreleasepool {
        NSUInteger segIndex = [(NSSegmentedControl *)sender selectedSegment];
        if(segIndex == 0){
            [self refreshCurrentPage:nil];
        }else if(segIndex ==1){
            //clear url
            self.urlTextField.stringValue = @"";
        }else{
            [self addCurrentPageToBookmark:nil];
           
        }
    }
}

- (IBAction)startDownload:(id)sender {
    @autoreleasepool {
        NSSegmentedControl *startDownloadSeg = sender;
        if(startDownloadSeg.selectedSegment == 0){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:START_DOWNLOAD_KEY];
        }else{
             [[NSUserDefaults standardUserDefaults] setBool:NO forKey:START_DOWNLOAD_KEY];
            GlobalObject *tmpGlobal = [GlobalObject sharedObj];
            [tmpGlobal abortAllResource];
        }
    }
}
-(void)updateCurrentWebviewMainFrame{
    @autoreleasepool {
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        if(currentItem == nil){
            self.urlTextField.stringValue = @"";
            return;
        }
        
        TabitemIdentity *currID = currentItem.identifier;
        if([currID isKindOfClass:[TabitemIdentity class]]){
            WebView *currWebview = currID.webview;
            if([[currWebview mainFrameURL] length]){
                self.urlTextField.stringValue=[currWebview mainFrameURL];
              //  self.window.title = [self.urlTextField.stringValue copy];
            }
            else{
                self.urlTextField.stringValue = @"";
               // self.window.title = [BOOKMARK_INVALID_TITLE_STRING copy];
            }
        }
    }
}

-(void)collapseRightView:(NSView *)view
{
    if(view == self.bookmarkSplitview){
        NSView *left  = [[self.bookmarkSplitview subviews] objectAtIndex:0];
        NSView *right = [[self.bookmarkSplitview subviews] objectAtIndex:1];
        
        NSRect leftFrame = [left frame];
        if(leftFrame.size.width >0)
            [self.bookmarkSplitview setPosition:0.0 ofDividerAtIndex:0];
        else
            [self.bookmarkSplitview setPosition:202.0 ofDividerAtIndex:0];
        [self.bookmarkSplitview display];
    }
    else{
        NSView *left  = [[self.taskSplitView subviews] objectAtIndex:0];
        NSView *right = [[self.taskSplitView subviews] objectAtIndex:1];
        
        NSRect rightFrame = [right frame];
        if(rightFrame.size.width >0)
            [self.taskSplitView setPosition:self.taskSplitView.frame.size.width ofDividerAtIndex:0];
        else
            [self.taskSplitView setPosition:(self.taskSplitView.frame.size.width - 202.0) ofDividerAtIndex:0];
        [self.taskSplitView display];
    }
}


-(IBAction)toggleDownload:(id)sender{
    @autoreleasepool {
        [self collapseRightView:self.taskSplitView];
  }
}
-(IBAction)toggleBookMark:(id)sender{
    // [self.drawer openOnEdge:NSMinXEdge];
    @autoreleasepool {
       [self collapseRightView:self.bookmarkSplitview];
      }
}

- (void)addDefaultTabs {
    @autoreleasepool {
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    
    [self addNewTabWithURL:[tmpGlobal.preferenceController defaultURL]];
    }
}

- (IBAction)addNewTab:(id)sender {
    @autoreleasepool {
        

    [self addNewTabWithURL:nil];
    }
}
/*
- (IBAction)resizeToView:(id)sender
{
    // webview content sub/document-view
    NSView *docView =[[[webView mainFrame] frameView] documentView];
    NSRect docRect = [docView frame];
    
    // height and width
    int height = docRect.size.height;
    int width = docRect.size.width;
    
    NSRect frame = [window frame];
    int delta = height - frame.size.height;
    
    // y/height
    frame.origin.y -= delta;
    frame.size.height += delta;
    
    // x/width
    frame.size.width = width;
    
    [window setFrame:frame display:YES];
}
*/
- (IBAction)adjustToFitWebpage:(id)sender
{
    @autoreleasepool {
        // webview content sub/document-view
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        
        NSView *docView =[[[currWebview mainFrame] frameView] documentView];
        NSRect docRect = [docView frame];
        
        // height and width
        int width = docRect.size.width;
        
        NSRect frame = [self.window frame];
        
        int widedelta = frame.size.width - currWebview.frame.size.width;
        // x/width
        frame.size.width = width + widedelta;
        
        [self.window.animator setFrame:frame display:YES animate:YES];
    }
}

- (IBAction)increaseWindowSize:(id)sender
{
    @autoreleasepool {
        
        
        // webview content sub/document-view
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        NSRect frame = [self.window frame];
        
        // x/width
        frame.size.width *= (1+0.05);
        
        [self.window.animator setFrame:frame display:YES animate:YES];
    }
}

- (IBAction)decreaseWindowSize:(id)sender
{
    @autoreleasepool {
        
        
        // webview content sub/document-view
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        TabitemIdentity *currID = currentItem.identifier;
        WebView *currWebview = currID.webview;
        if(currWebview == nil)
            return;
        
        NSRect frame = [self.window frame];
        
        // x/width
        frame.size.width *= (1-0.05);
        
        [self.window.animator setFrame:frame display:YES animate:YES];
    }
}
-(IBAction)menuBatchDownloadpanel:(id)sender{
    if([self isAuthencating] == YES) return;
    
    @autoreleasepool {
        [self.preferenceViewController showBatchDownloadPanel:nil];
    }
}

- (IBAction)closeTab:(id)sender {
    @autoreleasepool {
        NSTabViewItem *tabViewItem = [tabView selectedTabViewItem];
        if(tabViewItem == nil)
            return;
        
        if (([tabBar delegate]) && ([[tabBar delegate] respondsToSelector:@selector(tabView:shouldCloseTabViewItem:)])) {
            if (![[tabBar delegate] tabView:tabView shouldCloseTabViewItem:tabViewItem]) {
                return;
            }
        }
        
        if (([tabBar delegate]) && ([[tabBar delegate] respondsToSelector:@selector(tabView:willCloseTabViewItem:)])) {
            [[tabBar delegate] tabView:tabView willCloseTabViewItem:tabViewItem];
        }
        
        [tabView removeTabViewItem:tabViewItem];
        if (([tabBar delegate]) && ([[tabBar delegate] respondsToSelector:@selector(tabView:didCloseTabViewItem:)])) {
            [[tabBar delegate] tabView:tabView didCloseTabViewItem:tabViewItem];
        }
        
    }
    
}

- (IBAction)closeAllTabs:(id)sender {
    @autoreleasepool {
        while ([tabView selectedTabViewItem]) {
            [self closeTab:sender];
        } ;
    }
}

-(IBAction)selectNextTab:(id)sender{
    @autoreleasepool {
        [tabView selectNextTabViewItem:nil];
    }
}

-(IBAction)selectPreviousTab:(id)sender{
    @autoreleasepool {
        [tabView selectPreviousTabViewItem:nil];
    }
}

- (void)setIconNamed:(id)sender {
    @autoreleasepool {
        
    
	NSString *iconName = [sender titleOfSelectedItem];
	if ([iconName isEqualToString:@"None"]) {
		[[[tabView selectedTabViewItem] identifier] setValue:nil forKeyPath:@"icon"];
		[[[tabView selectedTabViewItem] identifier] setValue:@"None" forKeyPath:@"iconName"];
	} else {
		NSImage *newIcon = [NSImage imageNamed:iconName];
		[[[tabView selectedTabViewItem] identifier] setValue:newIcon forKeyPath:@"icon"];
		[[[tabView selectedTabViewItem] identifier] setValue:iconName forKeyPath:@"iconName"];
	}
    }
}

- (void)setObjectCount:(id)sender {
    @autoreleasepool {
        
    
	[[[tabView selectedTabViewItem] identifier] setValue:[NSNumber numberWithInteger:[sender integerValue]] forKeyPath:@"objectCount"];
    }
}

- (void)setObjectCountColor:(id)sender {
     @autoreleasepool {
	[[[tabView selectedTabViewItem] identifier] setValue:[sender color] forKeyPath:@"objectCountColor"];
     }
}

- (IBAction)showObjectCountAction:(NSButton *)sender {
     @autoreleasepool {
	[[[tabView selectedTabViewItem] identifier] setValue:[NSNumber numberWithBool:[sender state]] forKeyPath:@"showObjectCount"];
     }
}

- (IBAction)isProcessingAction:(NSButton *)sender {
     @autoreleasepool {
	[[[tabView selectedTabViewItem] identifier] setValue:[NSNumber numberWithBool:[sender state]] forKeyPath:@"isProcessing"];
     }
}

- (IBAction)isEditedAction:(NSButton *)sender {
     @autoreleasepool {
	[[[tabView selectedTabViewItem] identifier] setValue:[NSNumber numberWithBool:[sender state]] forKeyPath:@"isEdited"];
     }
}

- (IBAction)hasLargeImageAction:(NSButton *)sender {
     @autoreleasepool {
    if ([sender state] == NSOnState) {
         [[[tabView selectedTabViewItem] identifier] setValue:[NSImage imageNamed:@"largeImage"] forKeyPath:@"largeImage"];
    } else {
        [[[tabView selectedTabViewItem] identifier] setValue:nil forKeyPath:@"largeImage"];
    }
     }
}

- (IBAction)hasCloseButtonAction:(NSButton *)sender {
     @autoreleasepool {
	[[[tabView selectedTabViewItem] identifier] setValue:[NSNumber numberWithBool:[sender state]] forKeyPath:@"hasCloseButton"];
     }
}

- (IBAction)setTabLabel:(id)sender {
 @autoreleasepool {
	[[[tabView selectedTabViewItem] identifier] setValue:[sender stringValue] forKeyPath:@"title"];
 }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL itemAction = [menuItem action];
    
	if (itemAction == @selector(closeTab:)) {
		if (![tabBar canCloseOnlyTab] && ([tabView numberOfTabViewItems] <= 1)) {
			return NO;
		}
    }

	return YES;
}

- (MMTabBarView *)tabBar {
	return tabBar;
}



- (void)menuNeedsUpdate:(NSMenu *)menu {

    if (menu == [popUp_orientation menu]) {
    
        for (NSMenuItem *anItem in [menu itemArray]) {

            [anItem setEnabled:YES];
            
            if (![tabBar supportsOrientation:MMTabBarHorizontalOrientation] && [anItem tag] == 0)
                [anItem setEnabled:NO];
            
            if (![tabBar supportsOrientation:MMTabBarVerticalOrientation] && [anItem tag] == 1)
                [anItem setEnabled:NO];
        }
    }
}

-(void)_updateForOrientation:(MMTabBarOrientation)newOrientation {
 @autoreleasepool {
	//change the frame of the tab bar according to the orientation
	NSRect tabBarFrame = [tabBar frame], tabViewFrame = [tabView frame];
	NSRect totalFrame = NSUnionRect(tabBarFrame, tabViewFrame);

	if (newOrientation == MMTabBarHorizontalOrientation) {
		tabBarFrame.size.height = [tabBar isTabBarHidden] ? 1 : 22;
		tabBarFrame.size.width = totalFrame.size.width;
		tabBarFrame.origin.y = totalFrame.origin.y + totalFrame.size.height - tabBarFrame.size.height;
		tabViewFrame.origin.x = 13;
		tabViewFrame.size.width = totalFrame.size.width - 23;
		tabViewFrame.size.height = totalFrame.size.height - tabBarFrame.size.height - 2;
		[tabBar setAutoresizingMask:NSViewMinYMargin | NSViewWidthSizable];
	} else {
		tabBarFrame.size.height = totalFrame.size.height;
		tabBarFrame.size.width = [tabBar isTabBarHidden] ? 1 : 120;
		tabBarFrame.origin.y = totalFrame.origin.y;
		tabViewFrame.origin.x = tabBarFrame.origin.x + tabBarFrame.size.width;
		tabViewFrame.size.width = totalFrame.size.width - tabBarFrame.size.width;
		tabViewFrame.size.height = totalFrame.size.height;
		[tabBar setAutoresizingMask:NSViewHeightSizable];
	}

	tabBarFrame.origin.x = totalFrame.origin.x;
	tabViewFrame.origin.y = totalFrame.origin.y;

	[tabView setFrame:tabViewFrame];
	[tabBar setFrame:tabBarFrame];

    [popUp_orientation selectItemWithTag:newOrientation];
	[[self window] display];

    if (newOrientation == MMTabBarHorizontalOrientation) {
        [[NSUserDefaults standardUserDefaults] setObject:[[popUp_orientation itemAtIndex:0] title] forKey:@"Orientation"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[[popUp_orientation itemAtIndex:1] title] forKey:@"Orientation"];
    }
 }
}

#pragma mark -
#pragma mark KVO 

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (object == tabBar) {
        if ([keyPath isEqualToString:@"orientation"]) {
            [self _updateForOrientation:[[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue]];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark ---- tab bar config ----

- (void)configStyle:(id)sender {
 @autoreleasepool {
	[tabBar setStyleNamed:[sender titleOfSelectedItem]];
    
	[[NSUserDefaults standardUserDefaults] setObject:[sender titleOfSelectedItem]
	 forKey:@"Style"];
 }
}

- (void)configOnlyShowCloseOnHover:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setOnlyShowCloseOnHover:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	 forKey:@"OnlyShowCloserOnHover"];
     }
}

- (void)configCanCloseOnlyTab:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setCanCloseOnlyTab:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	 forKey:@"CanCloseOnlyTab"];
     }
}

- (void)configDisableTabClose:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setDisableTabClose:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	 forKey:@"DisableTabClose"];
     }
}

- (void)configAllowBackgroundClosing:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setAllowsBackgroundTabClosing:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	 forKey:@"AllowBackgroundClosing"];
     }
}

- (void)configHideForSingleTab:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setHideForSingleTab:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	 forKey:@"HideForSingleTab"];
     }
}

- (void)configAddTabButton:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setShowAddTabButton:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender state]]
	 forKey:@"ShowAddTabButton"];
     }
}

- (void)configTabMinWidth:(id)sender {
     @autoreleasepool {
	if ([tabBar buttonOptimumWidth] < [sender integerValue]) {
		[tabBar setButtonMinWidth:[tabBar buttonOptimumWidth]];
		[sender setIntegerValue:[tabBar buttonOptimumWidth]];
		return;
	}

	[tabBar setButtonMinWidth:[sender integerValue]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[sender integerValue]]
	 forKey:@"TabMinWidth"];
     }
}

- (void)configTabMaxWidth:(id)sender {
     @autoreleasepool {
	if ([tabBar buttonOptimumWidth] > [sender integerValue]) {
		[tabBar setButtonMaxWidth:[tabBar buttonOptimumWidth]];
		[sender setIntegerValue:[tabBar buttonOptimumWidth]];
		return;
	}

	[tabBar setButtonMaxWidth:[sender integerValue]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[sender integerValue]]
	 forKey:@"TabMaxWidth"];
     }
}

- (void)configTabOptimumWidth:(id)sender {
     @autoreleasepool {
	if ([tabBar buttonMaxWidth] < [sender integerValue]) {
		[tabBar setButtonOptimumWidth:[tabBar buttonMaxWidth]];
		[sender setIntegerValue:[tabBar buttonMaxWidth]];
		return;
	}

	if ([tabBar buttonMinWidth] > [sender integerValue]) {
		[tabBar setButtonOptimumWidth:[tabBar buttonMinWidth]];
		[sender setIntegerValue:[tabBar buttonMinWidth]];
		return;
	}

	[tabBar setButtonOptimumWidth:[sender integerValue]];
     }
}

- (void)configTabSizeToFit:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setSizeButtonsToFit:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender integerValue]]
	 forKey:@"SizeToFit"];
     }
}

- (void)configTearOffStyle:(id)sender {
     @autoreleasepool {
	[tabBar setTearOffStyle:([sender indexOfSelectedItem] == 0) ? MMTabBarTearOffAlphaWindow : MMTabBarTearOffMiniwindow];

	[[NSUserDefaults standardUserDefaults] setObject:[sender title]
	 forKey:@"Tear-Off"];
     }
}

- (void)configUseOverflowMenu:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setUseOverflowMenu:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender integerValue]]
	 forKey:@"UseOverflowMenu"];
     }
}

- (void)configAutomaticallyAnimates:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setAutomaticallyAnimates:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender integerValue]]
	 forKey:@"AutomaticallyAnimates"];
     }
}

- (void)configAllowsScrubbing:(NSButton *)sender {
     @autoreleasepool {
	[tabBar setAllowsScrubbing:[sender state]];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[sender integerValue]]
	 forKey:@"AllowScrubbing"];
     }
}

#pragma mark -
#pragma mark ---- delegate ----

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
     @autoreleasepool {
	// need to update bound values to match the selected tab
	if ([[tabViewItem identifier] respondsToSelector:@selector(objectCount)]) {
		[objectCounterField setIntegerValue:[[tabViewItem identifier] objectCount]];
	}
    
	if ([[tabViewItem identifier] respondsToSelector:@selector(objectCountColor)]) {
        if ([[tabViewItem identifier] objectCountColor] != nil)
            [objectCounterColorWell setColor:[[tabViewItem identifier] objectCountColor]];
        else
            [objectCounterColorWell setColor:[MMTabBarButtonCell defaultObjectCountColor]];
	}    

	if ([[tabViewItem identifier] respondsToSelector:@selector(isProcessing)]) {
		[isProcessingButton setState:[[tabViewItem identifier] isProcessing]];
	}

	if ([[tabViewItem identifier] respondsToSelector:@selector(isEdited)]) {
		[isEditedButton setState:[[tabViewItem identifier] isEdited]];
	}

	if ([[tabViewItem identifier] respondsToSelector:@selector(hasCloseButton)]) {
		[hasCloserButton setState:[[tabViewItem identifier] hasCloseButton]];
	}

	if ([[tabViewItem identifier] respondsToSelector:@selector(showObjectCount)]) {
		[showObjectCountButton setState:[[tabViewItem identifier] showObjectCount]];
	}
    
	if ([[tabViewItem identifier] respondsToSelector:@selector(largeImage)]) {
		[hasLargeImageButton setState:[[tabViewItem identifier] largeImage] != nil];
	}

	if ([[tabViewItem identifier] respondsToSelector:@selector(iconName)]) {
		NSString *newName = [[tabViewItem identifier] iconName];
		if (newName) {
			[iconButton selectItem:[[iconButton menu] itemWithTitle:newName]];
		} else {
			[iconButton selectItem:[[iconButton menu] itemWithTitle:@"None"]];
		}
	}
    
    if ([[tabViewItem identifier] respondsToSelector:@selector(title)]) {
        [tabField setStringValue:[[tabViewItem identifier] title]];
    }
    //custom
    [self updateCurrentWebviewMainFrame];
     }
    
}

- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    @autoreleasepool {
        if ([[tabViewItem label] isEqualToString:@"Drake"]) {
            /*
             NSAlert *drakeAlert = [NSAlert alertWithMessageText:@"No Way!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"I refuse to close a tab named \"Drake\""];
             [drakeAlert beginSheetModalForWindow:[NSApp keyWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
             */
            return NO;
        }
        
        NSTabViewItem *currentItem = [tabView selectedTabViewItem];
        if(currentItem == tabViewItem){
            
            [self selectNextTab:nil];
        }
    }
	return YES;
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    @autoreleasepool {
        //NSLog(@"didCloseTabViewItem: %@", [tabViewItem label]);
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        TabitemIdentity *identiry =(TabitemIdentity *)tabViewItem.identifier;
        [identiry.webview close];
        
        NSArray *unfinishedArray = [NSArray arrayWithArray: tmpGlobal.unfinishedResources];
        for(URLResource *j in unfinishedArray){
            if(j.parent == identiry.webview)
                [tmpGlobal abortResource:j];
        }
        
        [tmpGlobal.tabItemIdentities removeObject:tabViewItem.identifier];
        
        [self updateCurrentWebviewMainFrame];
    }
}

- (void)tabView:(NSTabView *)aTabView didMoveTabViewItem:(NSTabViewItem *)tabViewItem toIndex:(NSUInteger)index
{
    //NSLog(@"tab view did move tab view item %@ to index:%ld",[tabViewItem label],index);
}

- (void)addNewTabToTabView:(NSTabView *)aTabView {
     @autoreleasepool {
    [self addNewTab:aTabView];
     }
}

- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView {
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil];
}

- (BOOL)tabView:(NSTabView *)aTabView acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabViewItem {
	//NSLog(@"acceptedDraggingInfo: %@ onTabViewItem: %@", [[draggingInfo draggingPasteboard] stringForType:[[[draggingInfo draggingPasteboard] types] objectAtIndex:0]], [tabViewItem label]);
    return YES;
}

- (NSMenu *)tabView:(NSTabView *)aTabView menuForTabViewItem:(NSTabViewItem *)tabViewItem {
	//NSLog(@"menuForTabViewItem: %@", [tabViewItem label]);
	return nil;
}

- (BOOL)tabView:(NSTabView *)aTabView shouldAllowTabViewItem:(NSTabViewItem *)tabViewItem toLeaveTabBarView:(MMTabBarView *)tabBarView {
    return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem inTabBarView:(MMTabBarView *)tabBarView {
	return YES;
}

- (NSDragOperation)tabView:(NSTabView*)aTabView validateDrop:(id<NSDraggingInfo>)sender proposedItem:(NSTabViewItem *)tabViewItem proposedIndex:(NSUInteger)proposedIndex inTabBarView:(MMTabBarView *)tabBarView {

    return NSDragOperationMove;
}

- (NSDragOperation)tabView:(NSTabView *)aTabView validateSlideOfProposedItem:(NSTabViewItem *)tabViewItem proposedIndex:(NSUInteger)proposedIndex inTabBarView:(MMTabBarView *)tabBarView {

    return NSDragOperationMove;
}

- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBarView:(MMTabBarView *)tabBarView {
	//NSLog(@"didDropTabViewItem: %@ inTabBarView: %@", [tabViewItem label], tabBarView);
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(NSUInteger *)styleMask {
	// grabs whole window image
	NSImage *viewImage = [[NSImage alloc] init];
	NSRect contentFrame = [[[self window] contentView] frame];
	[[[self window] contentView] lockFocus];
	NSBitmapImageRep *viewRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:contentFrame];
	[viewImage addRepresentation:viewRep];
	[[[self window] contentView] unlockFocus];

	// grabs snapshot of dragged tabViewItem's view (represents content being dragged)
	NSView *viewForImage = [tabViewItem view];
	NSRect viewRect = [viewForImage frame];
	NSImage *tabViewImage = [[NSImage alloc] initWithSize:viewRect.size];
	[tabViewImage lockFocus];
	[viewForImage drawRect:[viewForImage bounds]];
	[tabViewImage unlockFocus];

	[viewImage lockFocus];
	NSPoint tabOrigin = [tabView frame].origin;
	tabOrigin.x += 10;
	tabOrigin.y += 13;
    [tabViewImage drawAtPoint:tabOrigin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//	[tabViewImage compositeToPoint:tabOrigin operation:NSCompositeSourceOver];
	[viewImage unlockFocus];

    MMTabBarView *tabBarView = (MMTabBarView *)[aTabView delegate];
    
	//draw over where the tab bar would usually be
	NSRect tabFrame = [tabBar frame];
	[viewImage lockFocus];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(tabFrame);
	//draw the background flipped, which is actually the right way up
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:1.0 yBy:-1.0];
	[transform concat];
	tabFrame.origin.y = -tabFrame.origin.y - tabFrame.size.height;
	[[tabBarView style] drawBezelOfTabBarView:tabBarView inRect:tabFrame];
	[transform invert];
	[transform concat];

	[viewImage unlockFocus];

	if ([tabBarView orientation] == MMTabBarHorizontalOrientation) {
		offset->width = [tabBarView leftMargin];
		offset->height = 22;
	} else {
		offset->width = 0;
		offset->height = 22 + [tabBarView topMargin];
	}

	if (styleMask) {
		*styleMask = NSTitledWindowMask | NSTexturedBackgroundWindowMask;
	}

	return viewImage;
}

- (MMTabBarView *)tabView:(NSTabView *)aTabView newTabBarViewForDraggedTabViewItem:(NSTabViewItem *)tabViewItem atPoint:(NSPoint)point {
	//NSLog(@"newTabBarViewForDraggedTabViewItem: %@ atPoint: %@", [tabViewItem label], NSStringFromPoint(point));

	//create a new window controller with no tab items
	WebBrowserWindowController *controller = [[WebBrowserWindowController alloc] initWithWindowNibName:@"DemoWindow"];
    
    MMTabBarView *tabBarView = (MMTabBarView *)[aTabView delegate];
    
	id <MMTabStyle> style = [tabBarView style];

	NSRect windowFrame = [[controller window] frame];
	point.y += windowFrame.size.height - [[[controller window] contentView] frame].size.height;
	point.x -= [style leftMarginForTabBarView:tabBarView];

	[[controller window] setFrameTopLeftPoint:point];
	[[controller tabBar] setStyle:style];

	return [controller tabBar];
}

- (void)tabView:(NSTabView *)aTabView closeWindowForLastTabViewItem:(NSTabViewItem *)tabViewItem {
	//NSLog(@"closeWindowForLastTabViewItem: %@", [tabViewItem label]);
	[[self window] close];
}

- (void)tabView:(NSTabView *)aTabView tabBarViewDidHide:(MMTabBarView *)tabBarView {
	//NSLog(@"tabBarViewDidHide: %@", tabBarView);
}

- (void)tabView:(NSTabView *)aTabView tabBarViewDidUnhide:(MMTabBarView *)tabBarView {
	//NSLog(@"tabBarViewDidUnhide: %@", tabBarView);
}

- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem {
	return [tabViewItem label];
}

- (NSString *)accessibilityStringForTabView:(NSTabView *)aTabView objectCount:(NSInteger)objectCount {
	return (objectCount == 1) ? @"item" : @"items";
}

#pragma mark -
#pragma mark ---- toolbar ----

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

	if ([itemIdentifier isEqualToString:@"TabField"]) {
		[item setPaletteLabel:@"Tab Label"];
		[item setLabel:@"Tab Label"];
		[item setView:tabField];
		[item setMinSize:NSMakeSize(100, [tabField frame].size.height)];
		[item setMaxSize:NSMakeSize(500, [tabField frame].size.height)];
	} else if ([itemIdentifier isEqualToString:@"DrawerItem"]) {
		[item setPaletteLabel:@"Configuration"];
		[item setLabel:@"Configuration"];
		[item setToolTip:@"Configuration"];
		[item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
		[item setTarget:drawer];
		[item setAction:@selector(toggle:)];
	}

	return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
	return [NSArray arrayWithObjects:@"TabField",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"DrawerItem",
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
	return [NSArray arrayWithObjects:@"TabField",
			NSToolbarFlexibleSpaceItemIdentifier,
			@"DrawerItem",
			nil];
}

- (IBAction)toggleToolbar:(id)sender {
	[[[self window] toolbar] setVisible:![[[self window] toolbar] isVisible]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	return YES;
}

- (void)configureTabBarInitially {
     @autoreleasepool {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
         
         
    NSDictionary *appDefaults = [NSDictionary
                                 dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithInteger:SORT_BY_SITE],SORT_BY_KEY,
                                 [NSNumber numberWithBool:YES   ], ALWAYS_CREATE_NEW_WEBVIEW,
                                 [NSNumber numberWithBool:YES   ], ALWAYS_SELECT_NEW_WEBVIEW,
                                @"Safari",@"Style",
                                 [NSNumber numberWithBool:YES],@"ShowAddTabButton",
                                 [NSNumber numberWithBool:YES],@"SizeToFit",
                                 [NSNumber numberWithBool:YES],@"hasCloseButton",
                                 [NSNumber numberWithBool:NO],@"DisableTabClosing",
                                 [NSNumber numberWithBool:YES],@"AllowBackgroundClosing",
                                 PRODUCT_ALL_URL_STRING,DEFAULT_URL_KEY,
                                 [NSNumber numberWithBool:NO],@"CanCloseOnlyTab",
                                 [NSNumber numberWithBool:YES],START_DOWNLOAD_KEY,
                                 [NSNumber numberWithBool:NO],DOWNLOAD_FOLDER_HIDE_KEY,
                                 [NSNumber numberWithBool:NO],PASSWORD_ENABLE_KEY,
                                 [NSNumber numberWithBool:NO],PASSWORD_VALUE_SHOW_KEY,
                                 [NSNumber numberWithInteger:BOOKMARK_SORT_BY_DATE],BOOKMARK_SORT_KEY,
                                 @"Horizontal", @"Orientation",
                                 @"Miniwindow", @"Tear-Off",
                                 @"100", @"TabMinWidth",
                                 @"280", @"TabMaxWidth",
                                 @"130", @"TabOptimalWidth",
                                 [NSNumber numberWithBool:YES], @"UseOverflowMenu",
                                 [NSNumber numberWithBool:YES], @"UseOverflowMenu",
                                 [NSNumber  numberWithBool:NO], PDF_PASSWORD_ENABLE_KEY,
                                 [NSNumber numberWithBool:NO],PDF_ALLOW_PRINT_KEY,
                                 [NSNumber numberWithBool:NO], PDF_ALLOW_COPY_KEY,
                                 [NSNumber numberWithInteger:DEFAULT_WEBPAGE_SAVE_TYPE_PDF],DEFAULT_WEBPAGE_SAVE_TYPE_KEY,
                                 [NSNumber numberWithBool:YES],LOCK_WHEN_CLOSE_KEY,
                                 [NSNumber numberWithBool:NO],IMAGE_ALL_TYPE_KEY,
                                 [NSDate date], MY_TIMESTAMP_KEY,
                                 [NSNumber numberWithBool:NO],MOBILE_MODE_KEY,
                                 nil];
    [defaults registerDefaults:appDefaults];
    
    
    
	[popUp_style selectItemWithTitle:[defaults stringForKey:@"Style"]];
	[popUp_orientation selectItemWithTitle:[defaults stringForKey:@"Orientation"]];
	[popUp_tearOff selectItemWithTitle:[defaults stringForKey:@"Tear-Off"]];

	[button_onlyShowCloseOnHover setState:[defaults boolForKey:@"OnlyShowCloseOnHover"]];
	[button_canCloseOnlyTab setState:[defaults boolForKey:@"CanCloseOnlyTab"]];
	[button_disableTabClosing setState:[defaults boolForKey:@"DisableTabClosing"]];
    [button_allowBackgroundClosing setState:[defaults boolForKey:@"AllowBackgroundClosing"]];
	[button_hideForSingleTab setState:[defaults boolForKey:@"HideForSingleTab"]];
	[button_showAddTab setState:[defaults boolForKey:@"ShowAddTabButton"]];
	[button_sizeToFit setState:[defaults boolForKey:@"SizeToFit"]];
	[button_useOverflow setState:[defaults boolForKey:@"UseOverflowMenu"]];
	[button_automaticallyAnimate setState:[defaults boolForKey:@"AutomaticallyAnimates"]];
	[button_allowScrubbing setState:[defaults boolForKey:@"AllowScrubbing"]];

	[self configStyle:popUp_style];
    [tabBar setOrientation:[popUp_orientation selectedTag]];    
//    [self _updateForOrientation:[popUp_orientation selectedTag]];

    [self configOnlyShowCloseOnHover:button_onlyShowCloseOnHover];    
	[self configCanCloseOnlyTab:button_canCloseOnlyTab];
	[self configDisableTabClose:button_disableTabClosing];
	[self configAllowBackgroundClosing:button_allowBackgroundClosing];
	[self configHideForSingleTab:button_hideForSingleTab];
	[self configAddTabButton:button_showAddTab];
	[self configTabMinWidth:textField_minWidth];
	[self configTabMaxWidth:textField_maxWidth];
	[self configTabOptimumWidth:textField_optimumWidth];
	[self configTabSizeToFit:button_sizeToFit];
	[self configTearOffStyle:popUp_tearOff];
	[self configUseOverflowMenu:button_useOverflow];
	[self configAutomaticallyAnimates:button_automaticallyAnimate];
	[self configAllowsScrubbing:button_allowScrubbing];
     }
}



-(void)performClose:(NSNotification *)anotification
{
    [NSApp terminate:self];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    //  [[MyCoreData sharedInstance]save];
    
          // [tabBar removeObserver:self forKeyPath:@"orientation"];
        
        //[self autorelease];
    GlobalObject *tmpGlobal = [GlobalObject  sharedObj];
    [tmpGlobal.bookmarkController saveBookMark];
    if([[NSUserDefaults standardUserDefaults] boolForKey:LOCK_WHEN_CLOSE_KEY ] == YES){
        [self lockWindow];
    }
  //  [NSApp terminate:self];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[WebHistory optionalSharedHistory] removeAllItems];
    [[NSURLCache sharedURLCache]removeAllCachedResponses];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    sync();
    return NSTerminateNow;
}

- (IBAction)openLocalFile:(id)sender {
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    NSString *tmp = SELECTED_DIRECTORY_PROMPT;
    [panel setMessage:tmp];
    // Display the panel attached to the document's window
    [panel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            // Use the URLs to build a list of items to import.
            NSURL *path  = [urls objectAtIndex:0];
            GlobalObject *tmpGlobal = [GlobalObject sharedObj];
            [tmpGlobal.windowController addNewTabWithURL:[path path]];
        }
    }];
    
    
}


@end
