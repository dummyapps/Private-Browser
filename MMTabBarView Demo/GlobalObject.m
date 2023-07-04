//
//  GlobalObject.m
//  EasyWebBrowser
//
//  Created by fun on 2/13/14.
//  Copyright (c) 2014 Michael Monscheuer. All rights reserved.
//

#import "GlobalObject.h"
#import "AFNetworking.h"
#import "PreferenceViewController.h"
static GlobalObject *singleStone;
static dispatch_queue_t taskQueue = NULL;
@implementation GlobalObject
+(id)sharedObj{
    if(singleStone == nil){
        singleStone = [[GlobalObject alloc] init ];
    }
    
    return singleStone;
}
+(void)showAlert:(NSString *)alertMessage{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:WARNING_STRING];
        [alert setInformativeText:alertMessage];
        [alert addButtonWithTitle:OK_STRING];
        [alert runModal];
    });
}

+(BOOL)isURLAllow:(NSURL *)url{
#if 0
    if([[NSUserDefaults standardUserDefaults] boolForKey:IMAGE_ALL_TYPE_KEY] == NO){
        NSString *hostName = [url host];
        if([hostName.lowercaseString isEqualToString:@"www.instagram.com"] == YES||[hostName.lowercaseString isEqualToString:@"www.periscope.tv"] == YES||[hostName.lowercaseString isEqualToString:@"www.snapchat.com"] == YES||[hostName.lowercaseString isEqualToString:@"vine.co"] == YES){
          //  [GlobalObject showAlert:RESTRICT_URL_STRING];
            return NO;
        }
        
        //检查是否是限制的内容
        
    }
#endif
    return YES;
}

//#define HASH_CAPABILITY 0xffff

-(id)init{
    self = [super init];
    if(self){
        self.tabItemIdentities = [NSMutableArray array];
        self.resources = [NSMutableArray array];
        self.unfinishedResources = [NSMutableArray array];
        self.resourceHash = [NSMutableDictionary dictionary];
        
        if(taskQueue == NULL){
            taskQueue = dispatch_queue_create("com.dummyapp.easyWebBrowser", NULL);
        }
    }
    
    return self;
}

-(NSString *)goodFileName:(NSString *)oldFileName{
    if(oldFileName == nil)
        oldFileName  = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle];
    
    NSCharacterSet *illegalChar = [NSCharacterSet illegalCharacterSet];
    // NSCharacterSet *puchChar = [NSCharacterSet punctuationCharacterSet];
    NSCharacterSet *controlChar = [NSCharacterSet controlCharacterSet];
    //  NSCharacterSet *synbolChar = [NSCharacterSet symbolCharacterSet];
    
    NSCharacterSet *filename_set = [NSCharacterSet characterSetWithCharactersInString:FILENAME_IGNORE_SET];
    oldFileName =  [[oldFileName componentsSeparatedByCharactersInSet:filename_set] componentsJoinedByString:FILENAME_REPLACE_STRING];
    oldFileName =  [[oldFileName componentsSeparatedByCharactersInSet:illegalChar] componentsJoinedByString:@""];
    //    fileName =  [[fileName componentsSeparatedByCharactersInSet:puchChar] componentsJoinedByString:FILENAME_REPLACE_STRING];
    oldFileName =  [[oldFileName componentsSeparatedByCharactersInSet:controlChar] componentsJoinedByString:@""];
    //    fileName =  [[fileName componentsSeparatedByCharactersInSet:synbolChar] componentsJoinedByString:FILENAME_REPLACE_STRING];
    if([oldFileName length] == 0)
        oldFileName     = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
    oldFileName  =[oldFileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if([oldFileName length] == 0)
        oldFileName  = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
    
    return oldFileName;
}


