//
//  CMSMethodStyleItem.m
//  CopyMethodStyle


#import "CMSCopyMethodStyle.h"
#import "CMSMethodStyleItem.h"
#import "CMSUtil.h"

/*
 landmark type
 method declaration 4
 method definition 5
 @property 19
 
 class dec 2
 class def 3
 func def 7
 */


@implementation CMSLandmarkItemWrapper {
    id _landmarkItem; //DVTSourceLandmarkItem
    NSTextView* _textView; //DVTSourceTextView
}

+ (instancetype)wrapperWithLandmarkItem:(id)item textView:(NSTextView*)textView
{
    id storage=[textView textStorage];
    
    if (![item respondsToSelector:@selector(parent)])return nil;
    if (![item respondsToSelector:@selector(type)])return nil;
    if (![item respondsToSelector:@selector(range)])return nil;
    if (![item respondsToSelector:@selector(nameRange)])return nil;
    if (![item respondsToSelector:@selector(name)])return nil;

    if (![textView respondsToSelector:@selector(language)])return nil;
    if (![storage respondsToSelector:@selector(sourceLandmarkAtCharacterIndex:)])return nil;
    
    //support Objective-C only
    
    //DVTSourceCodeLanguage
    id lang=((id(*)(id, SEL, ...))objc_msgSend)(textView, @selector(language));

    if (![lang respondsToSelector:@selector(identifier)])return nil;
    NSString* identifier=((id(*)(id, SEL, ...))objc_msgSend)(lang, @selector(identifier));
    if (![identifier hasPrefix:@"Xcode.SourceCodeLanguage.Objective-C"]) {
        return nil;
    }
    
    

    CMSLandmarkItemWrapper* result=[[CMSLandmarkItemWrapper alloc]initWithLandmarkItem:item textView:textView];
    return result;
}


- (instancetype)initWithLandmarkItem:(id /*DVTSourceLandmarkItem*/ )item textView:(NSTextView*)textView
{
    self = [super init];
    if (!self) return nil;
    
    _landmarkItem=item;
    _textView=textView;
    
    
    return self;
}


- (int)type
{
    return ((int(*)(id, SEL, ...))objc_msgSend)(_landmarkItem, @selector(type));
}


- (id)parent
{
    return ((id(*)(id, SEL, ...))objc_msgSend)(_landmarkItem, @selector(parent));
}

- (NSRange)range
{
    NSRange range=((NSRange(*)(id, SEL, ...))objc_msgSend)(_landmarkItem, @selector(range));
    return range;
}

- (NSRange)nameRange
{
    NSRange range=((NSRange(*)(id, SEL, ...))objc_msgSend)(_landmarkItem, @selector(nameRange));
    return range;
}


- (instancetype)parentWrapper
{
    id parentItem=[self parent];
    return [[self class]wrapperWithLandmarkItem:parentItem textView:_textView];
}


- (BOOL)canUseForMethodStyleItem
{
    int type=[self type];
    if (type!=4 && type!=19 && type!=5) {
        return NO;
    }
    
    id parent=[self parent];
    if (!parent) {
        return NO;
    }
    
    if (type==5) {
        NSRange selectedRange=[_textView selectedRange];
        NSRange nameRange=[self nameRange];
        NSUInteger location=nameRange.location+nameRange.length;
        if (selectedRange.location > location) {
            return NO;
        }
    }
    
    
    return YES;
}


- (NSString*)name
{
    return ((id(*)(id, SEL, ...))objc_msgSend)(_landmarkItem, @selector(name));
}


- (NSString*)text
{
    NSString* result=nil;
    int type=[self type];
    
    if (type==4 || type==19) {
        NSRange range=[self range];
        result=[[[_textView textStorage]string]substringWithRange:range];
    }else if(type==5) {
        NSRange range=[self nameRange];
        result=[[[_textView textStorage]string]substringWithRange:range];
    }
    
    return result;
}



@end


#pragma mark -

enum : NSUInteger {
    asGetter,
    asSetter,
};


@implementation CMSMethodStyleItem{
    CMSLandmarkItemWrapper* _landmark;
    NSInteger _propertyTransform;
}



