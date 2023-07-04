//
//  FakeModel.h
//  MMTabBarView Demo
//
//  Created by John Pannell on 12/19/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import <EasyWebBrowser/MMTabBarItem.h>

@interface TabitemIdentity : NSObject <MMTabBarItem> {
    NSString    *_title;
	BOOL        _isProcessing;
	NSImage     *_icon;
    NSImage     *_largeImage;
	NSString    *_iconName;
	NSInteger   _objectCount;
    NSColor     *_objectCountColor;
  //  BOOL        _showObjectCount;
	BOOL        _isEdited;
    BOOL        _hasCloseButton;
}

@property (copy)   NSString *title;
@property (strong) NSImage  *largeImage;
@property (strong) NSImage  *icon;
@property (strong) NSString *iconName;

@property (assign) BOOL      isProcessing;
@property (assign) NSInteger objectCount;
@property (strong) NSColor   *objectCountColor;
//@property (assign) BOOL      showObjectCount;
@property (assign) BOOL      isEdited;
@property (assign) BOOL      hasCloseButton;

//custom
@property (strong) WebView *webview;
@property (strong) NSString *requestURL;


// designated initializer
- (id)init;

@end
