//
//  WindowController.h
//  MMTabBarView Demo
//
//  Created by John Pannell on 4/6/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#import <EasyWebBrowser/MMTabBarView.h>
#import "WebViewController.h"
#import "PreferenceViewController.h"
@interface WebBrowserWindowController : NSWindowController <NSToolbarDelegate, MMTabBarViewDelegate, NSMenuDelegate> {
    IBOutlet NSTextField *passwordField;
	IBOutlet NSTabView				*tabView;
	IBOutlet NSTextField            *tabField;
	IBOutlet NSDrawer				*drawer;
   // IBOutlet NSDrawer                *taskDrawer;
    IBOutlet NSTableView             *taskTableView;

	IBOutlet MMTabBarView           *tabBar;

	IBOutlet NSButton               *isProcessingButton;
	IBOutlet NSButton				*isEditedButton;
	IBOutlet NSButton				*hasLargeImageButton;
	IBOutlet NSTextField			*objectCounterField;
    IBOutlet NSColorWell            *objectCounterColorWell;
	IBOutlet NSPopUpButton			*iconButton;
    IBOutlet NSButton				*hasCloserButton;
    IBOutlet NSButton               *showObjectCountButton;

	IBOutlet NSPopUpButton			*popUp_style;
	IBOutlet NSPopUpButton			*popUp_orientation;
	IBOutlet NSPopUpButton			*popUp_tearOff;
	IBOutlet NSButton               *button_onlyShowCloseOnHover;    
	IBOutlet NSButton				*button_canCloseOnlyTab;
	IBOutlet NSButton				*button_disableTabClosing;
    IBOutlet NSButton               *button_allowBackgroundClosing;
	IBOutlet NSButton				*button_hideForSingleTab;
	IBOutlet NSButton				*button_showAddTab;
	IBOutlet NSButton				*button_useOverflow;
	IBOutlet NSButton				*button_automaticallyAnimate;
	IBOutlet NSButton				*button_allowScrubbing;
	IBOutlet NSButton				*button_sizeToFit;
	IBOutlet NSTextField			*textField_minWidth;
	IBOutlet NSTextField			*textField_maxWidth;
	IBOutlet NSTextField			*textField_optimumWidth;
    
}

@property IBOutlet NSTabView *authTabView;
-(BOOL)isAuthencating;
- (void)addDefaultTabs;
- (IBAction)lockWindow;
// Actions
-(IBAction)menuBatchDownloadpanel:(id)sender;
- (IBAction)addNewTab:(id)sender;
- (IBAction)closeTab:(id)sender;

- (IBAction)setIconNamed:(id)sender;
- (IBAction)setObjectCount:(id)sender;
- (IBAction)setObjectCountColor:(id)sender;
- (IBAction)setTabLabel:(id)sender;

- (IBAction)showObjectCountAction:(id)sender;
- (IBAction)isProcessingAction:(id)sender;
- (IBAction)isEditedAction:(id)sender;
- (IBAction)hasCloseButtonAction:(id)sender;
- (IBAction)hasLargeImageAction:(id)sender;

// Toolbar
- (IBAction)toggleToolbar:(id)sender;
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;

//custom
- (void)addNewTabWithURL:(NSString *)url;
- (id)addNewTabWithRequest:(NSURLRequest *)request;
- (IBAction)urlEntered:(id)sender;
- (IBAction)pageForwardAndBack:(id)sender;
- (IBAction)webViewAction:(id)sender;
- (IBAction)startDownload:(id)sender;
- (MMTabBarView *)tabBar;
-(void)updateCurrentWebviewMainFrame;
-(NSTabView*)getTabView;
- (IBAction)openLocalFile:(id)sender;
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSSegmentedControl *startDownloadButton;
@property (strong) IBOutlet PreferenceViewController *preferenceViewController;
//@property (strong) IBOutlet NSDrawer *bookmarkDrawer;

@property (weak) IBOutlet NSSplitView *bookmarkSplitview;
@property (weak) IBOutlet NSSplitView *taskSplitView;

/*menu action*/
-(IBAction)printPDF:(id)sender;

@end
