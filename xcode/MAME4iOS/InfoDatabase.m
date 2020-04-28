//
//  InfoDatabase.m
//  MAME4iOS
//
//  Created by Todd Laney on 4/24/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import "InfoDatabase.h"

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

//
// the index maps a key to a NSNumber containing the offset in the file and the
// length of the text packed into a uint64. NSNumber uses [tagged pointers](https://en.wikipedia.org/wiki/Tagged_pointer)
// so this should be memory efficient and fast too.
//
#define SIZE_MASK       0x1FFFF  // is 128K enough text? I hope so! 64K is not enough!

@implementation InfoDatabase {
    NSDictionary<NSString*, NSNumber*>* _index;
    NSString* _path;
}

- (instancetype)initWithPath:(NSString*)path
{
    if (self = [super init])
    {
        _path = path;
        _index = nil;
        [self loadIndex];
    }
    return self;
}

- (NSArray<NSString*>*)allKeys
{
    return [_index allKeys];
}

- (uint64_t)intForKey:(NSString*)key
{
    return [[_index objectForKey:key] longLongValue];
}

- (BOOL)boolForKey:(NSString*)key
{
    return [self intForKey:key] != 0;
}

- (NSString*)stringForKey:(NSString*)key
{
    uint64_t u64 = [self intForKey:key];
    uint64_t offset = u64 / (SIZE_MASK+1);
    size_t size = u64 & SIZE_MASK;

    if (offset == 0 || size == 0)
        return nil;
    
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:_path];
    [file seekToFileOffset:offset];
    NSData* data = [file readDataOfLength:size];
    
    NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    text = [text stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return text;
}

//
// text in a MAME INFO .DAT file is "markdown like" so we try to do some simple conversions....
//
// - HEADER 1 -
// * HEADER 2:
// HEADER 3:
// [header]
//
// BOLD: more text
// BOLD1 BOLD2: more text
//* BOLD: more text
//
// - BOLD: list item
// - List item
// * list item
// 1. list item
// 2a. list item
// 1) list item
// a) list item
// 05 - list
//
- (NSAttributedString*)attributedStringForKey:(NSString*)key attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs
{
    NSString* raw_text = [self stringForKey:key];
    
    if (raw_text == nil)
        return nil;
    
    NSDictionary* body = attrs;
    
    UIFont *boldFont = [UIFont systemFontOfSize:[body[NSFontAttributeName] pointSize] weight:UIFontWeightHeavy];
    NSDictionary* bold = @{NSFontAttributeName:boldFont, NSForegroundColorAttributeName:[UIColor colorWithWhite:0.777 alpha:1.0]};
    NSDictionary* h1 = @{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline], NSForegroundColorAttributeName:UIColor.whiteColor};
    NSDictionary* h2 = h1;
    NSDictionary* h3 = h1;
    
    CGSize size = [@"•••" sizeWithAttributes:bold];
    
    NSMutableParagraphStyle *paragraphStyle;
    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.tabStops = @[[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:size.width options:@{}]];
    paragraphStyle.defaultTabInterval = size.width;
    paragraphStyle.headIndent = size.width;
    paragraphStyle.firstLineHeadIndent = 0;
    paragraphStyle.paragraphSpacing = size.height * 0.25;
    
    NSDictionary* list = @{
        NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
        NSParagraphStyleAttributeName: paragraphStyle
    };

    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:raw_text attributes:body];

    // we cant click on links so remove this all together
    [self modifyText:text pattern:@"^- CONTRIBUTE -\\s+?Edit this entry: https:.+?$" string:@""];

    // lines followed by blank line.
    [self modifyText:text pattern:@"^[A-Za-z].{1,30}(\\n\\n)(?=[A-Za-z].{1,30}$)" attributes:@[@{}, @"\n"]];
    [self modifyText:text pattern:@"^[\\-\\*] .+?(\\n\\n)(?=[\\-\\*] )" attributes:@[@{}, @"\n"]];
    [self modifyText:text pattern:@"^[0-9]\\. .+?(\\n\\n)(?=[0-9]\\. )"     attributes:@[@{}, @"\n"]];

    // HEADERS
    [self modifyText:text pattern:@"^(- )(.+?)( - {0,1})$"   attributes:@[h1, @"", @{}, @""]];
    [self modifyText:text pattern:@"^(\\* {0,1})(.+?)(: {0,1})$"  attributes:@[h2, @"", @{}, @""]];
    [self modifyText:text pattern:@"^(\\[)(.+?)(\\] {0,1})$" attributes:@[h3, @"", @{}, @""]];
    [self modifyText:text pattern:@"^(.+?)(: {0,1})$"        attributes:@[h3, @{}, @""]];
    
    // BOLD
    [self modifyText:text pattern:@"^(\\* )(.+?)(:).+?$"    attributes:@[@{}, @"", bold, @""]];
    [self modifyText:text pattern:@"^(\\w+?)( ?:) "         attributes:@[bold, @{}, @""]];
    [self modifyText:text pattern:@"^(\\w+? \\w+?)( ?:) "   attributes:@[bold, @{}, @""]];

    // LISTS
    [self modifyText:text pattern:@"^(\\- )(.+?)(: +).+?$"      attributes:@[list, @"", bold, @" "]];
    [self modifyText:text pattern:@"^([\\-\\*] ).+?$"              attributes:@[list, @"•\t"]];
    [self modifyText:text pattern:@"^([0-9]{1,2}[a-z]?[\\.\\)] +).+?$"    attributes:@[list, @"•\t"]];
    [self modifyText:text pattern:@"^([0-9]{1,2})( - ).+?$" attributes:@[list, bold, @"\t"]];

    return text;
}

