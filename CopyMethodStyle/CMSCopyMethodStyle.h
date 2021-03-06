//
//  CMSCopyMethodStyle.h
//  CopyMethodStyle


//setting
/**
 kUseNSSelectorFromString
   YES: use NSSelectorFromString mainly
    NO: use @selector() mainly
 */
#define kUseNSSelectorFromString NO

/**
 kUseKZRMethodSwizzling
 if YES, menu item that copy as KZRMethodSwizzling snippet appear.
 */
#define kUseKZRMethodSwizzling YES
#define kKZRMethodSwizzlingSelfName @"slf"
#define kKZRMethodSwizzlingIMPName @"call"
#define kKZRMethodSwizzlingSELName @"sel"
#define kKZRMethodSwizzlingResultName @"result"

/**
 copy expression that can use for Symbolic Breakpoint.
 -[classname(category) selector]
 */
#define kUseSymbolicBreakpoint YES


@import AppKit;

@interface CMSCopyMethodStyle : NSObject

@property (nonatomic, strong) NSBundle *bundle;

+ (instancetype)sharedPlugin;

@end