+ (instancetype)currentLandmarkForEditor:(id /* IDESourceCodeEditor */)editor
{
    if (![editor respondsToSelector:@selector(textView)]) {
        return nil;
    }
    
    NSTextView* textView=[editor textView];
    NSTextStorage* storage=[textView textStorage]; //DVTTextStorage
    NSRange selectedRange=[textView selectedRange];
    id currentMarkRaw=objc_msgSend(storage, @selector(sourceLandmarkAtCharacterIndex:), selectedRange.location);
    
    CMSLandmarkItemWrapper* currentMark=[CMSLandmarkItemWrapper wrapperWithLandmarkItem:currentMarkRaw textView:textView];
    
    if (![currentMark canUseForMethodStyleItem]) {
        return nil;
    }

    id result=[[self alloc]initWithLandmark:currentMark];
    
    return result;
}


- (instancetype)initWithLandmark:(CMSLandmarkItemWrapper*)landmark
{
    self = [super init];
    if (!self) return nil;
    
    _propertyTransform=asGetter;
    _landmark=landmark;
    _valid=YES;
    
    if (![self setupClassName]) {
        _primitiveClassName=@"__CLASSNAME__";
        _decoratedClassName=@"__CLASSNAME__";
    }

    [self parseFirst];

    return self;
}


#pragma mark - parse

- (BOOL)setupClassName
{
    CMSLandmarkItemWrapper* parent=[_landmark parentWrapper];
    if (!parent) {
        return NO;
    }
    
    NSString* parentName=[parent name];
    if (![parentName hasPrefix:@"@"]) {
        return NO;
    }
    NSArray* words=[CMSUtil slice:parentName by:@" "];
    if ([words count]!=2) {
        return NO;
    }
    
    _decoratedClassName=[words objectAtIndex:1];
    NSRange range=[_decoratedClassName rangeOfString:@"("];
    if (range.length) {
        _primitiveClassName=[_decoratedClassName substringToIndex:range.location];
    }else{
        _primitiveClassName=_decoratedClassName;
    }
    
    return YES;
}


