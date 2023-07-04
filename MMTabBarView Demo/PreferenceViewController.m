//
//  PreferenceViewController.m
//  EasyWebBrowser
//
//  Created by fun on 14-2-25.
//  Copyright (c) 2014年 Michael Monscheuer. All rights reserved.
//

#import "FileManagerProxy.h"
#import "PreferenceViewController.h"
#import "GlobalObject.h"
#import "URLResource.h"
@implementation PreferenceViewController
@synthesize preferencePanel;
@synthesize savedPath;


- (IBAction)hideDownloadFolder:(id)sender {
    @autoreleasepool {
        NSButton *tmpBUtton = sender;
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0)
            return;
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
        if(tmpBUtton.state == NSOnState){
            [[FileManagerProxy sharedInstance] URL:[NSURL fileURLWithPath:savedHomePath] setHidden:YES];
        }else{
            [[FileManagerProxy sharedInstance] URL:[NSURL fileURLWithPath:savedHomePath] setHidden:NO];
        }
    }
}

-(void)awakeFromNib{
    static BOOL isInitialized = NO;
    if(isInitialized == NO){
        isInitialized = YES;
        [self hideDownloadFolder: self.isHideDownloadFolder];
    }
}

-(IBAction)showPreference:(id)sender{
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    if([tmpGlobal.windowController isAuthencating   ] == YES)
        return;
    
    
    @autoreleasepool {
        NSString *defaultPage =  [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_URL_KEY];
        if([defaultPage length])
            self.defaultPageField.stringValue = defaultPage;
        else
            self.defaultPageField.stringValue = @"";
    }
    [NSApp beginSheet: self.preferencePanel
       modalForWindow: [NSApp mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
}
- (IBAction)closePanel:(id)sender {
    @autoreleasepool {
        [self setDefaultURL:self.defaultPageField];
        
        NSString *currPassword = [[NSUserDefaults standardUserDefaults] stringForKey:PASSWORD_VALUE_KEY];
        if([currPassword length] == 0){
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PASSWORD_ENABLE_KEY];
        }
        
        if([[[NSUserDefaults standardUserDefaults] stringForKey:PDF_PASSWORD_VALUE_KEY]  length] == 0 )
            [ [NSUserDefaults standardUserDefaults] setBool:NO forKey:PDF_PASSWORD_ENABLE_KEY];
    }
    [NSApp endSheet: self.preferencePanel];
    [self.preferencePanel orderOut:nil];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

 /*
-(void)awakeFromNib{
    GlobalObject *tmpObj = [GlobalObject sharedObj];
    tmpObj.preferenceController = self;
   
    if([[NSUserDefaults standardUserDefaults] dataForKey:SAVE_TO_FOLDER_KEY] == nil){
        GlobalObject *tmpGobal = [GlobalObject sharedObj];
        [tmpGobal.preferenceController showPreference:nil];
        return;
    }
    
    BOOL bookmarkDataIsStable = NO;

    NSData *savedBookMark = [[NSUserDefaults standardUserDefaults] dataForKey:SAVE_TO_FOLDER_KEY];
    NSURL *tmpURL = [NSURL URLByResolvingBookmarkData:savedBookMark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStable error:nil];
    if((bookmarkDataIsStable == YES) || (tmpURL == nil)){
        return ;
    }
    if([tmpURL respondsToSelector:@selector(startAccessingSecurityScopedResource)])
        [tmpURL startAccessingSecurityScopedResource];
    
    self.savedPath.stringValue = [tmpURL path];
  
}
  */
/*
-(IBAction)SelectPath:(id)sender{
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    NSString *tmp = SELECTED_DIRECTORY_PROMPT;
    [panel setMessage:tmp];
    // Display the panel attached to the document's window
    [panel beginSheetModalForWindow:self.preferencePanel completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            // Use the URLs to build a list of items to import.
            NSURL *path  = [urls objectAtIndex:0];
            if([[FileManagerProxy sharedInstance] isFolder:path] == NO)
                return;
            NSError *error = nil;
            NSData *tmpBookmark = [path bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
            if(tmpBookmark == nil){
                NSLog(@"%@", error);
                return;
            }
            [[NSUserDefaults standardUserDefaults] setObject:tmpBookmark forKey:SAVE_TO_FOLDER_KEY];
            self.savedPath.stringValue = [path path];
        }
    }];
}
 */
-(IBAction)openFileNodeInFinder:(NSString *)host {
    @autoreleasepool {
        
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0)
            return ;
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
        
        if(host.length){
            savedHomePath = [savedHomePath stringByAppendingPathComponent:host];
        }
        [[NSFileManager defaultManager]createDirectoryAtPath:savedHomePath withIntermediateDirectories:YES attributes:nil error:nil];
        // NSArray *fileURLs = [NSArray arrayWithObject:[NSURL URLWithString:savedHomePath]];
        // [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:savedHomePath]];
      //  [[NSWorkspace sharedWorkspace] selectFile:savedHomePath inFileViewerRootedAtPath:@""];
         [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:savedHomePath]]];
    }
}



