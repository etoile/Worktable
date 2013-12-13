/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD (see COPYING)
 */

#import "ETDocumentEditorController.h"
#import "ETWorktableController.h"
#import "ETDocumentEditorConstants.h"
#import "ETDocumentEditorItemFactory.h"

@implementation ETDocumentEditorController

@synthesize documentItem = _documentItem, inspectorItem = _inspectorItem;

- (void) dealloc
{
	DESTROY(_documentItem);
	DESTROY(_inspectorItem);
	[super dealloc];
}

#pragma mark - Accessing UI Objects

- (void) setDocumentItem: (ETLayoutItemGroup *)anItem
{
	[self stopObserveObject: anItem forNotificationName: ETItemGroupSelectionDidChangeNotification];
	ASSIGN(_documentItem, anItem);
	[self setInitialFocusedItem: anItem];
	[self startObserveObject: anItem
	     forNotificationName: ETItemGroupSelectionDidChangeNotification
	                selector: @selector(contentViewSelectionDidChange:)];

	ASSIGN(_inspectorItem, 
		[[ETDocumentEditorItemFactory factory] inspectorWithObject: _documentItem
	                                                    controller: self]);
}

- (ETLayoutItemGroup *) topBarItem
{
	return (id)[[self content] itemForIdentifier: @"editorTopBar"];
}

#pragma mark - Notifications

/** The selection inside the document has changed. */
- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	// TODO: [self updateInspector];
}

#pragma mark - User Interface Item Validation

- (NSSet *) validatableItems
{
	return [NSSet setWithArray: [[self topBarItem] items]];
}

- (BOOL) validateItem: (ETLayoutItem *)anItem
{
	return [self validateUserInterfaceItem: (id)anItem];
}

- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem
{
	/*if (sel_isEqual([anItem action], @selector(addNewObject:)))
	{
		if ([self isSingleSelectionInSourceList])
		{
			return ([self currentObjectType] != nil);
		}
		return NO;
	}
	else if (sel_isEqual([anItem action], @selector(delete:))
	      || sel_isEqual([anItem action], @selector(duplicate:)))
	{
		return ([self isSingleSelectionInSourceList] && [self hasSelectionInContentView]);
	}
	else if (sel_isEqual([anItem action], @selector(open:))
	      || sel_isEqual([anItem action], @selector(markVersion:))
	      || sel_isEqual([anItem action], @selector(revertTo:))
	      || sel_isEqual([anItem action], @selector(browseHistory:))
	      || sel_isEqual([anItem action], @selector(import:))
	      || sel_isEqual([anItem action], @selector(export:)))
	{
		return [self hasSelectionInContentView];
	}*/
	return YES;
}

#pragma mark - History Actions

- (IBAction) markVersion: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) revertTo: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

// TODO: Remove duplication accross EtoileUI applications
- (IBAction) browseHistory: (id)sender
{
	if ([[self documentItem] isPersistent] == NO)
		return;

	id <COTrack> track = [[[self documentItem] objectGraphContext] branch];
	ETLayoutItemGroup *browser =
		[[ETLayoutItemFactory factory] historyBrowserWithRepresentedObject: track
		                                                             title: nil];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

#pragma mark - Other Object Actions

- (IBAction) search: (id)sender
{
	NSString *searchString = [sender stringValue];
	
	ETLog(@"Search %@ with %@", [searchString description], [[[self documentItem] controller] description]);
	
	if ([searchString isEqual: @""])
	{
		[[[self documentItem] controller] setFilterPredicate: nil];
	}
	else
	{
		// TODO: Improve (Full-text, SQL, more properties, Object Matching integration)
		NSString *queryString =
		@"(name CONTAINS %@) OR (typeDescription CONTAINS %@) OR (tagDescription CONTAINS %@)";
		NSPredicate *predicate = [NSPredicate predicateWithFormat: queryString
			                                        argumentArray: A(searchString, searchString, searchString)];
		
		[[[self documentItem] controller] setFilterPredicate: predicate];
	}
}

- (IBAction) share: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) import: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) export: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

@end
