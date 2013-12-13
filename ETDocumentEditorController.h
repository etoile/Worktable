/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>
#import <EtoileUI/CoreObjectUI.h>

/** 
 * The controller to supervise a compound document and the editor that encloses it (e.g a wrapper 
 * including a toolbar and status bar) 
 */
@interface ETDocumentEditorController : ETController
{
	ETLayoutItemGroup *_documentItem;
	ETLayoutItemGroup *_inspectorItem;
}

/** @taskunit Accessing UI Objects */

@property (nonatomic, retain) ETLayoutItemGroup *documentItem;
@property (nonatomic, readonly) ETLayoutItemGroup *topBarItem;
@property (nonatomic, readonly) ETLayoutItemGroup *inspectorItem;

/** @taskunit History Actions */

- (IBAction) markVersion: (id)sender;
- (IBAction) revertTo: (id)sender;
- (IBAction) browseHistory: (id)sender;

/** @taskunit Other Object Actions */

- (IBAction) search: (id)sender;
- (IBAction) share: (id)sender;
- (IBAction) import: (id)sender;
- (IBAction) export: (id)sender;

@end
