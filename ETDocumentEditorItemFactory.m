/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem+CoreObject.h>
#import "ETDocumentEditorItemFactory.h"

@implementation ETDocumentEditorItemFactory

- (NSSize) defaultInspectorSize
{
	return NSMakeSize(700, 1000);
}

- (NSSize) defaultEditorSize
{
	return NSMakeSize(800, 450);
}

- (NSSize) defaultEditorBodySize
{
	NSSize size = [self defaultEditorSize];
	size.height -= [self defaultIconAndLabelBarHeight];
	return size;
}

- (NSSize) defaultInspectorBodySize
{
	NSSize size = [self defaultInspectorSize];
	size.height -= [self defaultIconAndLabelBarHeight];
	return size;
}

- (NSSize) defaultBrowserSize
{
	NSSize size = [self defaultInspectorBodySize];
	size.height -= [self defaultBasicInspectorSize].height;
	return size;
}

- (NSSize) defaultBasicInspectorSize
{
	NSSize size = [self defaultInspectorBodySize];
	// NOTE: The height must be an integral value to prevent drawing artifacts.
	size.height = floorf((size.height / 10.) * 8.);
	return size;
}

- (NSSize) defaultBasicInspectorHeaderSize
{
	NSSize size = [self defaultBasicInspectorSize];
	size.height = 80;
	return size;
}

- (NSSize) defaultBasicInspectorContentSize
{
	NSSize size = [self defaultBasicInspectorSize];
	size.height -= [self defaultBasicInspectorHeaderSize].height;
	return size;
}

- (ETLayoutItemGroup *) editorTopBarWithController: (id)aController
{
	NSSize size = NSMakeSize([self defaultEditorSize].width, [self defaultIconAndLabelBarHeight]);
	ETLayoutItemGroup *itemGroup = [self itemGroupWithSize: size];
	// TODO: ETLayoutItem *insertItem = [self insertPopUpWithController: aController];
	ETLayoutItem *insertItem = [self popUpMenu];
	ETLayoutItem *removeItem = [self buttonWithIconNamed: @"list-remove"
	                                              target: aController
	                                              action: @selector(remove:)];
	ETLayoutItem *regroupItem = [self buttonWithIconNamed: @"media-playback-stop"
	                                               target: aController
	                                               action: @selector(group:)];
	ETLayoutItem *ungroupItem = [self buttonWithIconNamed: @"toolbar-space"
	                                               target: nil
	                                               action: @selector(ungroup:)];
	ETLayoutItem *inspectorItem = [self buttonWithIconNamed: @"application-x-executable"
	                                                 target: nil
	                                                 action: @selector(toggleInspectorVisibility:)];
	ETLayoutItem *colorItem = [self buttonWithIconNamed: @"palette-colors"
	                                             target: nil
	                                             action: @selector(toggleColorPickerVisibility:)];
	ETLayoutItem *aspectRepoItem = [self buttonWithIconNamed: @"folder"
	                                                  target: nil
	                                                  action: @selector(toggleAspectRepositoryVisibility:)];
	ETLayoutItem *searchItem = [self searchFieldWithTarget: aController
	                                                action: @selector(filter:)];
	ETLayoutItem *shareItem = [self buttonWithIconNamed: @"preferences-desktop-users"
	                                           target: nil
	                                           action: @selector(share:)];

	ETLayoutItemGroup *leftItemGroup = [self itemGroup];
	ETLayoutItemGroup *middleItemGroup = [self itemGroup];
	ETLayoutItemGroup *rightItemGroup = [self itemGroup];

	[(NSSearchFieldCell *)[[searchItem view] cell] setSendsSearchStringImmediately: YES];

	[itemGroup setIdentifier: @"editorTopBar"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];

	[leftItemGroup setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[leftItemGroup layout] setIsContentSizeLayout: YES];

	[leftItemGroup addItems:
		A([self barElementFromItem: insertItem withLabel: _(@"Insert")],
		  [self barElementFromItem: removeItem withLabel: _(@"Remove")])];

	[middleItemGroup setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[middleItemGroup layout] setIsContentSizeLayout: YES];

	[middleItemGroup addItems:
		A([self barElementFromItem: regroupItem withLabel: _(@"Group")],
		  [self barElementFromItem: ungroupItem withLabel: _(@"Ungroup")])];

	[rightItemGroup setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[rightItemGroup layout] setIsContentSizeLayout: YES];

	[rightItemGroup addItems:
	 	A([self barElementFromItem: inspectorItem withLabel: _(@"Inspector")],
		  [self barElementFromItem: colorItem withLabel: _(@"Colors")],
		  [self barElementFromItem: aspectRepoItem withLabel: _(@"Aspect Repository")],
		  [self barElementFromItem: searchItem withLabel: _(@"Filter")],
		  [self barElementFromItem: shareItem withLabel: _(@"Share")])];

	[itemGroup addItems: A(leftItemGroup, middleItemGroup, rightItemGroup)];

	return itemGroup;
}

