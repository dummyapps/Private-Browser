//
//  MMBookmarkController.h
//  EasyWebBrowser
//
//  Created by fun on 14-2-26.
//  Copyright (c) 2014年 Michael Monscheuer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMBookmarkController : NSObject
@property (weak) IBOutlet NSPopUpButton *bookmarkSortButton;

@property NSMutableArray *bookMarks;
@property IBOutlet NSTableView *tableview;
-(void)addBookmarkWithURL:(NSString *)url Title:(NSString *)title Icon:(NSImage *)icon;
-(void)saveBookMark;
-(NSString *)bookmarkFilePath;
@end
