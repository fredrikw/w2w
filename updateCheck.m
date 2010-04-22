//
//  updateCheck.m
//  
//
//  Created by Fredrik Wallner on 2008-03-31.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "updateCheck.h"


@implementation updateCheck

- (IBAction)checkForUpdate:(id)sender
{

	NSBundle *mainBundleForInfo = [NSBundle mainBundle];
	NSURL *checkURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.wallner.nu/fredrik/software/update.php?program=%@&build=%@", [mainBundleForInfo objectForInfoDictionaryKey:@"CFBundleExecutable"], [mainBundleForInfo objectForInfoDictionaryKey:@"CFBundleVersion"]]];
	
	if([[NSUserDefaults standardUserDefaults] valueForKey:@"Debug"])
		NSLog([checkURL description]);
	
	NSXMLDocument *xmlDoc;
    NSError *err=nil;
    if (!checkURL) {
        [self updateError:@"Can't create the NSURL" sender:sender];
        return;
    }
    xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:checkURL
												  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
													error:&err];
    if (xmlDoc == nil) 
	{
        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:checkURL
													  options:NSXMLDocumentTidyXML
														error:&err];
    }
    if (xmlDoc == nil)  
	{
        [self updateError:err 
				   sender:sender];
       return;
    }
	
	NSString *available = [self getStringAtXPath:@".//available" 
											from:xmlDoc];
	if([available isEqualToString:@"yes"])
	{
		NSMutableString *updateText = [NSMutableString stringWithFormat:@"<center><h2>Version: %@ (%@)</h2>Release date: %@</center><br>", [self getStringAtXPath:@"./update/version" from:xmlDoc], [self getStringAtXPath:@"./update/build" from:xmlDoc], [self getStringAtXPath:@"./update/date" from:xmlDoc]];
		[updateText appendString:@"<br><table><th>Release notes:</th>"];
		NSArray *releases = [xmlDoc nodesForXPath:@".//releaseNotes/release" 
											error:&err];
		if (err) 
		{
			[self updateError:err 
					   sender:sender];
			return;
		}
		NSEnumerator *releaseEnum = [releases objectEnumerator];
		NSXMLNode *releaseNode;
		while(releaseNode = [releaseEnum nextObject])
		{
			[updateText appendFormat:@"<tr><td width=50 valign=top>%@</td><td><ul>", [self getStringAtXPath:@"./version" from:releaseNode]];
			NSArray *notes = [releaseNode nodesForXPath:@"./note" error:&err];
			if (err)
			{
				[self updateError:err 
						   sender:sender];
				return;
			}
			if ([notes count] > 0)
			{
				NSEnumerator *notesEnum = [notes objectEnumerator];
				NSXMLNode *note;
				while(note = [notesEnum nextObject])
					[updateText appendFormat:@"<li>%@</li>", [note stringValue]];
			}
			[updateText appendString:@"</ul></td</tr>"];
		}
		[updateText appendString:@"</table>"];
		
		downloadURL = [self getStringAtXPath:@".//link" 
										from:xmlDoc];
		[downloadURL retain];
		NSDictionary *docAttr;
		NSMutableAttributedString *updateTextFormatted = [[NSAttributedString alloc] initWithHTML:[updateText dataUsingEncoding:NSUTF8StringEncoding] 
																			   documentAttributes:&docAttr];
		[updateWindow makeKeyAndOrderFront:self];
		[updateWindow setLevel:NSFloatingWindowLevel];
		[[updateDetails textStorage] setAttributedString:updateTextFormatted];
		
		[updateTextFormatted release], updateTextFormatted = nil;
		[xmlDoc release], xmlDoc = nil;
	}
	else
		if([sender isEqualTo:self])
			NSLog(@"No update available");
		else
			[[NSAlert alertWithMessageText:@"No update available" 
							 defaultButton:nil 
						   alternateButton:nil 
							   otherButton:nil 
				 informativeTextWithFormat:@"You allready have the most recent version."] runModal];
		
}

- (void)updateError:(id)err sender:(id)sender
{
	if(err)
	{
		if([sender isEqualTo:self])
			NSLog(@"Error while checking for update: %@", [err description]);
		else
			[[NSAlert alertWithMessageText:@"Error" 
							 defaultButton:nil 
						   alternateButton:nil 
							   otherButton:nil 
				 informativeTextWithFormat:@"Error while checking for update: %@", [err description]] runModal];
	}
}
	
	
- (NSString *)getStringAtXPath:(NSString *)path from:(id)xml
{
	NSError *err;
	NSArray *tempArray = [xml nodesForXPath:path 
									  error:&err];
	if (err) {
		NSLog([err description]);
		return nil;
	}
	if ([tempArray count] > 0)
		return [[tempArray objectAtIndex:0] stringValue];

	return nil;
}

- (IBAction)download:(id)sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:downloadURL]];
	[updateWindow close];
}

- (IBAction)toggleUpdateCheck:(id)sender;
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"disableUpdateCheck"])
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:FALSE] 
												  forKey:@"disableUpdateCheck"];
		[updateToggle setState:NSOffState];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:TRUE] 
												  forKey:@"disableUpdateCheck"];
		[updateToggle setState:NSOnState];
	}
}

/**
Implementation of dealloc, to release the retained variables.
 */

- (void) dealloc {
	
    [downloadURL release], downloadURL = nil;
    [super dealloc];
}

- (void)initialize;
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"disableUpdateCheck"])
		[updateToggle setState:NSOnState];
	else
	{
		[updateToggle setState:NSOffState];		
		[self checkForUpdate:self];
	}
}

@end