-(NSMutableArray *)retrieveFileTypes:(NSString *)typesString{
    if([typesString length] == 0)
        return nil;
    NSMutableArray *retArray = [NSMutableArray array];
    @autoreleasepool {
        NSArray *tmpTypes = [typesString componentsSeparatedByString:@","];
        for(NSString *i in tmpTypes){
            NSString *iTmp =[i stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([iTmp length])
                [retArray addObject:[iTmp lowercaseString]];
        }
    }
    if([retArray count])
        return  retArray;
    
    return nil;
}

-(IBAction)typeFieldsSaved:(NSTextField *)sender{
    @autoreleasepool {
        self.types = [self retrieveFileTypes:sender.stringValue];
        if (self.types) {
            NSString *tmpTypes = [self.types componentsJoinedByString:@"," ];
            sender.stringValue = tmpTypes;
        }
    }
}

-(BOOL)isSaveFileFilter:(URLResource *)resource{
    //only handle images from webpage
    
    BOOL isImage = [resource.mimeType hasPrefix:@"image"];
    
    //手动下载的全部通过
    if(resource.manualDownloadFilePath) return YES;
    if([resource.parent isKindOfClass:[WebView class]] == NO)
        return YES;
    
    if(resource.length <=0)
        return NO;
    
    if(LITE_VERSION == YES)
        return YES;
    
    BOOL ret = NO;
    @autoreleasepool {
        NSUInteger minValue = 0;
        NSUInteger maxValue = 0;
        
        if([resource.data length]){
            //for finish_resource
            ret = [[NSUserDefaults standardUserDefaults] boolForKey:DOWNLOAD_IMAGE_WIDTH_KEY];
            if(ret == YES){
                NSImage *image = [[NSImage alloc]initWithData:resource.data];
                if(image == nil)
                    return NO;
                
                minValue = [[NSUserDefaults standardUserDefaults] integerForKey:DOWNLOAD_IMAGE_WIDTH_SMALL_VALUE_KEY];
                maxValue = [[NSUserDefaults standardUserDefaults] integerForKey:DOWNLOAD_IMAGE_WIDTH_LARGE_VALUE_KEY];
                
                if(minValue !=0){
                    if(minValue > image.size.width)
                        return NO;
                }
                
                if(maxValue !=0){
                    if(maxValue < image.size.width)
                        return NO;
                }
            }
            
            
            ret = [[NSUserDefaults standardUserDefaults] boolForKey:DOWNLOAD_IMAGE_HEIGHT_KEY];
            if(ret == YES){
                NSImage *image = [[NSImage alloc]initWithData:resource.data];
                if(image == nil)
                    return NO;
                
                minValue = [[NSUserDefaults standardUserDefaults] integerForKey:DOWNLOAD_IMAGE_HEIGHT_SMALL_VALUE_KEY];
                maxValue = [[NSUserDefaults standardUserDefaults] integerForKey:DOWNLOAD_IMAGE_HEIGHT_LARGE_VALUE_KEY];
                
                if(minValue !=0){
                    if(minValue > image.size.height)
                        return NO;
                }
                
                if(maxValue !=0){
                    if(maxValue < image.size.height)
                        return NO;
                }
            }
            
        }else{
            //for add_resource
            ret = [[NSUserDefaults standardUserDefaults] boolForKey:DOWNLOAD_IMAGE_TYPE_KEY];
            if(ret == YES){
                if(self.types ==nil){
                    NSString *typesString = [[NSUserDefaults standardUserDefaults] stringForKey:DOWNLOAD_IMAGE_TYPE_VALUE_KEY];
                    self.types = [self retrieveFileTypes:typesString];
                }
                if([self.types count]){
                    NSString *fileext = [resource.filename pathExtension];
                    BOOL isFound = NO;
                    {
                        for(NSString *i in self.types){
                            if([i isEqualToString:[fileext lowercaseString]] == YES)
                            {
                                isFound = YES;
                                break;
                            }
                        }
                        
                        if(isFound == NO)
                            return NO;
                    }
                }
            }
            
            if(isImage == YES){
                ret = [[NSUserDefaults standardUserDefaults]boolForKey:DOWNLOAD_IMAGE_SIZE_KEY];
                if(ret == YES){
                    minValue = [[NSUserDefaults standardUserDefaults] integerForKey:DOWNLOAD_IMAGE_SIZE_SMALL_VALUE_KEY] *1024;
                    maxValue = [[NSUserDefaults standardUserDefaults] integerForKey:DOWNLOAD_IMAGE_SIZE_LARGE_VALUE_KEY] *1024;
                    
                    if(minValue !=0){
                        if(minValue > resource.length)
                            return NO;
                    }
                    
                    if(maxValue !=0){
                        if(maxValue <resource.length)
                            return NO;
                    }
                }
            }
            
        }
    }
    return YES;
}
-(IBAction)setDefaultURL:(NSTextField *)sender{
    @autoreleasepool {
        NSString *tmpStr = sender.stringValue;
        if([tmpStr length]){
            NSURL *tmpURL = [NSURL URLWithString:tmpStr];
            if([tmpURL.scheme length] == 0){
                tmpStr = [@"http://" stringByAppendingString:tmpStr];
            }
            sender.stringValue = tmpStr;
            [ [NSUserDefaults standardUserDefaults] setObject:tmpStr forKey:DEFAULT_URL_KEY];
        }
        else
            [ [NSUserDefaults standardUserDefaults] removeObjectForKey:DEFAULT_URL_KEY];
        
    }
}

-(NSString *)defaultURL{
    if(LITE_VERSION == YES)
        return PRODUCT_ALL_URL_STRING;
    NSString *tmpStr = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULT_URL_KEY];
    if([tmpStr length] == 0)
        return PRODUCT_ALL_URL_STRING;
    @autoreleasepool {
        NSURL *tmpURL = [NSURL URLWithString:tmpStr];
        if([tmpURL.scheme length] == 0){
            tmpStr = [@"http://" stringByAppendingString:tmpStr];
        }
    }
    return tmpStr;
}
-(NSString *)resourceSavedPath:(URLResource *)resource{
    NSString *testTargetPath = nil;
    @autoreleasepool {
       // NSString *homepath =NSHomeDirectory() ;
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0)
            return nil;
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
        if(LITE_VERSION == NO){
            NSUInteger sortSelection = [[NSUserDefaults standardUserDefaults] integerForKey:SORT_BY_KEY];
            if(sortSelection == SORT_BY_FILENAME_EXTENSION){
                NSString *fileEXT = [resource.filename pathExtension];
                if(fileEXT){
                    savedHomePath = [savedHomePath stringByAppendingPathComponent:[fileEXT lowercaseString]];
                }
            }else if(sortSelection == SORT_BY_RESOLUTION){
                if([resource.data length]){
                    NSImage *tmpImage = [[NSImage alloc]initWithData:resource.data];
                    if(tmpImage){
                        NSString *tmpComp = [NSString stringWithFormat:@"%ld X %ld",(NSUInteger)tmpImage.size.width, (NSUInteger)tmpImage.size.height];
                        
                        if(tmpComp)
                            savedHomePath = [savedHomePath stringByAppendingPathComponent:tmpComp];
                    }
                }else{
                    NSString *fileEXT = [resource.filename pathExtension];
                    if(fileEXT){
                        savedHomePath = [savedHomePath stringByAppendingPathComponent:[fileEXT lowercaseString]];
                    }
                }
                
            }else if(sortSelection == SORT_BY_SITE){
                NSString *siteStr = [resource.hostURL host];
                if(siteStr)
                    savedHomePath= [savedHomePath stringByAppendingPathComponent:[siteStr lowercaseString]];
            }
        }
        
        NSString *newfileName = [[GlobalObject sharedObj] goodFileName:resource.filename];
        NSString *targetPath = [savedHomePath  stringByAppendingPathComponent:newfileName];
        NSUInteger tmpNum = 1;
        testTargetPath = [NSString stringWithString:targetPath];
        
      //  if([[FileManagerProxy sharedInstance] isUrlExist:[NSURL URLWithString: [testTargetPath stringByDeletingLastPathComponent]]] == NO)
        {
            //[[FileManagerProxy sharedInstance] createDirectoryAt:[NSURL URLWithString: savedHomePath]];
            if([[NSFileManager defaultManager] createDirectoryAtPath:[testTargetPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL] == NO){
                NSLog(@"failed to create %@", [testTargetPath stringByDeletingLastPathComponent]);
                return nil;
            }
        }
        
        while ([[NSFileManager defaultManager] fileExistsAtPath:testTargetPath] == YES){
            NSString *pathFirstComponent = [targetPath stringByDeletingPathExtension];
            pathFirstComponent = [pathFirstComponent stringByAppendingFormat:@"_%ld",tmpNum];
            testTargetPath = [pathFirstComponent stringByAppendingPathExtension:[targetPath pathExtension]];
            tmpNum ++;
        }
    }
    return testTargetPath;
}