- (void)parseFirst
{
    NSString* text=[_landmark text];
    if ([text length]<=1) {
        _valid=NO;
        return;
    }
    
    //erace semicolon
    if ([text hasSuffix:@";"]) {
        text=[text substringToIndex:[text length]-1];
    }
    
    //erase tab
    text=[text stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
    
    _rawText=text;
    
    if ([text hasPrefix:@"@property"]) {
        _propertyDeclaration=YES;
        _prefix=@"-";
    }else{
        _propertyDeclaration=NO;
        _prefix=[text substringToIndex:1];
    }
}

#pragma mark -

- (NSString*)methodReturnType
{
    if (_propertyDeclaration) {
        return [CMSUtil propertyReturnType:_rawText];
    }else{
        return [CMSUtil methodReturnType:_rawText];
    }
}


- (NSString*)methodSelectorName
{
    if (_propertyDeclaration) {
        if (_propertyTransform==asSetter) return [CMSUtil propertySelectorNameSetter:_rawText];
        return [CMSUtil propertySelectorNameGetter:_rawText];
    }else{
        return [CMSUtil methodSelectorName:_rawText];
    }
}


- (NSArray*)methodParameters
{
    if (_propertyDeclaration) {
        if(_propertyTransform==asSetter) return @[[CMSUtil propertyParameterSetter:_rawText addingName:NO]];
        return @[];
    }else{
        return [CMSUtil methodParameters:_rawText addingName:NO];
    }
}


- (NSArray*)methodParametersAddingName
{
    if (_propertyDeclaration) {
        if(_propertyTransform==asSetter) return @[[CMSUtil propertyParameterSetter:_rawText addingName:YES]];
        return @[];
    }else{
        return [CMSUtil methodParameters:_rawText addingName:YES];
    }
}


- (NSArray*)methodParameterNames
{
    if (_propertyDeclaration) {
        if(_propertyTransform==asSetter) return @[[CMSUtil propertyParameterName:_rawText]];
        return @[];
    }else{
        return [CMSUtil methodParameterNames:_rawText];
    }
}





#pragma mark - action


- (void)writeStringToPasteboard:(NSString*)string
{
    if ([string length]<=0) {
        return;
    }
    
    NSPasteboard* pb=[NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString:string forType:NSPasteboardTypeString];
}


- (NSMenu*)submenuForContextMenu
{

#define addMenuItem(menu, title, sel) ({NSMenuItem* addedItem=[menu addItemWithTitle:title action:sel keyEquivalent:@""]; addedItem.target=self; addedItem.enabled=YES; addedItem;})
#define addMenuItemLabel(menu, title) ({NSMenuItem* addedItem=[menu addItemWithTitle:title action:nil keyEquivalent:@""]; addedItem.enabled=NO; addedItem;})
#define alternate(itm) itm.alternate=YES; itm.keyEquivalentModifierMask=NSAlternateKeyMask
    
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@"Copy Method Style"];
    NSMenuItem* itm;
    
    menu.autoenablesItems=NO;
    
    itm=addMenuItem(menu, _primitiveClassName, @selector(actCopyPrimitiveClassName:));

    
    if (![_primitiveClassName isEqualToString:_decoratedClassName]) {
        itm=addMenuItem(menu, _decoratedClassName, @selector(actCopyDecoratedClassName:));
        alternate(itm);
    }
    
    NSString* title=_rawText;
    if ([title length]>46) {
        title=[[title substringToIndex:44]stringByAppendingString:@"..."];
    }
    itm=addMenuItem(menu, title, @selector(actCopyRawText:));
    
    //so that survive until menu tracking ends
    [itm setRepresentedObject:self];
    
    
    [menu addItem:[NSMenuItem separatorItem]];

    if (_propertyDeclaration) {
        addMenuItemLabel(menu, @"getter");
    }
    
    itm=addMenuItem(menu, @"selector", @selector(actCopySelector:));
    if (kUseSymbolicBreakpoint) {
        itm=addMenuItem(menu, @"Symbolic Breakpoint", @selector(actCopySymbolicBreakpoint:));
        alternate(itm);
    }
    
    if (kUseNSSelectorFromString) {
        itm=addMenuItem(menu, @"NSSelectorFromString()", @selector(actCopySelectorWithNS:));
        itm=addMenuItem(menu, @"@selector()", @selector(actCopySelectorWithAt:));
        alternate(itm);
    }else{
        itm=addMenuItem(menu, @"@selector()", @selector(actCopySelectorWithAt:));
        itm=addMenuItem(menu, @"NSSelectorFromString()", @selector(actCopySelectorWithNS:));
        alternate(itm);
    }
    [menu addItem:[NSMenuItem separatorItem]];
    
    itm=addMenuItem(menu, @"objc_msgSend()", @selector(actCopyObjcMsgSend:));
    itm=addMenuItem(menu, @"objc_msgSend() with Check", @selector(actCopyObjcMsgSendWithCheck:));
    alternate(itm);
    if (kUseKZRMethodSwizzling) {
        itm=addMenuItem(menu, @"KZRMethodSwizzling", @selector(actCopyMethodSwizzling:));
    }

    
    if (_propertyDeclaration) {
        [menu addItem:[NSMenuItem separatorItem]];
        addMenuItemLabel(menu, @"setter");
        
        itm=addMenuItem(menu, @"selector", @selector(actCopySelectorSetter:));
        if (kUseSymbolicBreakpoint) {
            itm=addMenuItem(menu, @"Symbolic Breakpoint", @selector(actCopySymbolicBreakpointSetter:));
            alternate(itm);
        }
        
        if (kUseNSSelectorFromString) {
            itm=addMenuItem(menu, @"NSSelectorFromString()", @selector(actCopySelectorWithNSSetter:));
            itm=addMenuItem(menu, @"@selector()", @selector(actCopySelectorWithAtSetter:));
            alternate(itm);
        }else{
            itm=addMenuItem(menu, @"@selector()", @selector(actCopySelectorWithAtSetter:));
            itm=addMenuItem(menu, @"NSSelectorFromString()", @selector(actCopySelectorWithNSSetter:));
            alternate(itm);
        }
        [menu addItem:[NSMenuItem separatorItem]];

        itm=addMenuItem(menu, @"objc_msgSend()", @selector(actCopyObjcMsgSendSetter:));
        itm=addMenuItem(menu, @"objc_msgSend() with Check", @selector(actCopyObjcMsgSendWithCheckSetter:));
        alternate(itm);
        if (kUseKZRMethodSwizzling) {
            itm=addMenuItem(menu, @"KZRMethodSwizzling", @selector(actCopyMethodSwizzlingSetter:));
        }
    }

    return menu;
    
#undef addMenuItem
#undef addMenuItemLabel
#undef alternate
}


