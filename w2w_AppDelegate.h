//
//  w2w_AppDelegate.h
//  w2w
//
//  Created by Fredrik Wallner on 2006-08-31.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "updateCheck.h"

@interface w2w_AppDelegate : NSObject 
{
    IBOutlet NSWindow *main;
	IBOutlet NSDrawer *siteDrawer;
	IBOutlet NSTextField *folderPathField;
	IBOutlet NSArrayController *sites;
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTableView *table;
	IBOutlet NSButton *editButton;
	IBOutlet updateCheck *checker;
	IBOutlet NSTextField *progressInfo;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	NSMutableString *cUrlResults;
	int numberOfFilesToUpload;
	int numberOfFilesUploaded;
	
	int stderrSave;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (void)dataArrived:(NSNotification *)notification;

- (IBAction)addSite:sender;
- (IBAction)editFolder:sender;
- (IBAction)updateSite:sender;
- (IBAction)goToHomepage:sender;
- (IBAction)saveAction:sender;

@end