//only called by downloadNextResource , in mainthread
-(void)finishResource:(URLResource *)resource{
    @autoreleasepool {
        
        if([self.preferenceController isSaveFileFilter:resource] == NO){
            [self abortResource:resource];
            return ;
        }
        
        if([self.unfinishedResources containsObject:resource] == YES){
            [self.unfinishedResources removeObject:resource];
        }
#if 0
        if([self.unfinishedResources count] == 0)
            [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
#endif
        [self.taskTableview reloadData];
    }
    if(resource.data.length){
        dispatch_async(taskQueue, ^{
            @autoreleasepool {
                //save images to file
                //because image has to compare image_width and image_height
                GlobalObject *globalObj = [GlobalObject sharedObj];
                PreferenceViewController *tmpController = globalObj.preferenceController;
                NSString *savedPath = [tmpController resourceSavedPath:resource];
                if(savedPath){
                    [resource.data writeToFile:savedPath atomically:YES];
                    resource.data = nil;
                    resource.parent = nil;
                    resource.id = nil;
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            [self abortResource:resource];
                        }
                    });
                }
            }
        });
    }
}

-(void)abortResource:(URLResource *)resource{
    @autoreleasepool {
        resource.data = nil;
        resource.parent = nil;
        resource.id  = nil;
        if([self.unfinishedResources containsObject:resource] == YES){
            [self.unfinishedResources removeObject:resource];
        }
        
#if 0
        if([self.unfinishedResources count] == 0)
                [[NSUserDefaults standardUserDefaults]setBool:NO forKey:GLOBAL_IS_PROCESSING_KEY];
#endif
        NSString * hashKey =[NSString stringWithFormat:@"%ld", [resource.url.absoluteString hash]] ;
        
        if([self.resourceHash objectForKey:hashKey]){
            [self.resourceHash removeObjectForKey:hashKey];
        }
        [self.taskTableview reloadData];
    }
}

-(void)abortAllResource{
    @autoreleasepool {
        NSArray *tmpArray = [NSArray arrayWithArray:self.unfinishedResources];
        for(URLResource *i in tmpArray){
            [self abortResource:i];
        }
    }
}
/*
-(void)downloadNextResource{
    return;
    dispatch_async(taskQueue, ^{
        if([self.unfinishedResources count]){
            URLResource *resource = [self.unfinishedResources objectAtIndex:0];
            NSURLRequest *request = [NSURLRequest requestWithURL:resource.url];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request] ;
            resource.operation = operation;
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:resource.filename];
            operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Successfully downloaded file to %@", resource.url);
                resource.isFinished = YES;
                resource.operation = nil;
                
                [self finishResource:resource];
                if([self.unfinishedResources count])
                    [self   downloadNextResource];
                else
                    isdownloading = NO;
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
                resource.operation = nil;
                resource.isFinished = YES;
                [self finishResource:resource];
                if([self.unfinishedResources count])
                    [self downloadNextResource];
                else
                    isdownloading = NO;
            }];
            
            [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long  totalBytesExpectedToRead){
                resource.finishedLength = totalBytesRead;
            }];
            
            [operation start];
        }
    });
    
}
 */

-(void)playSlideshowSounds{
    @autoreleasepool {
        NSURL *path = [[NSBundle mainBundle]URLForResource:@"slideshow" withExtension:@"aif"];
        if(path){
            NSSound *systemSound = [[NSSound alloc] initWithContentsOfFile:path.path byReference:YES];
            if (systemSound) {
                [systemSound play];
            }
        }
    }
}

-(URLResource *)getResourceByID:(NSNumber *)ID{
    for(URLResource *i in self.unfinishedResources){
        if(i.id.integerValue == ID.integerValue)
            return i;
    }
    
    return nil;
}

-(BOOL)addResource:(URLResource *)resource{
    if([self.preferenceController isSaveFileFilter:resource] != YES)
        return NO;
    
    @autoreleasepool {
        NSString * hashKey =[NSString stringWithFormat:@"%lu", [resource.url.absoluteString hash]] ;
        if([self.resourceHash objectForKey:hashKey])
            return NO;
        
        [self.resourceHash setObject:resource.url forKey:hashKey];
        
        if([self.unfinishedResources  count] == 0)
            [self.unfinishedResources addObject:resource];
        else
            [self.unfinishedResources insertObject:resource atIndex:0];
        
        [self.taskTableview reloadData];
        
        return YES;
        
        
#if 0
        if([self.unfinishedResources count])
                [[NSUserDefaults standardUserDefaults]setBool:YES forKey:GLOBAL_IS_PROCESSING_KEY];
#endif
    }
   
}


@end