- (void)modifyText:(NSMutableAttributedString*)text pattern:(NSString *)pattern attributes:(NSArray*)attributes
{
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionAnchorsMatchLines error:nil];
    
    NSAssert(regex.numberOfCaptureGroups+1 == attributes.count, @"Bad pattern, attribute array must contain a item for each capture group, and entire match");
    
    NSArray* matches = [regex matchesInString:text.string options:0 range:(NSRange){0, text.string.length}];
    
    // walk matched backward, so indices stay valid.
    for (NSTextCheckingResult *match in [[matches reverseObjectEnumerator] allObjects]) {
         // apply the first attribute (for the whole match) first, then the capture groups backward.
         for (NSUInteger i = 0; i < attributes.count; i++)
         {
             NSUInteger n = (i==0) ? 0 : (int)attributes.count-i;
             id attr = attributes[n];
             NSRange range = [match rangeAtIndex:n];
             
             // apply attributes, or set text, empty attribue means ignore.
             if ([attr isKindOfClass:[NSString class]])
                 [text replaceCharactersInRange:range withString:attr];
             else if ([attr count] != 0)
                 [text addAttributes:attr range:range];
         }
     }
}
- (void)modifyText:(NSMutableAttributedString*)text pattern:(NSString *)pattern attribute:(NSDictionary*)attribute
{
    return [self modifyText:text pattern:pattern attributes:@[attribute]];
}
- (void)modifyText:(NSMutableAttributedString*)text pattern:(NSString *)pattern string:(NSString*)string
{
    return [self modifyText:text pattern:pattern attributes:@[string]];
}

#pragma mark - load or create index

- (void)loadIndex
{
    // TODO: I was gonna cache the index on disk, and rebuild it if file changed, but I am seeing at most 2sec to create index, SO SHIP IT!

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0), ^{
        NSDictionary* index = [self createIndex];
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_index = index;
#ifdef DEBUG    // write out a filtered HISTORY.DAT for only the 139u1 ROMS.
            extern NSDictionary* g_category_dict;
            NSString* path = [self->_path stringByReplacingOccurrencesOfString:@".dat" withString:@"139.dat"];
            [self saveDatabaseToPath:path keys:g_category_dict.allKeys];
#endif
        });
    });
}

