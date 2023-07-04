//
//  PreferenceViewController.h
//  EasyWebBrowser
//
//  Created by fun on 14-2-25.
//  Copyright (c) 2014年 Michael Monscheuer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "URLResource.h"
@interface PreferenceViewController : NSObject {
   
    __weak NSTextField *savedPath;
}
@property (weak) IBOutlet NSTextField *defaultPageField;
@property (weak) IBOutlet NSButton *isHideDownloadFolder;

@property (strong) IBOutlet NSPanel *preferencePanel;

@property (weak) IBOutlet NSTextField *savedPath;
@property (strong) NSMutableArray *types;
-(IBAction)showPreference:(id)sender;
-(NSString *)resourceSavedPath:(URLResource *)resource;
-(BOOL)isSaveFileFilter:(URLResource *)resource;
-(NSString *)defaultURL;
-(IBAction)openFileNodeInFinder:(id)sender;



@property  IBOutlet NSPanel *batchURLPanel;
@property IBOutlet NSTextView *batchURLView;
-(IBAction)showBatchDownloadPanel:(id)sender;
-(IBAction)closeBatchDownloadPanel:(id)sender;
-(IBAction)batchOpenURLs:(id)sender;
@end
