/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem+CoreObject.h>
#import <EtoileUI/CoreObjectUI.h>
#import "ETWorktableController.h"
#import "ETDocumentEditorItemFactory.h"
#import "ETDocumentEditorConstants.h"

@interface ETCompoundDocumentTemplate : ETItemTemplate
@end

@implementation ETWorktableController

@synthesize editingContext, mainUndoTrack, inspectorItem = _inspectorItem;

- (void) dealloc
{
	DESTROY(_inspectorItem);
	DESTROY(_aspectPicker);
	[super dealloc];
}

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

#pragma mark - Persistency

- (COUndoTrack *) undoTrack
{
	return [self mainUndoTrack];
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

#pragma mark - Finish Launching

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
	// NOTE: This editor item is not used on New Document... To avoid the copy (currently unsupported
	// until we migrate EtoileUI to COCopier), we just create a new instance in
	// -[ETCompoundDocumentTemplate newItemWithURL:options:]
	ETLayoutItemGroup *editorItem = [itemFactory editorWithCompoundDocument: [itemFactory compoundDocument]];
	ETItemTemplate *template =
		[ETCompoundDocumentTemplate templateWithItem: editorItem
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
	[[itemFactory windowGroup] setDelegate: self];
	
	/* Reopen documents or create a new one */

	if (clear)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"kETOpenedDocumentUUIDs"];
	}
	[self showPreviouslyOpenedDocuments];
	// FIXME: [self newDocument: nil]; to create a blank document
	
	/* Show aspect palette */

	ASSIGN(_aspectPicker, [itemFactory objectPicker]);
	[self toggleAspectPicker: nil];
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

#pragma mark - Tracking Active Document

/** The active item/document has changed. */
- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	[self updateInspector];
}

#pragma mark - Tracking Opened Documents

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
		
		// TODO: We should use -[ETDocumentController openItemWithURL:options:]
		ETDocumentEditorItemFactory *transientItemFactory = [ETDocumentEditorItemFactory factory];

		[[transientItemFactory windowGroup]
			addItem: [transientItemFactory editorWithCompoundDocument: documentItem]];
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
	// TODO: Access the persistent item through a controller
	ETUUID *UUID = [[[anItem itemForIdentifier: @"compoundDocument"] persistentRoot] UUID];

	if ([openedDocUUIDs containsObject: UUID])
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByAddingObject: UUID];
	[[NSUserDefaults standardUserDefaults] setObject: [[openedDocUUIDs mappedCollection] stringValue]
	                                          forKey: @"kETOpenedDocumentUUIDs"];
}

- (void) rememberClosedDocumentItem: (ETLayoutItem *)anItem
{
	NSArray *openedDocUUIDs = [self openedDocumentUUIDsFromDefaults];
	// TODO: Access the persistent item through a controller
	ETUUID *UUID = [[[anItem itemForIdentifier: @"compoundDocument"] persistentRoot] UUID];

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

#pragma mark - Presentation

- (ETLayoutItemGroup *) windowGroup
{
	return [[ETDocumentEditorItemFactory factory] windowGroup];
}

- (BOOL) isInspectorHidden
{
	return ([[self windowGroup] containsItem: [self inspectorItem]] == NO);
}

- (void) showInspector
{
	[[self windowGroup] addItem: [self inspectorItem]];
}

- (void) hideInspector
{
	ETAssert([[self windowGroup] containsItem: [self inspectorItem]]);
	[[self windowGroup] removeItem: [self inspectorItem]];
}

- (void) updateInspector
{
	if ([self isInspectorHidden])
		return;

	CGPoint prevInspectorOrigin = [[self inspectorItem] origin];

	[self hideInspector];

	/* Switch to the inspector bound to the current frontmost document */
	ASSIGN(_inspectorItem, [[self activeItem] inspectorItem]);
	[_inspectorItem setOrigin: prevInspectorOrigin];

	[self showInspector];
}

- (NSColorPanel *)colorPanel
{
	return [NSColorPanel sharedColorPanel];
}

#pragma mark - Presentation Actions

- (IBAction) toggleColorPicker: (id)sender
{
	if ([[self colorPanel] isVisible])
	{
		[[self colorPanel] orderOut: sender];
	}
	else
	{
		[[self colorPanel] orderFront: sender];
	}
}

- (IBAction) toggleInspector: (id)sender
{
	if ([self isInspectorHidden])
	{
		[self showInspector];
	}
	else
	{
		[self hideInspector];
	}
}

- (IBAction) toggleAspectPicker: (id)sender
{
	ETLayoutItemFactory *itemFactory = [ETDocumentEditorItemFactory factory];

	if ([[itemFactory windowGroup] containsItem: _aspectPicker])
	{
		[[itemFactory windowGroup] removeItem: _aspectPicker];
	}
	else
	{
		[[itemFactory windowGroup] addItem: _aspectPicker];
	}
}

#pragma mark - History Actions

- (IBAction) undo: (id)sender
{
	// TODO: Access the persistent item through a controller
	[[[[self activeItem] itemForIdentifier: @"compoundDocument"] branch] undo];
}

- (IBAction) redo: (id)sender
{
	// TODO: Access the persistent item through a controller
	[[[[self activeItem] itemForIdentifier: @"compoundDocument"] branch] redo];
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

- (ETLayoutItem *) contentItem
{
	return [[self item] itemForIdentifier: @"compoundDocument"];
}

- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options
{
	ETAssert([[self contentItem] compoundDocument] != nil);
	[[[self contentItem] persistentRoot] commit];
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
	ETDocumentEditorItemFactory *transientItemFactory = [ETDocumentEditorItemFactory factory];
	ETLayoutItemGroup *contentItem = [newDocumentFactory compoundDocument];

	[editingContext insertNewPersistentRootWithRootObject: contentItem];

	ETLayoutItemGroup *presentedItem = [transientItemFactory editorWithCompoundDocument: contentItem];
	ETAssert([presentedItem itemForIdentifier: @"compoundDocument"] == contentItem);

	return presentedItem;
}

@end

@implementation ETUIBuilderDemoController

- (IBAction)increment: (id)sender
{
	ETLayoutItem *counterItem = [[self content] itemForIdentifier: @"counter"];

	NSLog(@"Increment counter %@", counterItem);

	[[counterItem view] setIntegerValue: [[counterItem view] integerValue] + 1];
	[counterItem didChangeValueForProperty: kETViewProperty];
	[[counterItem persistentRoot] commit];
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
	[[documentItem persistentRoot] commit];
}

@end
