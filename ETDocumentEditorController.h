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


@interface ETDocumentEditorController : ETDocumentController
{
	COEditingContext *editingContext;
	COUndoTrack *mainUndoTrack;
}

/** @taskunit Persistency */

@property (nonatomic, readonly) COEditingContext *editingContext;
@property (nonatomic, readonly) COUndoTrack *mainUndoTrack;

/** @taskunit Actions */

- (IBAction) undo: (id)sender;
- (IBAction) redo: (id)sender;

@end

@interface ETUIBuilderDemoController : ETController
- (IBAction)increment: (id)sender;
@end