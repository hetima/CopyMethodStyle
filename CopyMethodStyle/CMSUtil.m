//
//  CMSUtil.m
//  CopyMethodStyle


#import "CMSUtil.h"

@implementation CMSUtil


+ (NSString*)trim:(NSString*)text
{
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (NSString*)lastWord:(NSString*)text
{
    
    NSRange sep=[text rangeOfString:@" " options:NSBackwardsSearch];
    if (sep.length>0) {
        text=[text substringFromIndex:sep.location+1];
    }
    
    sep=[text rangeOfString:@"*" options:NSBackwardsSearch];
    if (sep.length>0) {
        text=[text substringFromIndex:sep.location+1];
    }
    
    sep=[text rangeOfString:@")" options:NSBackwardsSearch];
    if (sep.length>0) {
        text=[text substringFromIndex:sep.location+1];
    }

    return text;
}

+ (NSArray*)slice:(NSString*)text by:(NSString*)separator
{
    NSMutableArray* ary=[[NSMutableArray alloc]init];
    NSArray* items=[text componentsSeparatedByString:separator];
    for (NSString* item in items) {
        NSString* trimedItem=[CMSUtil trim:item];
        if ([trimedItem length]>0) {
            [ary addObject:trimedItem];
        }
    }
    

    return ary;
}


+ (NSString*)stringInFirstParenthesis:(NSString*)text
{
    NSArray* items=[CMSUtil slice:text by:@"("];
    if ([items count]>=2) {
        NSString* item=items[1];
        items=[CMSUtil slice:item by:@")"];
        item=[items firstObject];
        
        return item;
    }
    
    return nil;
}


+ (NSArray*)alteredArrayWithArray:(NSArray*)array usingBlock:(id (^)(id obj))block
{
    NSMutableArray* alteredArray=[[NSMutableArray alloc]initWithCapacity:[array count]];
    for (id obj in array) {
        id result=block(obj);
        if (result) {
            [alteredArray addObject:result];
        }
    }
    return alteredArray;
}


#pragma mark -

+ (NSString*)methodSelectorName:(NSString*)text
{
    __block NSMutableArray* ary=[[NSMutableArray alloc]init];
    NSArray* items=[CMSUtil slice:text by:@":"];
    
    if ([items count]==0){
        return nil;
    }
    
    if ([items count]==1){
        NSString* name=[CMSUtil lastWord:[items firstObject]];
        return name;
    }
    
    NSInteger lastItem=[items count]-1;
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx>=lastItem) {
            return;
        }
        NSString* name=[CMSUtil lastWord:obj];

        name=[name stringByAppendingString:@":"];
        
        [ary addObject:name];
    }];
    
    return [ary componentsJoinedByString:@""];
}


+ (NSString*)methodReturnType:(NSString*)text
{
    return [CMSUtil stringInFirstParenthesis:text];
}


+ (NSArray*)methodParameters:(NSString*)text addingName:(BOOL)addName
{

    __block NSMutableArray* ary=[[NSMutableArray alloc]init];
    NSRange range;
    
    range=[text rangeOfString:@":"];
    if (range.length==0) {
        return ary;
    }

    NSArray* items=[CMSUtil slice:text by:@":"];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx<=0 || ![obj hasPrefix:@"("]) {
            return;
        }
        
        NSRange paramEnd=[obj rangeOfString:@")" options:NSBackwardsSearch];
        if (paramEnd.length==0) {
            return;
        }
        
        NSString* param=[obj substringWithRange:NSMakeRange(1, paramEnd.location-1)];
        
        if (addName) {
            NSString* remain=[obj substringFromIndex:paramEnd.location+1];
            NSString* name=name=[[CMSUtil slice:remain by:@" "]firstObject];
            
            if (![param hasSuffix:@"*"]) {
                param=[param stringByAppendingString:@" "];
            }
            param=[param stringByAppendingString:name];
            
        }
        [ary addObject:param];
    }];

    return ary;
}


+ (NSArray*)methodParameterNames:(NSString*)text
{
    __block NSMutableArray* ary=[[NSMutableArray alloc]init];
    NSRange range;
    
    range=[text rangeOfString:@":"];
    if (range.length==0) {
        return ary;
    }
    
    NSArray* items=[CMSUtil slice:text by:@":"];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx<=0 || ![obj hasPrefix:@"("]) {
            return;
        }
        
        NSRange paramEnd=[obj rangeOfString:@")" options:NSBackwardsSearch];
        if (paramEnd.length==0) {
            return;
        }

        NSString* remain=[obj substringFromIndex:paramEnd.location+1];
        NSString* name=[[CMSUtil slice:remain by:@" "]firstObject];

        if ([name length]>0) {
            [ary addObject:name];
        }
    }];
    
    return ary;
}


#pragma mark -

+ (NSString*)propertySelectorNameGetter:(NSString*)text
{
    //getter=
    NSString* option=[CMSUtil stringInFirstParenthesis:text];
    NSArray* options=[CMSUtil slice:option by:@","];
    for (NSString* op in options) {
        NSArray* items=[CMSUtil slice:op by:@"="];
        if ([items count]==2 && [[items firstObject]isEqualToString:@"getter"]) {
            return [items lastObject];
        }
    }

    return [CMSUtil propertyParameterName:text];
}


+ (NSString*)propertySelectorNameSetter:(NSString*)text;
{
    //setter=
    NSString* option=[CMSUtil stringInFirstParenthesis:text];
    NSArray* options=[CMSUtil slice:option by:@","];
    for (NSString* op in options) {
        NSArray* items=[CMSUtil slice:op by:@"="];
        if ([items count]==2 && [[items firstObject]isEqualToString:@"setter"]) {
            return [items lastObject];
        }
    }
    NSString* result=@"set???:";
    
    NSString* name=[CMSUtil propertyParameterName:text];
    
    if ([name length]>0) {
        NSString* head=[[name substringToIndex:1]uppercaseString];
        NSString* body=[name substringFromIndex:1];
        result=[NSString stringWithFormat:@"set%@%@:", head, body];
    }
    
    return result;
}


+ (NSString*)propertyReturnType:(NSString*)text
{
    text=[[CMSUtil slice:text by:@")"]lastObject];

    //remove name
    NSString* name=[CMSUtil lastWord:text];
    NSUInteger index=[text length]-[name length];
    NSString* param=[text substringToIndex:index];
    
    if ([param hasPrefix:@"__"]) {
        param=[param substringFromIndex:[[[param componentsSeparatedByString:@" "]firstObject]length]];
        param=[CMSUtil trim:param];
    }
    if ([param hasPrefix:@"IBOutlet "]) {
        param=[param substringFromIndex:[@"IBOutlet" length]];
        param=[CMSUtil trim:param];
    }

    return param;
}


+ (NSString*)propertyParameterSetter:(NSString*)text addingName:(BOOL)addName
{
    NSString* str=[CMSUtil propertyReturnType:text];
    if (addName) {
        str=[str stringByAppendingFormat:@" %@", [CMSUtil propertySelectorNameGetter:text]];
    }
    return str;
}


+ (NSString*)propertyParameterName:(NSString*)text
{
    NSString* name=[CMSUtil lastWord:text];
    
    return name;
}

@end


