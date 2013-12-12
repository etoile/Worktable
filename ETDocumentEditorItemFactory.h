/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>


@interface ETDocumentEditorItemFactory : ETLayoutItemFactory
{

}

- (ETLayoutItemGroup *) editorWithCompoundDocument: (ETLayoutItemGroup *)aCompoundDocument;
- (ETLayoutItemGroup *) compoundDocument;
- (ETLayoutItemGroup *) objectPicker;

@end
