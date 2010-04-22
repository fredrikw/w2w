//
//  updateCheck.h
//  
//
//  Created by Fredrik Wallner on 2008-03-31.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface updateCheck : NSObject {

	IBOutlet NSTextView *updateDetails;
	IBOutlet NSWindow *updateWindow;
	IBOutlet NSMenuItem *updateToggle;
	NSString *downloadURL;
	
}

- (IBAction)checkForUpdate:(id)sender;
- (NSString *)getStringAtXPath:(NSString *)path from:(id)xml;
- (IBAction)download:(id)sender;
- (IBAction)toggleUpdateCheck:(id)sender;
- (void)updateError:(id)err sender:(id)sender;
- (void)initialize;

@end
