/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem+CoreObject.h>
#import "ETDocumentEditorItemFactory.h"

@implementation ETDocumentEditorItemFactory

- (ETLayoutItemGroup *) compoundDocument
{
	ETLayoutItemGroup *mainItem = [self itemGroupWithSize: NSMakeSize(500, 400)];

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