// ClassName
- (void)actCopyPrimitiveClassName:(NSMenuItem*)sender
{
    [self writeStringToPasteboard:_primitiveClassName];
}


// ClassName(Category)
- (void)actCopyDecoratedClassName:(NSMenuItem*)sender
{
    [self writeStringToPasteboard:_decoratedClassName];
}

// -(id)selector:(id)val... / @property ...
- (void)actCopyRawText:(NSMenuItem*)sender
{
    [self writeStringToPasteboard:_rawText];
}

// selector:name: / getter
- (void)actCopySelector:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self methodSelectorName];
    [self writeStringToPasteboard:str];
}


//setter:
- (void)actCopySelectorSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self methodSelectorName];
    [self writeStringToPasteboard:str];
}


// @selector(selector:name: / getter)
- (void)actCopySelectorWithAt:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self methodSelectorName];
    str=[NSString stringWithFormat:@"@selector(%@)", str];
    [self writeStringToPasteboard:str];
}


// @selector(setter:)
- (void)actCopySelectorWithAtSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self methodSelectorName];
    str=[NSString stringWithFormat:@"@selector(%@)", str];
    [self writeStringToPasteboard:str];
    
}

// @NSSelectorFromString(@"selector:name: / getter")
- (void)actCopySelectorWithNS:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self methodSelectorName];
    str=[NSString stringWithFormat:@"NSSelectorFromString(@\"%@\")", str];
    [self writeStringToPasteboard:str];
}

// @NSSelectorFromString(@"selector:name: / setter")
- (void)actCopySelectorWithNSSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self methodSelectorName];
    str=[NSString stringWithFormat:@"NSSelectorFromString(@\"%@\")", str];
    [self writeStringToPasteboard:str];
}

// ((id(*)(id, SEL, ...))objc_msgSend)(id, SEL, ...)
- (void)actCopyObjcMsgSend:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self objcMsgSendStringWithCheckResponds:NO];
    [self writeStringToPasteboard:str];
}

// if([id respondsToSelector:SEL]){objc_msgSend(...)}
- (void)actCopyObjcMsgSendWithCheck:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self objcMsgSendStringWithCheckResponds:YES];
    [self writeStringToPasteboard:str];
}

// ((id(*)(id, SEL, ...))objc_msgSend)(id, SEL, ...)
- (void)actCopyObjcMsgSendSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self objcMsgSendStringWithCheckResponds:NO];
    [self writeStringToPasteboard:str];
}

// if([id respondsToSelector:SEL]){objc_msgSend(...)}
- (void)actCopyObjcMsgSendWithCheckSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self objcMsgSendStringWithCheckResponds:YES];
    [self writeStringToPasteboard:str];
}


- (NSString*)objcMsgSendStringWithCheckResponds:(BOOL)addCheck
{
    NSString* returnType=[self methodReturnType];
    NSString* selectr=[self methodSelectorName];
    NSArray* args=[self methodParameters];
    
    
    if (kUseNSSelectorFromString) {
        selectr=[NSString stringWithFormat:@"NSSelectorFromString(@\"%@\")", selectr];
    }else{
        selectr=[NSString stringWithFormat:@"@selector(%@)", selectr];
    }

    args=[CMSUtil alteredArrayWithArray:args usingBlock:^id(id obj) {
        NSString* str=[NSString stringWithFormat:@"<%@(%@)%@>", @"#", obj, @"#"];
        return str;
    }];
    
    NSString* argStr;

    if ([args count]>0) {
        argStr=[args componentsJoinedByString:@", "];
        argStr=[@", " stringByAppendingString:argStr];
    }else{
        argStr=@"";
    }

    NSString* receiverStr=@"id";
    if ([_prefix isEqualToString:@"+"]) {
        receiverStr=@"Class";
    }

    NSString* body=[NSString stringWithFormat:
                    @"((%@(*)(id, SEL, ...))objc_msgSend)(<%@(%@)%@>, %@%@)",
                    returnType,
                    @"#", receiverStr, @"#",
                    selectr,
                    argStr
                    ];
    
    if (addCheck) {

        body=[NSString stringWithFormat:
              @"if ([<%@(%@)%@> respondsToSelector:%@]) {\n"
              @"    %@;\n"
              @"}\n",
              @"#", receiverStr, @"#",
              selectr,
              body
              ];
    }
    
    return body;
}

