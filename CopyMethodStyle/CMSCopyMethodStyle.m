//
//  CMSCopyMethodStyle.m
//  CopyMethodStyle



#import "CMSCopyMethodStyle.h"
#import "CMSMethodStyleItem.h"

static CMSCopyMethodStyle *sharedPlugin;


@implementation CMSCopyMethodStyle


+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}


+ (BOOL)shouldLoadPlugin
{
    NSString *currentApplicationName = [[NSBundle mainBundle]infoDictionary][@"CFBundleName"];
    if (![currentApplicationName isEqual:@"Xcode"]){
        return NO;
    }
    
    // check something
    
    return YES;
}


+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    if ([self shouldLoadPlugin]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }else{
        NSLog(@"CopyMethodStyle was not loaded. shouldLoadPlugin==NO");
    }
}


- (instancetype)initWithBundle:(NSBundle *)plugin
{
    self = [super init];
    if (!self) return nil;
    
    
    _bundle = plugin;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        KZRMETHOD_SWIZZLING_("IDESourceCodeEditor", "setupTextViewContextMenuWithMenu:",
                             void, call, sel)
        ^(id slf, NSMenu* menu)
        {
            call(slf, sel, menu);
            
            CMSMethodStyleItem* item=[CMSMethodStyleItem currentLandmarkForEditor:slf];
            if (item.valid) {
                NSMenu* submenu=[item submenuForContextMenu];
                NSMenuItem* copyMethodStyleMenuItem=[[NSMenuItem alloc]initWithTitle:@"Copy Method Style" action:nil keyEquivalent:@""];
                [copyMethodStyleMenuItem setSubmenu:submenu];
                
                NSInteger idx=[menu indexOfItemWithTitle:@"Copy"];
                if (idx<0) {
                    idx=[menu numberOfItems];
                }else{
                    idx++;
                }
                [menu insertItem:copyMethodStyleMenuItem atIndex:idx];
                
            }
        }_WITHBLOCK;
        
    });
    
    //[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)note
{

}


@end
