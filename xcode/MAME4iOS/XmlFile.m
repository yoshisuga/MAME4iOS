//
//  XmlFile.m
//  Wombat
//
//  Created by ToddLa on 4/4/21.
//
//  Based on http://troybrant.net/blog/2010/09/simple-xml-to-nsdictionary-converter/
//
#import "XmlFile.h"

#if !__has_feature(objc_arc)
#error("This file assumes ARC")
#endif

#define DebugLog 0
#if DebugLog == 0 || !defined(DEBUG)
#define NSLog(...) (void)0
#endif

static NSString *const kTextNodeKey = @"text";

@interface XmlFile (Internal) <NSXMLParserDelegate>

- (NSDictionary *)dictionaryWithStream:(NSInputStream *)stream error:(NSError **)errorPointer;

@end

@implementation XmlFile
{
    NSMutableArray*     dictionaryStack;
    NSMutableString*    textInProgress;
}

#pragma mark Public methods

+ (NSDictionary *)dictionaryWithStream:(NSInputStream *)stream error:(NSError **)error
{
    return [[[self alloc] init] dictionaryWithStream:stream error:error];
}

+ (NSDictionary *)dictionaryWithData:(NSData *)data error:(NSError **)error
{
    return [self dictionaryWithStream:[[NSInputStream alloc] initWithData:data] error:error];
}

+ (NSDictionary *)dictionaryWithURL:(NSURL *)url error:(NSError **)error
{
    return [self dictionaryWithStream:[[NSInputStream alloc] initWithURL:url] error:error];
}

+ (NSDictionary *)dictionaryWithPath:(NSString *)path error:(NSError **)error
{
    return [self dictionaryWithURL:[NSURL fileURLWithPath:path] error:error];
}

+ (void)downloadURL:(NSURL*)url completionHandler:(void (^)(NSURL* url, NSURLResponse* response, NSError* error))handler
{
    if ([url isFileURL])
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{handler(url, nil, nil);});
    else
        [[NSURLSession.sharedSession downloadTaskWithURL:url completionHandler:handler] resume];
}

+ (void)loadUrl:(NSURL*)url completionHandler:(void (^)(NSDictionary* dict, NSError* error)) handler
{
    [self downloadURL:url completionHandler:^(NSURL* url, NSURLResponse* response, NSError* error) {
        NSParameterAssert(![NSThread isMainThread]);
        NSDictionary* dict = (url && error == nil) ? [XmlFile dictionaryWithURL:url error:&error] : nil;
        handler(dict, error);
    }];
}

#pragma mark Parsing

- (NSDictionary *)dictionaryWithStream:(NSInputStream *)stream error:(NSError **)error
{
    dictionaryStack = [[NSMutableArray alloc] init];
    textInProgress = [[NSMutableString alloc] init];

    // Initialize the stack with a fresh dictionary
    [dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithStream:stream];
    parser.delegate = self;
    BOOL success = [parser parse];
    
    if (error)
        *error = [parser parserError];
    
    // Return the stack’s root dictionary on success
    if (success)
        return [dictionaryStack objectAtIndex:0];

    NSLog(@"XML PARSE ERROR: line=%d %@", (int)parser.lineNumber, [parser parserError]);
    return nil;
}

#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSLog(@"START: %@ %@", elementName, attributeDict);
    
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [dictionaryStack lastObject];
    
    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionaryWithDictionary:attributeDict];

    // If there’s already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn’t exist
            array = [NSMutableArray array];
            [array addObject:existingValue];
            
            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
    }
    
    // Update the stack
    [dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSLog(@"END: %@", elementName);
    
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = [dictionaryStack lastObject];

    // Pop the current dict
    [dictionaryStack removeLastObject];
    
    NSString* text = @"";
    
    if (textInProgress.length != 0) {
        // Get rid of leading + trailing whitespace
        text = [textInProgress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Reset the text
        textInProgress = [[NSMutableString alloc] init];
    }
    
    // convert empty dictionary to a string
    if ([dictInProgress count] == 0)
    {
        NSMutableDictionary* parentDict = [dictionaryStack lastObject];
        
        if (parentDict[elementName] == dictInProgress)
        {
             parentDict[elementName] = text;
        }
        else if ([parentDict[elementName] isKindOfClass:[NSMutableArray class]])
        {
            NSMutableArray* parentArray = parentDict[elementName];
            parentArray[[parentArray count]-1] = text;
        }
    }
    // Set the text property
    else if ([text length] > 0)
    {
        [dictInProgress setObject:text forKey:kTextNodeKey];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSLog(@"STRING: '%@'", string);

    // Build the text value
    [textInProgress appendString:string];
}

@end
