//
//  MMAppDelegate.h
//  MMTabBarView Demo
//
//  Created by Michael Monscheuer on 9/19/12.
//  Copyright (c) 2012 Michael Monscheuer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WebBrowserWindowController.h"
@interface MMAppDelegate : NSObject <NSApplicationDelegate>
//@property (unsafe_unretained) IBOutlet NSPanel *passwordPanel;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property NSWindow *mainWindow;
//@property WebBrowserWindowController    *mainwindowController;

- (IBAction)newWindow:(id)pSender;

@end