-(IBAction)showBatchDownloadPanel:(id)sender{
    @autoreleasepool {
#if 0
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                NSTextView *log_view = ((AppDelegate *)[NSApp delegate]).logView;
                NSString *log_string = [NSString stringWithFormat:@"%@\n", log_msg];
                [[[log_view textStorage] mutableString] appendString: log_string];
                NSRange range;
                range = NSMakeRange ([[log_view string] length], 0);
                [log_view  scrollRangeToVisible: range];
            }
        });
#endif
        @autoreleasepool {
           
          //  [[[self.batchURLView textStorage] mutableString] appendString: log_string];
            [[self.batchURLView textStorage].mutableString setString: @""];
        }
    }

    [NSApp beginSheet: self.batchURLPanel
       modalForWindow: [NSApp mainWindow]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
}

-(IBAction)batchOpenURLs:(id)sender{
    @autoreleasepool {
        NSString *urlStrings =[[self.batchURLView textStorage] mutableString];
        if([urlStrings length] == 0)
            return;
        
        NSArray *urlsArray = [urlStrings componentsSeparatedByString:@"\n"];
        if(urlsArray.count == 0)
            return;
        
        for(NSString *url in urlsArray){
            NSString *enteredURLString = [url  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if([enteredURLString length] == 0)
                continue;
            
            NSURL *newURL =[NSURL URLWithString:enteredURLString];
            if(newURL == nil)
                continue;
            
            if([newURL.scheme length] == 0){
                NSString *newString =[ @"http://" stringByAppendingString:enteredURLString];
                newURL = [NSURL URLWithString:newString];
                
            }
            
            if(newURL == nil)
                continue;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    WebBrowserWindowController *windowController = [[GlobalObject sharedObj] windowController];
                    [windowController addNewTabWithURL:newURL.absoluteString];
                }
            });
        }
       
            
            //  [[[self.batchURLView textStorage] mutableString] appendString: log_string];
            [[self.batchURLView textStorage].mutableString setString: @""];
    }
}
-(IBAction)closeBatchDownloadPanel:(id)sender{
    [NSApp endSheet: self.batchURLPanel];
    [self.batchURLPanel orderOut:nil];
}
@end
