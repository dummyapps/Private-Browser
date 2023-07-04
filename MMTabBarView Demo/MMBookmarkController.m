//
//  MMBookmarkController.m
//  EasyWebBrowser
//
//  Created by fun on 14-2-26.
//  Copyright (c) 2014年 Michael Monscheuer. All rights reserved.
//

#import "MMBookmarkController.h"
#import "GlobalObject.h"
#import "WebViewController.h"
@implementation MMBookmarkController
static NSImage *invalidBookmarkImage = nil;


- (IBAction)bookmarkSort:(id)sender {
    @autoreleasepool {
        NSPopUpButton *popButton = sender;
        NSInteger selectIndex = popButton.indexOfSelectedItem;
        if([self.bookMarks count] )
        {
            NSSortDescriptor *sortDescriptor = nil;
            if(selectIndex == BOOKMARK_SORT_BY_DATE){
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:BOOKMARK_VIEWDATE_KEY
                                                             ascending:NO];
            }else if(selectIndex == BOOKMARK_SORT_BY_COUNTER){
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:BOOKMARK_COUNTER_KEY
                                                             ascending:NO];
            }else if(selectIndex == BOOKMARK_SORT_BY_ADDDATE){
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:BOOKMARK_DATE_KEY
                                                             ascending:NO];
            }
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            [self.bookMarks sortUsingDescriptors:sortDescriptors];
        }
        
        [self.tableview reloadData];
    }
}

#pragma mark table delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    @autoreleasepool {
        if(invalidBookmarkImage == nil)
            invalidBookmarkImage = [NSImage imageNamed:@"NSBookmarksTemplate"];
        
        if(self.bookMarks == nil){
            NSArray *tmpBookmarks = [NSMutableArray arrayWithArray: [[NSUserDefaults standardUserDefaults] objectForKey:BOOKMARK_ARRAY_KEY]];
            self.bookMarks = [NSMutableArray array];
            for(NSDictionary *tmp in tmpBookmarks){
                NSMutableDictionary *newTmp = [NSMutableDictionary  dictionaryWithDictionary:tmp];
                if(newTmp)
                {
                    NSData *iconData = [newTmp objectForKey:BOOKMARK_ICON_KEY];
                    if(iconData == nil)
                        [newTmp setObject:invalidBookmarkImage forKey:BOOKMARK_ICON_KEY ];
                    else{
                        NSImage *tmpImage = [[NSImage alloc ] initWithData:iconData];
                        if(tmpImage)
                            [newTmp setObject:tmpImage forKey:BOOKMARK_ICON_KEY];
                        else
                            [newTmp setObject:invalidBookmarkImage forKey:BOOKMARK_ICON_KEY ];
                    }
                    [self.bookMarks addObject:newTmp];
                }
            }
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:BOOKMARK_ARRAY_KEY]; //this is for migrate older version
            
            //read plist file
            
            NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
            if([paths count] == 0)
                return 0;
            
            NSString *homepath =paths.firstObject;
            NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
            NSString *plistFilePath = [savedHomePath stringByAppendingPathComponent:BOOKMARK_FILE_NAME];
            NSDictionary *bookmarkFileContent = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
            if(bookmarkFileContent){
                tmpBookmarks = [bookmarkFileContent objectForKey:BOOKMARK_ARRAY_KEY];
                for(NSDictionary *tmp in tmpBookmarks){
                    NSMutableDictionary *newTmp = [NSMutableDictionary  dictionaryWithDictionary:tmp];
                    if(newTmp)
                    {
                        NSData *iconData = [newTmp objectForKey:BOOKMARK_ICON_KEY];
                        if(iconData == nil)
                            [newTmp setObject:invalidBookmarkImage forKey:BOOKMARK_ICON_KEY ];
                        else{
                            NSImage *tmpImage = [[NSImage alloc ] initWithData:iconData];
                            if(tmpImage)
                                [newTmp setObject:tmpImage forKey:BOOKMARK_ICON_KEY];
                            else
                                [newTmp setObject:invalidBookmarkImage forKey:BOOKMARK_ICON_KEY ];
                        }
                        [self.bookMarks addObject:newTmp];
                    }
                }
            }
            
           
        }
        
         [self bookmarkSort:self.bookmarkSortButton];
        
        NSTableColumn *firstColumn = [[tableView tableColumns] objectAtIndex:0];
        [[firstColumn headerCell] setStringValue:[NSString stringWithFormat:DOWNLOAD_TABLE_HEADER_STRING, [self.bookMarks count]]] ;
    }
    return [self.bookMarks count];
}


- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    @autoreleasepool {
        
        
        
        NSArray *desc = [tableView sortDescriptors];
        if(desc.count){
            [self.bookMarks sortUsingDescriptors:desc];
        }
        
        [tableView reloadData];
    }
    
}

-(void)awakeFromNib{
    static BOOL initialized = NO;
    @autoreleasepool {
        if(initialized == NO){
            GlobalObject *tmpGlobal = [GlobalObject sharedObj];
            tmpGlobal.bookmarkController = self;
            
            [self.tableview setTarget:self];
            [self.tableview setDoubleAction:@selector(DoubleClick)];
            initialized = YES;
        }
    }
    
}