- (NSDictionary*)createIndex
{
    FILE* file = fopen([_path UTF8String], "r");
    
    if (file == NULL)
        return nil;
    
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];

    NSMutableDictionary* index = [[NSMutableDictionary alloc] init];
    
    char line[4096];

    while (fgets(line, sizeof(line), file) != NULL)
    {
        size_t len = strlen(line);
        if (line[len-1] == '\n') line[len-1] = '\0';
        if (line[len-2] == '\r') line[len-2] = '\0';
        
        if (line[0] == '\0')
            continue;
        
        if (line[0] == '$' && strncmp(line, "$info=", 6) == 0)
        {
            NSString* keys = [NSString stringWithUTF8String:line+6];
            fgets(line, sizeof(line), file);

            uint64_t offset = ftell(file);
            while (fgets(line, sizeof(line), file) != NULL)
            {
                if (strncmp(line, "$end", 4) == 0)
                    break;
            }
            size_t size = ftell(file) - offset - strlen(line);
            NSParameterAssert((size & ~SIZE_MASK) == 0);
            size = MIN(size, SIZE_MASK);
            
            uint64_t u64 = (size & SIZE_MASK) | (offset * (SIZE_MASK+1));
            
            for (NSString* key in [keys componentsSeparatedByString:@","]) {
                NSString* k = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([k length] != 0) {
                    [index setValue:@(u64) forKey:k];
                }
            }
        }
    }
    
    time = [NSDate timeIntervalSinceReferenceDate] - time;
    NSLog(@"InfoDatabase:createIndex: %@ took %.1fsec to load %d items", _path.lastPathComponent, time, (int)index.allKeys.count);

    fclose(file);
    return index;
}


#pragma mark - Save a custom .DAT file for a set of ROMs

#ifdef DEBUG

static void write_string(NSFileHandle* file, NSString* string) {
    [file writeData:[[string stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}
    
-(void)saveDatabaseToPath:(NSString*)path keys:(NSArray*)keys {

    if (_index.count == 0)
        return;
    
    if (keys == nil)
        keys = [self allKeys];

    NSLog(@"%d KEYS, %d TOTAL", (int)keys.count, (int)self.allKeys.count);
    
    NSMutableSet* output_keys = [[NSMutableSet alloc] init];
    NSInteger output_count = 0;
    NSInteger output_size = 0;

    [NSFileManager.defaultManager createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:path];
    
    for (NSString* key in keys) @autoreleasepool {{
        
        if ([output_keys containsObject:key])
            continue;
        
        if (![self boolForKey:key]) {
            NSLog(@"*** INFO FOR %@ NOT FOUND", key);
            continue;
        }
        NSMutableSet* duplicate_keys = [[NSMutableSet alloc] init];
        NSString* text = [self stringForKey:key];
        uint64_t text_id  = [self intForKey:key];
 
        // walk the whole list again looking for duplicates, can you say O(N^2)!
        for (NSString* key in keys) @autoreleasepool {{
            if ([self intForKey:key] == text_id)
                [duplicate_keys addObject:key];
        }}
        
        [output_keys unionSet:duplicate_keys];
        output_count += 1;
        output_size += text.length;
        
        NSLog(@"    INFO: %@", [duplicate_keys.allObjects componentsJoinedByString:@","]);
        
        write_string(file, [NSString stringWithFormat:@"$info=%@,", [duplicate_keys.allObjects componentsJoinedByString:@","]]);
        write_string(file, @"$bio");
        write_string(file, text);
        write_string(file, @"$end");
    }}
    
    NSLog(@"INFO: %d keys, %d entries, %d size",(int)output_keys.count, (int)output_count, (int)output_size);
}
#endif

@end


