//
//  w2w_AppDelegate.m
//  w2w
//
//  Created by Fredrik Wallner on 2006-08-31.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.
//

#import "w2w_AppDelegate.h"
#include <unistd.h>

@implementation w2w_AppDelegate


/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "w2w" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"w2w"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle and all of the 
    framework bundles.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    NSMutableSet *allBundles = [[NSMutableSet alloc] init];
    [allBundles addObject: [NSBundle mainBundle]];
    [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"w2w.data"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {

	/* Restore stderr */
	// Flush before restoring stderr
	fflush(stderr);
	
	// Now restore stderr, so new output goes to console.
	dup2(stderrSave, STDERR_FILENO);
	close(stderrSave);
	
	[managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
	[cUrlResults release], cUrlResults = nil;
    [super dealloc];
}

/**
	Add a site and show the site-window
 */

- (IBAction)addSite:sender
{
	[sites add:nil];
	[editButton setState:NSOnState];
	[siteDrawer open];
}

- (IBAction)editFolder:sender
{
	NSOpenPanel *op;
	int runResult;
	
	op = [NSOpenPanel openPanel];
	
	/* set up new attributes */
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
	[op setAllowsMultipleSelection:NO];
	
	/* display the NSOpenePanel */
	runResult = [op runModalForDirectory:nil file:nil];
	
	/* if successful */
	if (runResult == NSOKButton)
	{
		/* Get the foldername and check if it's changed */
		NSString *filename = [[op filenames] objectAtIndex:0];
		if(![filename isEqualToString:[(NSManagedObject *)[sites selection] valueForKey:@"localpath"]])
		{
			/* Set the  text-field to selection */
			[folderPathField setStringValue:filename];
			/* Set the corresponding value in the Site-field */
			[(NSManagedObject *)[sites selection] setValue:filename forKey:@"localpath"];
			/* Remove the files from the last folder */
			NSSet *temp = [(NSManagedObject *)[sites selection] valueForKey:@"files"];
			NSEnumerator *enumerator = [temp objectEnumerator];
			NSManagedObject *tempMO;
			
			while ((tempMO = [enumerator nextObject]))
			{
				[managedObjectContext deleteObject:tempMO];
			}
			
			[(NSManagedObject *)[sites selection] setValue:nil forKey:@"files"];
		}
	}
}

- (IBAction)updateSite:sender
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [(NSManagedObject *)[sites selection] valueForKey:@"localpath"];
	NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:path];
	NSString *file;
	BOOL isDir;
	NSMutableArray *filesToUpload = [NSMutableArray array];
	
	[progress setHidden:NO];
	[progress startAnimation:self];
	
	NSMutableArray *args = [NSMutableArray array];

	/* Step through the files/folders in the folder and treat them */
	while (file = [dirEnum nextObject])
	{
		/* Check that the file is not a directory */
		if(!([fm fileExistsAtPath:[path stringByAppendingPathComponent:file] isDirectory:&isDir] && isDir))
		{
			/* Add the complete path to the arguments for checksum */
			[args addObject:[path stringByAppendingPathComponent:file]];
		}
	}
	
	/* Debugging */
	if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
		NSLog([NSString stringWithFormat:@"Path: %@\nNumber of files: %d\nLength of arguments: %d", path, [args count], [[args componentsJoinedByString:@" "] length]]);

	if([args count] > 0)
	{
		[progressInfo setStringValue:@"Calculating checksums"];
		/* Prepare the checksum-task */
		NSTask *checksum = [[NSTask alloc] init];
		
		/* Add pipe on stdout to get the results */
		NSPipe *outPipe = [[NSPipe alloc] init];
		[checksum setStandardOutput:outPipe];
		NSFileHandle *handle = [outPipe fileHandleForReading];
		
		/* Add pipe on stdin to feed the filenames */
		/* Now using xargs to fix problem with a large number of files */
		NSPipe *cksumInPipe = [[NSPipe alloc] init];
		[checksum setStandardInput:cksumInPipe];
		NSFileHandle *cksumInHandle = [cksumInPipe fileHandleForWriting];
		
		/* Get all checksums */
		[checksum setLaunchPath:@"/usr/bin/xargs"];
		[checksum setArguments:[NSArray arrayWithObjects:@"-n 1", @"/usr/bin/cksum", nil]];
		[checksum launch];
				
		NSEnumerator *argEnum = [args objectEnumerator];
		NSString *argument;

		NSData *inData;
		NSMutableString *string = [NSMutableString stringWithCapacity:256];
		
		while (argument = [argEnum nextObject])
		{
			[cksumInHandle writeData:[[NSString stringWithFormat:@"\"%@\"\n", argument] dataUsingEncoding:NSUTF8StringEncoding]];
			/* Debugging */
			if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
				NSLog([NSString stringWithFormat:@"\"%@\"", argument]);
			if ((inData = [handle availableData]) && [inData length])
			{
				[string appendString:[[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease]];
				/* Debugging */
				if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
					NSLog([NSString stringWithFormat:@"Read %d bytes data from cksum (%@)", [inData length], [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease]]);
			}
		}
		[cksumInHandle closeFile];
		
		while ((inData = [handle availableData]) && [inData length])
		{
			if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
				NSLog([NSString stringWithFormat:@"Read %d bytes data from cksum (%@)", [inData length], [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease]]);
			[string appendString:[[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease]];
		}
		
		
		[checksum waitUntilExit];
		int status = [checksum terminationStatus];
		
		[checksum release];
		checksum = nil;
		
		/* Debugging */
		if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
			NSLog([NSString stringWithFormat:@"Checksum complete with status: %d\nLength of resultsstring: %d", status, [string length]]);
		
		if (status == 0)
		{
			/* If the checksum task succeded */
			NSMutableArray *checksumArray = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
			[checksumArray removeLastObject];
			NSDictionary *checksumDict = [NSDictionary dictionaryWithObjects:checksumArray forKeys:args];
			NSEnumerator *checksumEnu = [checksumDict keyEnumerator];
			NSString *key, *tempChk;
			
			/* Group the undoing */
			[[managedObjectContext undoManager] beginUndoGrouping];
			
			/* Prepare the FetchRequest */
			NSDictionary * entities = [managedObjectModel entitiesByName];
			NSEntityDescription * entity   = [entities valueForKey:@"File"];
			NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
			[fetch setEntity: entity];
			NSError *error = nil;
			/* Prepare the predicate */
			NSPredicate  *predicate =  [NSPredicate predicateWithFormat: @"(name == $FILENAME) AND (site.localpath == %@)", path];
			
			
			/* Prepare the dictionary to fill in template values */
			NSMutableDictionary *valueDict = [NSMutableDictionary dictionaryWithObject: @""
																				forKey: @"FILENAME"];
			
			while (key = [checksumEnu nextObject])
			{
								
				tempChk = [[[checksumDict valueForKey:key] componentsSeparatedByString:@" "] objectAtIndex:0];
				file = [key substringFromIndex:[path length] + 1];
				[valueDict setValue:file forKey:@"FILENAME"];	
				[fetch setPredicate: [predicate predicateWithSubstitutionVariables: valueDict]];   
				NSArray *results = [managedObjectContext executeFetchRequest:fetch error:&error];
				if((results != nil) && ([results count] > 0))
				{
					/* Found an entry */
					/* Compare saved checksum with the present */
					if(![[(NSManagedObject *)[results objectAtIndex:0] valueForKey:@"checksum"] isEqualToString:tempChk])
					{
						/* The file is changed */
						[filesToUpload addObject:file];
						[[results objectAtIndex:0] setValue:tempChk forKey:@"checksum"];
					}
				}
				else
				{
					[filesToUpload addObject:file];
					/* Add a new entry */
					NSManagedObject *newFile = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:managedObjectContext];
					NSManagedObjectID *objectID = [[[sites selectedObjects] objectAtIndex:0] objectID];
					[newFile setValue:[managedObjectContext objectWithID:objectID] forKey:@"site"];
					[newFile setValue:file forKey:@"name"];
					[newFile setValue:tempChk forKey:@"checksum"];
				}
			}

			/* Group the undoing */
			[[managedObjectContext undoManager] endUndoGrouping];

			/* Treat filesToUpload - array with filenames as NSString */
			
			if((numberOfFilesToUpload = [filesToUpload count]) > 0)
			{
				numberOfFilesUploaded = 0;
				[progressInfo setStringValue:[NSString stringWithFormat:@"Uploading (0/%d)", filesToUpload]];
				
				/* Debugging */
				if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
					NSLog([NSString stringWithFormat:@"Files to upload(%d): %@", numberOfFilesToUpload, [filesToUpload description]]);
				
				[cUrlResults setString:@""];
				
				NSEnumerator *uploadEnumerator = [filesToUpload objectEnumerator];
				NSString *uploadFile;
				NSString *remotebase = [[[[sites selectedObjects] objectAtIndex:0] valueForKey:@"server"] stringByAppendingPathComponent:[[[sites selectedObjects] objectAtIndex:0] valueForKey:@"remotepath"]];
				/* Setup the arguments for curl */
				[args removeAllObjects];
				/* Use config file to solve problems with large uploads */
				[args addObject:@"--config"];
				[args addObject:@"-"];
				NSTask *curl = [[NSTask alloc] init];
				[curl setLaunchPath:@"/usr/bin/curl"];
				[curl setArguments:args];
				
				/* Add pipe on stdErr to recieve parsable data */
				NSPipe *parsePipe = [[NSPipe alloc] init];
				[curl setStandardError:parsePipe];
				NSFileHandle *parseHandle = [parsePipe fileHandleForReading];
				[parseHandle readInBackgroundAndNotify];

				/* Add pipe on stdin to feed the arguments */
				NSPipe *inPipe = [[NSPipe alloc] init];
				[curl setStandardInput:inPipe];
				NSFileHandle *inHandle = [inPipe fileHandleForWriting];
				
				[curl launch];
				
				NSString *curlArgs = [NSString stringWithFormat:@"ftp-create-dirs\nuser = %@:%@\ngloboff\n", [[[sites selectedObjects] objectAtIndex:0] valueForKey:@"username"], [[[sites selectedObjects] objectAtIndex:0] valueForKey:@"password"]];
				[inHandle writeData:[curlArgs dataUsingEncoding:NSUTF8StringEncoding]];
				/* Debugging */
				if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
				{
					[inHandle writeData:[@"verbose\n" dataUsingEncoding:NSUTF8StringEncoding]];
				}
				
				while(uploadFile = [uploadEnumerator nextObject])
				{
					NSString *curlLine = [NSString stringWithFormat:@"upload-file = \"%@\"\nurl = \"ftp://%@\"\n", [path stringByAppendingPathComponent:uploadFile], [remotebase stringByAppendingPathComponent:uploadFile]];
					/* Debugging */
					if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
						NSLog(curlLine);
					
					[inHandle writeData:[curlLine dataUsingEncoding:NSUTF8StringEncoding]];
				}

				[inHandle closeFile];
				[curl waitUntilExit];
				status = [curl terminationStatus];
				
				/* Debugging */
				if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
					NSLog([NSString stringWithFormat:@"Curl returned with status: %d", status]);

				if(status != 0)
				{
					NSRunCriticalAlertPanel([NSString stringWithFormat:@"Error uploading the files to %@", remotebase], [NSString stringWithFormat:@"curl returned error number %d.", status], @"OK", nil, nil);
					[[managedObjectContext undoManager] undo];
				}
				
				[curl release];
				curl = nil;
				[inPipe release];
			}
			[fetch release];
			[outPipe release];
		}
	}
	[progress stopAnimation:self];
	
}

- (void)dataArrived:(NSNotification *) notification
{
	// http://forums.macnn.com/archive/index.php/t-267936.html 	
	// Get output string
	NSData *data = [[notification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	if ([data length] > 0) 
	{	
		[cUrlResults appendString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
		
		/* Look for "> STOR " */
		NSRange startRange = [cUrlResults rangeOfString:@"> STOR "];
		while(startRange.location != NSNotFound)
		{
			NSRange stopRange = [cUrlResults rangeOfString:@"\n" options:0 range:NSMakeRange(startRange.location,[cUrlResults length] - startRange.location)];
			if(stopRange.location != NSNotFound)
			{
				NSString *currentFile = [cUrlResults substringWithRange:NSMakeRange(startRange.location + startRange.length, stopRange.location - (startRange.location + startRange.length))];
				
				if(++numberOfFilesUploaded < numberOfFilesToUpload)
					[progressInfo setStringValue:[NSString stringWithFormat:@"Uploading (%d/%d)\n%@", numberOfFilesUploaded, numberOfFilesToUpload, currentFile]];
				else
					[progressInfo setStringValue:@"Idle"];
				/* Debugging */
				if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
					NSLog(@"Current file (%d of %d): %@\n", numberOfFilesUploaded, numberOfFilesToUpload, currentFile);

				[cUrlResults deleteCharactersInRange:NSMakeRange(0,stopRange.location)];
				startRange = [cUrlResults rangeOfString:@"> STOR "];
			}
			else
			{
				[cUrlResults deleteCharactersInRange:NSMakeRange(0,startRange.location)];
				startRange.location = NSNotFound;				
			}
		}	
	}
	// Ask for another notification
	[[notification object] readInBackgroundAndNotify];
}

				
/** 
	Avoid resizing of the drawer
*/
- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
	return [siteDrawer contentSize];
}

- (IBAction)goToHomepage:sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.wallner.nu/fredrik/software/w2w/?from_w2w"]];
}

/**
	Shut off Edit-button when drawer closes
*/
- (void)drawerDidClose:(NSNotification *)notification
{
	[editButton setState:NSOffState];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)awakeFromNib
{
	[checker initialize];
	/* Start notifications */
	[[NSNotificationCenter defaultCenter] 
		addObserver:self 
		   selector:@selector(dataArrived:) 
			   name:@"NSFileHandleReadCompletionNotification"
			 object:nil];	
	cUrlResults = [NSMutableString stringWithCapacity:1024];
	[cUrlResults retain];
	
	/* Redirect NSLog to go to a spefific file (http://www.atomicbird.com/blog/2007/07/code-quickie-redirect-nslog ) */
													 // Set permissions for our NSLog file
	umask(022);
	
	// Save stderr so it can be restored.
	int stderrSave = dup(STDERR_FILENO);
	
	// Get filename to log
	NSString *logfile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/w2w.log"];
	
	// Send stderr to our file
	FILE *newStderr = freopen([logfile cString], "a", stderr);
	/* End of redirect code */
	
}

@end
