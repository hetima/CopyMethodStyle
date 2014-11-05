//
//  CMSMethodStyleItem.h
//  CopyMethodStyle


@import AppKit;

@interface CMSMethodStyleItem : NSObject
@property (nonatomic, readonly) BOOL valid;
@property (nonatomic, strong, readonly) NSString* primitiveClassName; // ClassName
@property (nonatomic, strong, readonly) NSString* decoratedClassName; // ClassName(Category)


@property (nonatomic, readonly) BOOL propertyDeclaration;
@property (nonatomic, strong, readonly) NSString* prefix; // + or -
@property (nonatomic, strong, readonly) NSString* rawText; //
@property (nonatomic, strong, readonly) NSString* returnType; //

@property (nonatomic, strong, readonly) NSString* selector; //
@property (nonatomic, strong, readonly) NSString* altSelector; // property setter


+ (id)currentLandmarkForEditor:(id /* IDESourceCodeEditor */) editor;
- (NSMenu*)submenuForContextMenu;

@end

@interface CMSLandmarkItemWrapper : NSObject
@property(nonatomic, readonly) id (^test)(id obj, id obj2);
@end

