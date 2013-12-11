/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem+CoreObject.h>
#import <EtoileUI/CoreObjectUI.h>
#import "ETDocumentEditorController.h"
#import "ETDocumentEditorItemFactory.h"
#import "ETDocumentEditorConstants.h"

@interface ETCompoundDocumentTemplate : ETItemTemplate
@end

@implementation ETDocumentEditorController

@synthesize editingContext, mainUndoTrack;

/* For debugging */
/*- (void) showBasicRectangleItems
{
	ETLayoutItem *rectItem = RETAIN([itemFactory rectangle]);
	ETUUID *uuid = [rectItem UUID];

	[rectItem becomePersistentInContext: ctxt rootObject: rectItem];
	[rectItem commit];
	[[itemFactory windowGroup] addItem: rectItem];

	[ctxt unloadRootObjectTree: rectItem];

	ETLayoutItem *newRectItem = [ctxt objectWithUUID: uuid];
	//[newRectItem setStyle: [ETShape rectangleShapeWithRect: [newRectItem contentBounds]]];
	[[itemFactory windowGroup] addItem: newRectItem];
}*/

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp documentMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp editMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp insertMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
	
	[ETApp toggleDevelopmentMenu: nil];
}

- (NSString *) storePath
{
	return [@"~/TestObjectStore" stringByExpandingTildeInPath];
}

// TODO: Remove duplication in OMAppController
- (void) setUpEditingContext: (BOOL)clear
{
	if (clear && [[NSFileManager defaultManager] fileExistsAtPath: [self storePath]])
	{
		NSError *error = nil;
		[[NSFileManager defaultManager] removeItemAtPath: [self storePath]
		                                           error: &error];
		ETAssert(error == nil);
	}
	COEditingContext *ctxt =
		[COEditingContext contextWithURL: [NSURL fileURLWithPath: [self storePath]]];
	ETAssert(ctxt != nil);

	ASSIGN(editingContext, ctxt);

	[[NSNotificationCenter defaultCenter]
		addObserver: self
	 	   selector: @selector(didCommit:)
	 	       name: COEditingContextDidChangeNotification
	 	     object: editingContext];
}

// TODO: Remove duplication in OMAppController
- (void) setUpUndoTrack: (BOOL)clear
{
	ETAssert([self editingContext] != nil);
	ETUUID *trackUUID = [[NSUserDefaults standardUserDefaults] UUIDForKey: @"WTMainUndoTrackUUID"];

	if (trackUUID == nil)
	{
		trackUUID = [ETUUID UUID];
		[[NSUserDefaults standardUserDefaults] setUUID: trackUUID 
		                                        forKey: @"WTMainUndoTrackUUID"];
	}

	ASSIGN(mainUndoTrack, [COUndoTrack trackForName: [trackUUID stringValue]
	                             withEditingContext: [self editingContext]]);

	if (clear)
	{
		[mainUndoTrack clear];
	}
}

- (void) checkCopySupportForTemplateItem: (ETLayoutItemGroup *)mainItem
{
	ETDocumentEditorItemFactory *itemFactory = [ETDocumentEditorItemFactory factory];

	[mainItem addItem: [[itemFactory rectangle] copy]];
	[[itemFactory windowGroup] addItem: [mainItem copy]];
	[[itemFactory windowGroup] addItem: [mainItem deepCopy]];
}

- (void) setUpTemplates
{
	ETDocumentEditorItemFactory *itemFactory =
		[ETDocumentEditorItemFactory factoryWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
	ETUTI *mainType = 
		[ETUTI registerTypeWithString: @"org.etoile-project.compound-document" 
		                  description: _(@"Etoile Compound or Composite Document Format")
		             supertypeStrings: A(@"public.composite-content")
		                     typeTags: [NSDictionary dictionary]];
	ETLayoutItemGroup *mainItem = [itemFactory compoundDocument];
	ETItemTemplate *template =
		[ETCompoundDocumentTemplate templateWithItem: mainItem
		                                 objectClass: Nil
	                              objectGraphContext: [itemFactory objectGraphContext]];

	[self setTemplate: template forType: mainType];
	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: mainType];
	
	// NOTE: For debugging...
	//[self checkCopySupportForTemplateItem: mainItem];
}

- (void) setUpAndShowEditorUI: (BOOL)clear
{
	ETAssert([self editingContext] != nil);
	
	/* Finish preparing document persistency */

	[self setPersistentObjectContext: [self editingContext]];
	
	ETDocumentEditorItemFactory *itemFactory = [ETDocumentEditorItemFactory factory];

	[[itemFactory windowGroup] setController: self];
	
	/* Reopen documents or create a new one */

	if (clear)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"kETOpenedDocumentUUIDs"];
	}
	[self showPreviouslyOpenedDocuments];
	// FIXME: [self newDocument: nil]; to create a blank document
	
	/* Show aspect palette */

	[[itemFactory windowGroup] addItem: [itemFactory objectPicker]];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	/* If YES, deletes the existing store, the undo track and previously opened 
	   documents in the defaults */
	BOOL clear = NO;

	[self setUpMenus];
	[self setUpEditingContext: clear];
	[self setUpUndoTrack: clear];
	[self setUpTemplates];
	[self setUpAndShowEditorUI: clear];

	//[self showBasicRectangleItemsForDebugging];
}

