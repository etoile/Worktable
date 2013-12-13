/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>


@interface ETWorktableController : ETDocumentController
{
	COEditingContext *editingContext;
	COUndoTrack *mainUndoTrack;
	ETLayoutItemGroup *_aspectPicker;
	ETLayoutItemGroup *_inspectorItem;
}

/** @taskunit Accessing UI Objects */

@property (nonatomic, readonly) ETLayoutItemGroup *inspectorItem;

/** @taskunit Persistency */

@property (nonatomic, readonly) COEditingContext *editingContext;
@property (nonatomic, readonly) COUndoTrack *mainUndoTrack;

/** @taskunit Presentation Actions */

- (IBAction) toggleColorPicker: (id)sender;
- (IBAction) toggleInspector: (id)sender;
- (IBAction) toggleAspectPicker: (id)sender;

/** @taskunit History Actions */

- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

@end

@interface ETUIBuilderDemoController : ETController
- (IBAction)increment: (id)sender;
@end
