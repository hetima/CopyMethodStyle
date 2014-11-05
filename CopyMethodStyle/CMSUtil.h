//
//  CMSUtil.h
//  CopyMethodStyle


@import AppKit;

@interface CMSUtil : NSObject

+ (NSString*)trim:(NSString*)text;
+ (NSArray*)slice:(NSString*)text by:(NSString*)separator;
+ (NSArray*)alteredArrayWithArray:(NSArray*)array usingBlock:(id (^)(id obj))block;

// not support block return value
+ (NSString*)methodSelectorName:(NSString*)text;
+ (NSString*)methodReturnType:(NSString*)text;
+ (NSArray*)methodParameters:(NSString*)text addingName:(BOOL)addName;
+ (NSArray*)methodParameterNames:(NSString*)text;

// not support block property
+ (NSString*)propertySelectorNameGetter:(NSString*)text;
+ (NSString*)propertySelectorNameSetter:(NSString*)text;
+ (NSString*)propertyReturnType:(NSString*)text;
+ (NSString*)propertyParameterSetter:(NSString*)text addingName:(BOOL)addName;
+ (NSString*)propertyParameterName:(NSString*)text;


@end