- (ETLayoutItemGroup *) editorWithCompoundDocument: (ETLayoutItemGroup *)aCompoundDocument
{
	ETController *controller = AUTORELEASE([[ETController alloc] initWithObjectGraphContext: [self objectGraphContext]]);
	ETLayoutItemGroup *topBar = [self editorTopBarWithController: controller];
	ETLayoutItemGroup *editor = [self itemGroupWithSize: [self defaultEditorSize]];

	[editor addItems: A(topBar, aCompoundDocument)];
	[editor setIdentifier: @"editor"];
	[editor setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[editor setLayout: [ETColumnLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	// TODO: [editor setController: aController];
	//[aController setDocumentContentItem: anObject];

	/*ETLog(@"\n%@\n", [editor descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys:
		A(@"frame", @"autoresizingMask"), kETDescriptionOptionValuesForKeyPaths,
		@"items", kETDescriptionOptionTraversalKey, nil]]);*/

	return editor;
}

- (ETLayoutItemGroup *) compoundDocument
{
	ETLayoutItemGroup *mainItem = [self itemGroupWithSize: [self defaultEditorBodySize]];

	[mainItem setIdentifier: @"compoundDocument"];
	[mainItem setLayout: [ETFreeLayout layoutWithObjectGraphContext: [self objectGraphContext]]];

	// NOTE: Uncomment for testing
	//[mainItem addItem: [[itemFactory rectangle] copy]];
	
	return mainItem;
}

// TODO: Remove duplication in ETUIBuilderItemFactory
- (ETTool *) pickerTool
{
	ETSelectTool *tool = [ETSelectTool tool];
	
	[tool setAllowsMultipleSelection: YES];
	[tool setAllowsEmptySelection: NO];
	[tool setShouldRemoveItemsAtPickTime: NO];

	return tool;
}

// TODO: Remove duplication in ETUIBuilderItemFactory
- (ETLayoutItemGroup *) objectPicker
{
	ETLayoutItemGroup *picker = [self itemGroupWithRepresentedObject: [ETAspectRepository mainRepository]];
	ETController *controller = AUTORELEASE([[ETController alloc] initWithObjectGraphContext: [self objectGraphContext]]);
	ETItemTemplate *template = [controller templateForType: [controller currentObjectType]];

	[[template item] setActionHandler:
	 	[ETAspectTemplateActionHandler sharedInstanceForObjectGraphContext: [self objectGraphContext]]];
	[picker setActionHandler:
	 	[ETAspectTemplateActionHandler sharedInstanceForObjectGraphContext: [self objectGraphContext]]];

	[controller setAllowedPickTypes: A([ETUTI typeWithClass: [NSObject class]])];

	// TODO: Retrieve the size as ETUIBuilderItemFactory does it
	[picker setSize: NSMakeSize(300, 400)];
	[picker setController: controller];
	[picker setSource: picker];
	[picker setLayout: [ETOutlineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[picker layout] setAttachedTool: [self pickerTool]];
	[[picker layout] setDisplayedProperties: A(kETIconProperty, kETDisplayNameProperty)];
	[picker setHasVerticalScroller: YES];
	[picker reloadAndUpdateLayout];

	return picker;
}

@end