// KZRMETHOD_SWIZZLING_
- (void)actCopyMethodSwizzling:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self methodSwizzlingString];
    [self writeStringToPasteboard:str];
}

// KZRMETHOD_SWIZZLING_ setter
- (void)actCopyMethodSwizzlingSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self methodSwizzlingString];
    [self writeStringToPasteboard:str];
}

- (NSString*)methodSwizzlingString
{
    NSString* returnType=[self methodReturnType];
    NSString* selectr=[self methodSelectorName];
    
    NSArray* args=[self methodParameterNames];
    NSArray* params=[self methodParametersAddingName];
    NSString* argStr;
    NSString* paramStr;
    NSString* resultStr=@"";
    NSString* returnResultStr=@"";
    NSString* returnTypeStr=@"";
    
    if ([args count]>0) {
        argStr=[args componentsJoinedByString:@", "];
        argStr=[@", " stringByAppendingString:argStr];
    }else{
        argStr=@"";
    }
    if ([params count]>0) {
        paramStr=[params componentsJoinedByString:@", "];
        paramStr=[@", " stringByAppendingString:paramStr];
    }else{
        paramStr=@"";
    }


    if (![returnType isEqualToString:@"void"]) {
        resultStr=[NSString stringWithFormat:@"%@ %@=", returnType, kKZRMethodSwizzlingResultName];
        returnResultStr=[NSString stringWithFormat:@"return %@;", kKZRMethodSwizzlingResultName];
        returnTypeStr=returnType;
        
    }else{
        returnTypeStr=@"";
    }
    
    if ([_prefix isEqualToString:@"+"]) {
        selectr=[_prefix stringByAppendingString:selectr];
    }
    
    NSString* body=[NSString stringWithFormat:
                    @"KZRMETHOD_SWIZZLING_(\"%@\", \"%@\",\n"
                    @"                     %@, %@, %@)\n"
                    @"^%@(id %@%@)\n"
                    @"{\n"
                    @"    %@%@(%@, %@%@);\n"
                    @"    %@\n"
                    @"}_WITHBLOCK;\n",
                    _primitiveClassName, selectr,
                    returnType, kKZRMethodSwizzlingIMPName, kKZRMethodSwizzlingSELName,
                    returnTypeStr, kKZRMethodSwizzlingSelfName, paramStr,
                    resultStr, kKZRMethodSwizzlingIMPName, kKZRMethodSwizzlingSelfName, kKZRMethodSwizzlingSELName,argStr,
                    returnResultStr
                    ];
    
    return body;

}


// KZRMETHOD_SWIZZLING_
- (void)actCopySymbolicBreakpoint:(NSMenuItem*)sender
{
    _propertyTransform=asGetter;
    NSString* str=[self symbolicBreakpointString];
    [self writeStringToPasteboard:str];
}

// KZRMETHOD_SWIZZLING_ setter
- (void)actCopySymbolicBreakpointSetter:(NSMenuItem*)sender
{
    _propertyTransform=asSetter;
    NSString* str=[self symbolicBreakpointString];
    [self writeStringToPasteboard:str];
}

- (NSString*)symbolicBreakpointString
{
    NSString* selectr=[self methodSelectorName];
    NSString* str=[NSString stringWithFormat:@"%@[%@ %@]", _prefix, _decoratedClassName, selectr];
    return str;
}
@end