// TODO: Remove duplication in OMAppController
- (void) didCommit: (NSNotification *)notif
{
	COCommand *command = [[notif userInfo] objectForKey: kCOCommandKey];
	BOOL isUndoOrRedo = (command == nil);

	if (isUndoOrRedo)
		return;

	ETLog(@"Recording command %@ on %@", command, mainUndoTrack);

	ETAssert([mainUndoTrack currentNode] != nil);
}

// TODO: Move the methods below to ETDocumentController once Worktable is more mature

- (void) showPreviouslyOpenedDocuments
{
	ETAssert([self editingContext] != nil);

	for (ETUUID *uuid in [self openedDocumentUUIDsFromDefaults])
	{
		ETLayoutItemGroup *documentItem = [[[self editingContext] persistentRootForUUID: uuid] rootObject];
		if (documentItem == nil)
		{
			ETLog(@"WARNING: Found no document %@", uuid);
			[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"kETOpenedDocumentUUIDs"];
			return;
		}
		[[[ETLayoutItemFactory factory] windowGroup] addItem: documentItem];
	}
}

- (NSArray *) openedDocumentUUIDsFromDefaults
{
	NSArray *openedDocUUIDStrings = [[NSUserDefaults standardUserDefaults] arrayForKey: @"kETOpenedDocumentUUIDs"];
	NSMutableArray *openedDocUUIDs = [NSMutableArray array];

	for (NSString *UUIDString in openedDocUUIDStrings)
	{
		[openedDocUUIDs addObject: [ETUUID UUIDWithString: UUIDString]];
	}

	return openedDocUUIDs;
}

- (void) rememberOpenedDocumentItem: (ETLayoutItem *)anItem
{
	NSArray *openedDocUUIDs = [self openedDocumentUUIDsFromDefaults];
	ETUUID *UUID = [[anItem persistentRoot] UUID];

	if ([openedDocUUIDs containsObject: UUID])
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByAddingObject: UUID];
	[[NSUserDefaults standardUserDefaults] setObject: [[openedDocUUIDs mappedCollection] stringValue]
	                                          forKey: @"kETOpenedDocumentUUIDs"];
}

- (void) rememberClosedDocumentItem: (ETLayoutItem *)anItem
{
	NSArray *openedDocUUIDs = [self openedDocumentUUIDsFromDefaults];
	ETUUID *UUID = [[anItem persistentRoot] UUID];

	if ([openedDocUUIDs containsObject: UUID] == NO)
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByRemovingObject: UUID];
	[[NSUserDefaults standardUserDefaults] setObject: openedDocUUIDs 
	                                          forKey: @"kETOpenedDocumentUUIDs"];
}

- (void) didOpenDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberOpenedDocumentItem: anItem];
}

- (void) didCreateDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberOpenedDocumentItem: anItem];

	// Hmm, not sure that's the proper place to commit
	NSError *error = nil;

	[[self editingContext] commitWithIdentifier: kETDocumentEditorCommitCreate
	                                  undoTrack: [self mainUndoTrack]
	                                      error: &error];
	ETAssert(error == nil);
}

// Won't be called on quit, -terminate: doesn't close the windows with -performClose:
- (void) willCloseDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberClosedDocumentItem: anItem];
}

- (IBAction) undo: (id)sender
{
	[[[self activeItem] branch] undo];
}

- (IBAction) redo: (id)sender
{
	[[[self activeItem] branch] redo];
}

// TODO: Remove duplication in OMAppController
- (IBAction) browseUndoHistory: (id)sender
{
	ETAssert(mainUndoTrack != nil);
	ETLayoutItemGroup *browser = [[ETDocumentEditorItemFactory factory]
		historyBrowserWithRepresentedObject: mainUndoTrack title: nil];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

@end

@implementation ETCompoundDocumentTemplate

- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options
{
	ETAssert([anItem compoundDocument] != nil);
	[[anItem persistentRoot] commit];
	return YES;
}

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	COEditingContext *editingContext = [options objectForKey: kETTemplateOptionPersistentObjectContext];
	NSAssert(editingContext != nil,
		@"Current persistent object context must not be nil to create a new item");
	NSAssert([editingContext isEditingContext],
		@"Current persistent object context must be an editing context to create a new document");
	ETDocumentEditorItemFactory *newDocumentFactory =
		[ETDocumentEditorItemFactory factoryWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
	ETLayoutItemGroup *item = [newDocumentFactory compoundDocument];

	[editingContext insertNewPersistentRootWithRootObject: item];

	return item;
}

@end

@implementation ETUIBuilderDemoController

- (IBAction)increment: (id)sender
{
	ETLayoutItem *counterItem = [[self content] itemForIdentifier: @"counter"];

	NSLog(@"Increment counter %@", counterItem);

	[[counterItem view] setIntegerValue: [[counterItem view] integerValue] + 1];
	[counterItem didChangeValueForProperty: kETViewProperty];
	[counterItem commit];
}

@end

@implementation  ETApplication (UIBuilder)

- (IBAction) toggleLiveDevelopment: (id)sender
{
	ETDocumentController *controller = (id)[[[ETLayoutItemFactory factory] windowGroup] controller];
	ETLayoutItem *documentItem = [controller activeItem];
	BOOL isLiveDevelopmentActive = [[documentItem layout] isKindOfClass: [ETFreeLayout class]];

	if (isLiveDevelopmentActive)
	{
		[documentItem setLayout: [ETFixedLayout layoutWithObjectGraphContext: [documentItem objectGraphContext]]];
	}
	else
	{
		[documentItem setLayout: [ETFreeLayout layoutWithObjectGraphContext: [documentItem objectGraphContext]]];
	}
	[documentItem commit];
}

@end
