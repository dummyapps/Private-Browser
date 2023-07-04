//
//  DownloadTableviewController.m
//  EasyWebBrowser
//
//  Created by fun on 2/13/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//

#import "DownloadTableviewController.h"
#import "GlobalObject.h"
@interface DownloadTableviewController ()

@end

@implementation DownloadTableviewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


#pragma mark table delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    GlobalObject *tmpGlobal = [GlobalObject sharedObj];
    NSInteger totalNum = [tmpGlobal.unfinishedResources count];
    @autoreleasepool {
        
        
        NSTableColumn *firstColumn = [[tableView tableColumns] objectAtIndex:0];
        [[firstColumn headerCell] setStringValue:[NSString stringWithFormat:DOWNLOAD_TABLE_HEADER_STRING, totalNum]] ;
    }
    
    NSInteger pageDownload = 0;
    
    for(URLResource *i in tmpGlobal.unfinishedResources){
        if(i.manualDownloadFilePath == nil)
            pageDownload ++;
            
    }
    if(pageDownload >0){
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:GLOBAL_IS_PROCESSING_KEY];
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
    }
    return totalNum;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    NSArray *tmpArray  = [[GlobalObject sharedObj] unfinishedResources];
    
    if(rowIndex >= [tmpArray count])
        return nil;
    
    return [tmpArray objectAtIndex:rowIndex];
}

-(IBAction)openResource:(id)sender{
    @autoreleasepool {
        NSTableView *tmpTableView = (NSTableView *)self.view;
        NSInteger row = [tmpTableView rowForView:sender];
        
        if(row <0)
            return;
        
        NSArray *tmpArray  = [[GlobalObject sharedObj] unfinishedResources];
        
        if(row >= [tmpArray count])
            return ;
        
        URLResource *tmpResource= [tmpArray objectAtIndex:row];
        if(tmpResource.manualDownloadFilePath){
            [[NSWorkspace sharedWorkspace] selectFile:tmpResource.manualDownloadFilePath inFileViewerRootedAtPath:@""];
        }
    }
}

@end