-(IBAction)DoubleClick{
    @autoreleasepool {
        NSUInteger index = [self.tableview clickedRow];
        if(index >= [self.bookMarks count])
            return;
        
        NSMutableDictionary *dict = [self.bookMarks objectAtIndex:index];
        NSInteger tmpCounter = [[dict objectForKey:BOOKMARK_COUNTER_KEY] integerValue];
        tmpCounter ++;
        [dict setObject:[NSNumber numberWithInteger:tmpCounter] forKey:BOOKMARK_COUNTER_KEY];
        [dict setObject:[NSDate date] forKey:BOOKMARK_VIEWDATE_KEY];
        GlobalObject *tmpGlobal = [GlobalObject sharedObj];
        [tmpGlobal.windowController addNewTabWithURL:[dict objectForKey:BOOKMARK_URL_KEY]];
        [self.tableview reloadData];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    if(rowIndex >= [self.bookMarks count])
        return nil;
    
    return [self.bookMarks objectAtIndex:rowIndex];
}

-(void)addBookmarkWithURL:(NSString *)url Title:(NSString *)title Icon:(NSImage *)icon{
    if(url == nil)
        return;
    
    @autoreleasepool {
        for(NSMutableDictionary *i in self.bookMarks){
            NSString *iURL = [i objectForKey:BOOKMARK_URL_KEY];
            if([iURL  isEqualToString:url] == YES)
                return;
        }
        
        if([title length] == 0)
            title = BOOKMARK_INVALID_TITLE_STRING;
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        [tmpDict setObject:[NSDate date] forKey:BOOKMARK_VIEWDATE_KEY];
        [tmpDict setObject:url forKey:BOOKMARK_URL_KEY];
        [tmpDict setObject:title forKey:BOOKMARK_TITLE_KEY];
        
        if(icon)
            [tmpDict setObject:icon forKey:BOOKMARK_ICON_KEY ];
        else
             [tmpDict setObject:invalidBookmarkImage forKey:BOOKMARK_ICON_KEY ];
        
        [tmpDict setObject:[NSDate date]forKey:BOOKMARK_DATE_KEY];
        [tmpDict setObject:[NSNumber numberWithInteger:1] forKey:BOOKMARK_COUNTER_KEY];
        
        [self.bookMarks insertObject:tmpDict atIndex:0];
        [self.tableview reloadData];
        [self saveBookMark];
    }
    
}


-(NSString *)bookmarkFilePath{
    NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
    if([paths count] == 0)
        return nil;
    
    NSString *homepath =paths.firstObject;
    NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
    NSString *plistFilePath = [savedHomePath stringByAppendingPathComponent:BOOKMARK_FILE_NAME];
    
    return plistFilePath;
}
-(void)saveBookMark{
    @autoreleasepool {
        //  NSArray *saveToArray = [[NSArray alloc]initWithArray:self.bookMarks copyItems:YES];
        NSMutableArray *saveToArray=[NSMutableArray array];
        
        for(NSMutableDictionary *i in self.bookMarks){
            NSMutableDictionary *iTmp = [NSMutableDictionary dictionaryWithDictionary:i];
            NSImage *icon = [iTmp objectForKey:BOOKMARK_ICON_KEY];
            if(icon){
                if(icon == invalidBookmarkImage)
                    [iTmp removeObjectForKey:BOOKMARK_ICON_KEY];
                else
                    [iTmp setObject: [icon TIFFRepresentation]  forKey:BOOKMARK_ICON_KEY];
            }
            else
                [iTmp removeObjectForKey:BOOKMARK_ICON_KEY];
            
            [saveToArray addObject:iTmp];
        }
        
        NSArray* paths = NSSearchPathForDirectoriesInDomains( NSDownloadsDirectory, NSUserDomainMask, YES );
        if([paths count] == 0)
            return ;
        
        NSString *homepath =paths.firstObject;
        NSString *savedHomePath =[homepath stringByAppendingPathComponent:SAVE_TO_FOLDER];
        NSString *plistFilePath = [savedHomePath stringByAppendingPathComponent:BOOKMARK_FILE_NAME];
        /*
        if([[NSFileManager defaultManager] fileExistsAtPath:plistFilePath] == YES)
            [[NSFileManager defaultManager] removeItemAtPath:plistFilePath error:nil];
        */
        if([[NSFileManager defaultManager] fileExistsAtPath:savedHomePath] == NO)
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:savedHomePath withIntermediateDirectories:YES attributes:nil error:NULL];
            
        }
        
        NSDictionary *saveDict = [NSDictionary dictionaryWithObject:saveToArray forKey:BOOKMARK_ARRAY_KEY];
        [saveDict writeToFile:plistFilePath atomically:YES];
    }
}

-(IBAction)deleteBookMark:(id)sender{
    @autoreleasepool {
        
    NSUInteger row =  [self.tableview rowForView:sender];
    [self.bookMarks removeObjectAtIndex:row];
    [self.tableview reloadData];
    [self saveBookMark];
    }
}
@end
