//
//  ChooseGameController.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#import <UIKit/UIKit.h>
#import <GameController/GameController.h>
#import "ChooseGameController.h"
#import "PopupSegmentedControl.h"
#import "ImageCache.h"
#import "SystemImage.h"
#import "InfoDatabase.h"
#import "Alert.h"
#import "Globals.h"

#if TARGET_OS_IOS
#import <Intents/Intents.h>
#import <IntentsUI/IntentsUI.h>
#import "FileItemProvider.h"
#import "ZipFile.h"
#endif

#if TARGET_OS_TV
#import <TVServices/TVServices.h>
#endif

#if !__has_feature(objc_arc)
#error("This file assumes ARC")
#endif

#define DebugLog 0
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

#define CELL_IDENTIFIER   @"GameInfoCell"
#if TARGET_OS_IOS
#define CELL_TINY_WIDTH    100.0
#define CELL_SMALL_WIDTH   200.0
#define CELL_LARGE_WIDTH   400.0
#define CELL_LIST_WIDTH    400.0
#define CELL_INSET_X       8.0
#define CELL_INSET_Y       4.0
#else
#define CELL_TINY_WIDTH    200.0
#define CELL_SMALL_WIDTH   250.0
#define CELL_LARGE_WIDTH   350.0
#define CELL_LIST_WIDTH    600.0
#define CELL_INSET_X       8.0
#define CELL_INSET_Y       4.0
#endif

#define USE_TITLE_IMAGE         TRUE
#define TVOS_PARALLAX           FALSE
#define TITLE_COLOR             [UIColor whiteColor]
#define HEADER_TEXT_COLOR       [UIColor whiteColor]
#define HEADER_BACKGROUND_COLOR [UIColor clearColor]
#define HEADER_PINNED_COLOR     [BACKGROUND_COLOR colorWithAlphaComponent:0.8]

#define CELL_SELECTED_COLOR     [self.tintColor colorWithAlphaComponent:1.0]
#define CELL_SHADOW_COLOR       UIColor.clearColor

#define CELL_CORNER_RADIUS      16.0
#define CELL_BORDER_WIDTH       2.0

#if 0
#define BACKGROUND_COLOR        [UIColor blackColor]
#define CELL_BACKGROUND_COLOR   [UIColor colorWithWhite:0.222 alpha:1.0]
#define CELL_TEXT_ALIGN         NSTextAlignmentLeft
#else
#define BACKGROUND_COLOR        [UIColor colorWithWhite:0.066 alpha:1.0]
#define CELL_BACKGROUND_COLOR   UIColor.clearColor
#define CELL_TEXT_ALIGN         NSTextAlignmentCenter
#endif

#if TARGET_OS_IOS
#define CELL_TITLE_FONT         [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
#define CELL_TITLE_COLOR        [UIColor whiteColor]
#define CELL_DETAIL_FONT        [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
#define CELL_DETAIL_COLOR       [UIColor lightGrayColor]
#else
#define CELL_TITLE_FONT         [UIFont boldSystemFontOfSize:24.0]
#define CELL_TITLE_COLOR        [UIColor whiteColor]
#define CELL_DETAIL_FONT        [UIFont systemFontOfSize:20.0]
#define CELL_DETAIL_COLOR       [UIColor lightGrayColor]
#endif

#define INFO_BACKGROUND_COLOR   [UIColor colorWithWhite:0.111 alpha:1.0]
#define INFO_IMAGE_WIDTH        (TARGET_OS_IOS ? 260.0 : 580.0)
#define INFO_INSET_X            8.0
#define INFO_INSET_Y            8.0

#if TARGET_OS_IOS
#define INFO_TITLE_FONT_SIZE    [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle].pointSize
#else
#define INFO_TITLE_FONT_SIZE    [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize * 2.0
#endif
#define INFO_TITLE_FONT         [UIFont systemFontOfSize:INFO_TITLE_FONT_SIZE weight:UIFontWeightHeavy]
#define INFO_TITLE_COLOR        [UIColor whiteColor]
#define INFO_HEAD_FONT          [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
#define INFO_HEAD_COLOR         [UIColor whiteColor]
#define INFO_BODY_FONT          [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
#define INFO_BODY_COLOR         [UIColor lightGrayColor]

#define HEADER_IDENTIFIER   @"GameInfoHeader"

#define LAYOUT_MODE_KEY     @"LayoutMode"
#define LAYOUT_MODE_DEFAULT LayoutSmall
#define SCOPE_MODE_KEY      @"ScopeMode"
#define SCOPE_MODE_DEFAULT  @"System"
#define ALL_SCOPES          @[@"System", @"Manufacturer", @"Year", @"Genre", @"Driver"]
#define RECENT_GAMES_MAX    8

#define CLAMP(x, num) MIN(MAX(x,0), (num)-1)

typedef NS_ENUM(NSInteger, LayoutMode) {
    LayoutTiny,
    LayoutSmall,
    LayoutLarge,
    LayoutList,
    LayoutCount
};

#pragma mark GameCell

@interface GameCell : UICollectionViewCell
@property (readwrite, nonatomic, strong) UIImageView* image;
@property (readwrite, nonatomic, strong) UILabel* text;
-(void)setHorizontal:(BOOL)horizontal;
-(void)setHeight:(CGFloat)height;
-(void)setTextInsets:(UIEdgeInsets)insets;
-(void)setImageAspect:(CGFloat)aspect;
-(void)setBorderWidth:(CGFloat)width;
-(void)setCornerRadius:(CGFloat)radius;
-(void)setBackgroundColor:(UIColor *)backgroundColor;
-(void)setShadowColor:(UIColor*)color;
-(void)setSelectScale:(CGFloat)scale;
-(void)addBlur:(UIBlurEffectStyle)style;
-(void)startWait;
-(void)stopWait;
@end

#pragma mark GameInfoController

@interface GameInfoController : UICollectionViewController
-(instancetype)initWithGame:(NSDictionary*)game;
@end

#pragma mark shared user defaults

@interface NSUserDefaults(shared)
@property (class, nonatomic, strong, readonly) NSUserDefaults* sharedUserDefaults;
@end

@implementation NSUserDefaults(shared)
+(NSUserDefaults*)sharedUserDefaults {
#if TARGET_OS_MACCATALYST
    // on macOS shared container id must be <TEAMID>.<BUNDLE IDENTIFIER>
    return nil;
#else
    // on iOS shared container must be group.<BUNDLE IDENTIFIER>
    return [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@", NSBundle.mainBundle.bundleIdentifier]];
#endif
}
@end

#pragma mark ChooseGameController

@interface ChooseGameController () <UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate> {
    NSArray* _gameList;         // all games
    NSDictionary* _gameData;    // filtered and separated into sections/scope
    NSArray* _gameSectionTitles;// sorted section names
    NSString* _gameFilterText;  // text string to filter games by
    NSString* _gameFilterScope; // group results by Name,Year,Manufactuer
    NSUInteger _layoutCollums;  // number of collums in current layout.
    NSMutableDictionary* _layoutRowHeightCache; // cache of row heights, we want all items in a row to be same height.
    LayoutMode _layoutMode;
    CGFloat _layoutWidth;
    UISearchController* _searchController;
    NSArray* _key_commands;
    BOOL _searchCancel;
    NSIndexPath* _currentlyFocusedIndexPath;
    UIImage* _defaultImage;
    UIImage* _loadingImage;
    NSMutableSet* _updated_urls;
    NSMutableDictionary* _gameImageSize;
    InfoDatabase* _history;
    InfoDatabase* _mameinfo;
}
@end

@implementation ChooseGameController

+ (NSArray<NSString*>*) allSettingsKeys {
    return @[LAYOUT_MODE_KEY, SCOPE_MODE_KEY, RECENT_GAMES_KEY, FAVORITE_GAMES_KEY];
}

- (instancetype)init
{
    self = [self initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    
    // filter scope
    _gameFilterScope = [NSUserDefaults.standardUserDefaults stringForKey:SCOPE_MODE_KEY];
    
    if (![ALL_SCOPES containsObject:_gameFilterScope])
        _gameFilterScope = SCOPE_MODE_DEFAULT;
    
    // layout mode
    if ([NSUserDefaults.standardUserDefaults objectForKey:LAYOUT_MODE_KEY] == nil)
        _layoutMode = LAYOUT_MODE_DEFAULT;
    else
        _layoutMode = CLAMP([NSUserDefaults.standardUserDefaults integerForKey:LAYOUT_MODE_KEY], LayoutCount);
    
    _defaultImage = [UIImage imageNamed:@"default_game_icon"];
    _loadingImage = [UIImage imageWithColor:[UIColor clearColor] size:CGSizeMake(4, 3)];
    
    // load any INFO databases we might have around.
    NSString *datsPath = [NSString stringWithUTF8String:get_documents_path("dats")];
    _history  = [[InfoDatabase alloc] initWithPath:[datsPath stringByAppendingPathComponent:@"history.dat"]];
    _mameinfo = [[InfoDatabase alloc] initWithPath:[datsPath stringByAppendingPathComponent:@"mameinfo.dat"]];

    return self;
}

- (void)viewDidLoad
{
#if USE_TITLE_IMAGE
    CGFloat height = TARGET_OS_IOS ? 44.0 : (44.0 * 2.0);
    UIImage* image = [[UIImage imageNamed:@"mame_logo"] scaledToSize:CGSizeMake(0.0, height)];
    UIImageView* title = [[UIImageView alloc] initWithImage:image];
#else
    UILabel* title = [[UILabel alloc] init];
    CGFloat height = TARGET_OS_IOS ? (44.0 * 0.6) : (44.0 * 1.5);
    title.text = @PRODUCT_NAME;
    title.font = [UIFont boldSystemFontOfSize:height];
    title.textColor = TITLE_COLOR;
    [title sizeToFit];
#endif

    // put the title on the left, and set center title to nil
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:title];
    self.title = nil;
    
    //navbar
#if TARGET_OS_IOS
    self.navigationController.navigationBar.translucent = YES;
    
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.barTintColor = BACKGROUND_COLOR;
    }
    
    [title addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTop)]];
#else
    self.navigationController.navigationBar.translucent = NO;
#endif
    
    // layout
    height = TARGET_OS_IOS ? 16.0 : 32.0;
    UISegmentedControl* seg1 = [[PopupSegmentedControl alloc] initWithItems:@[
        [UIImage systemImageNamed:@"square.grid.4x3.fill" withPointSize:height]    ?: @"⚏",
        [UIImage systemImageNamed:@"rectangle.grid.2x2.fill" withPointSize:height] ?: @"☷",
        [UIImage systemImageNamed:@"rectangle.stack.fill" withPointSize:height]    ?: @"▢",
        [UIImage systemImageNamed:@"rectangle.grid.1x2.fill" withPointSize:height] ?: @"☰"
    ]];
    
    seg1.selectedSegmentIndex = _layoutMode;
    [seg1 addTarget:self action:@selector(viewChange:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem* layout = [[UIBarButtonItem alloc] initWithCustomView:seg1];

    // group/scope
    UISegmentedControl* seg2 = [[PopupSegmentedControl alloc] initWithItems:ALL_SCOPES];
    seg2.selectedSegmentIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
    seg2.apportionsSegmentWidthsByContent = TARGET_OS_IOS ? NO : YES;
    seg2.autoresizingMask = UIViewAutoresizingFlexibleHeight;   // make vertical menu always.
    [seg2 addTarget:self action:@selector(scopeChange:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem* scope = [[UIBarButtonItem alloc] initWithCustomView:seg2];
    
    // settings
    UIImage* settingsImage = [UIImage systemImageNamed:@"gear" withPointSize:height] ?: [[UIImage imageNamed:@"menu"] scaledToSize:CGSizeMake(height, height)];
#if TARGET_OS_TV
    UIBarButtonItem* settings = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
#else
    UISegmentedControl* seg3 = [[UISegmentedControl alloc] initWithItems:@[settingsImage]];
    seg3.momentary = YES;
    [seg3 addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem* settings = [[UIBarButtonItem alloc] initWithCustomView:seg3];
#endif
    
    self.navigationItem.rightBarButtonItems = @[settings, layout, scope];

#if TARGET_OS_IOS
    if (@available(iOS 13.0, *)) {
        UISegmentedControl* appearance = [UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]];
        appearance.selectedSegmentTintColor = self.view.tintColor;
    }
#endif

    // Search
#if TARGET_OS_IOS
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.delegate = self;
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.searchBar.placeholder = @"Search";
    
    // make the cancel button say Done
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitle:@"Done"];
 
    self.definesPresentationContext = TRUE;

    // put search in navbar...
    self.navigationItem.searchController = _searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = TRUE;
#else   // tvOS
    if (self.navigationController != nil) {
        // force light-mode so our buttons look good in navbar
        // force dark-mode so the (scope) segmented controll looks good.
        if (@available(tvOS 13.0, *)) {
            self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
            seg1.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            seg2.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
        
        UIBarButtonItem* search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearch)];
        self.navigationItem.rightBarButtonItems = [@[search] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
}
#endif
    
    // attach long press gesture to collectionView (only on pre-iOS 13, and tvOS)
    if (NSClassFromString(@"UIContextMenuConfiguration") == nil) {
        [self.collectionView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)]];
    }
    
    // collection view
    [self.collectionView registerClass:[GameCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER];
    [self.collectionView registerClass:[GameCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HEADER_IDENTIFIER];
    
    self.collectionView.backgroundColor = BACKGROUND_COLOR;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.alwaysBounceVertical = YES;
    
    if (_backgroundImage) {
        self.collectionView.backgroundView = [[UIView alloc] init];
        self.collectionView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:_backgroundImage];
    }
    
 #if TARGET_OS_TV
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuPress)];
    tap.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
    [self.navigationController.view addGestureRecognizer:tap];
#endif
    
#ifdef XDEBUG
    // delete all the cached TITLE images.
    NSString* titles_path = [NSString stringWithUTF8String:get_documents_path("titles")];
    [[NSFileManager defaultManager] removeItemAtPath:titles_path error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:titles_path withIntermediateDirectories:NO attributes:nil error:nil];
    [[ImageCache sharedInstance] flush];
#endif
    [self updateExternal];
}
-(void)scrollToTop
{
#if TARGET_OS_IOS
    [self.collectionView setContentOffset:CGPointMake(0, (self.collectionView.adjustedContentInset.top - _searchController.searchBar.bounds.size.height) * -1.0) animated:TRUE];
#endif
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.collectionView.contentOffset.y <= 0.0)
        [self scrollToTop];
}

#if TARGET_OS_TV
-(void)showSearch
{
    ChooseGameController* resultsController = [[ChooseGameController alloc] init];
    [resultsController setGameList:_gameList];
    resultsController.selectGameCallback = _selectGameCallback;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:resultsController];
    _searchController.searchResultsUpdater = resultsController;
    _searchController.searchBar.delegate = resultsController;
    _searchController.obscuresBackgroundDuringPresentation = YES;

    _searchController.searchBar.scopeButtonTitles = ALL_SCOPES;
    _searchController.searchBar.placeholder = @"Search";
    _searchController.searchBar.showsScopeBar = NO;
    _searchController.hidesNavigationBarDuringPresentation = YES;
    

    //self.definesPresentationContext = TRUE;
    UIViewController* search = [[UISearchContainerViewController alloc] initWithSearchController:_searchController];
    self.navigationController.navigationBarHidden = TRUE;
    if (@available(tvOS 13.0, *)) {
        // force dark-mode so the search controller looks ok!
        search.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    [self.navigationController pushViewController:search animated:YES];
}
#endif

-(void)showSettings
{
    if (_selectGameCallback)
        _selectGameCallback(@{kGameInfoDescription:@"Settings", kGameInfoName:kGameInfoNameSettings});
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (_layoutWidth != self.view.bounds.size.width)
    {
        _layoutWidth = self.view.bounds.size.width;
        [self updateLayout];
    }
}

- (void)setGameList:(NSArray*)games
{
    // add a *special* system game that will run the DOS MAME menu. (only if not already in list)

    if ([games filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kGameInfoName, kGameInfoNameMameMenu]].count == 0)
    {
        games = [games arrayByAddingObject:@{
            kGameInfoName:kGameInfoNameMameMenu,
            kGameInfoParent:@"",
            kGameInfoDescription:@"MAME UI",
            kGameInfoYear:@"2010",
            kGameInfoManufacturer:@"MAME 0.139u1",
        }];
        
        // then (re)sort the list by description
        games = [games sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kGameInfoDescription ascending:TRUE]]];
    }
    
    _gameList = games;
    [self filterGameList];
}

+ (void)reset
{
    // delete the recent and favorite game list(s)
    for (NSString* key in [self allSettingsKeys]) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
        [NSUserDefaults.sharedUserDefaults removeObjectForKey:key];
    }
    
    // delete all the cached TITLE images.
    NSString* titles_path = [NSString stringWithUTF8String:get_documents_path("titles")];
    [[NSFileManager defaultManager] removeItemAtPath:titles_path error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:titles_path withIntermediateDirectories:NO attributes:nil error:nil];
    [[ImageCache sharedInstance] flush];
}

-(void)viewChange:(UISegmentedControl*)sender
{
    NSLog(@"VIEW CHANGE: %d", (int)sender.selectedSegmentIndex);
    _layoutMode = sender.selectedSegmentIndex;
    [NSUserDefaults.standardUserDefaults setInteger:_layoutMode forKey:LAYOUT_MODE_KEY];
    [self updateLayout];
}
-(void)scopeChange:(UISegmentedControl*)sender
{
    NSLog(@"SCOPE CHANGE: %@", ALL_SCOPES[sender.selectedSegmentIndex]);
    _gameFilterScope = ALL_SCOPES[sender.selectedSegmentIndex];
    [NSUserDefaults.standardUserDefaults setValue:_gameFilterScope forKey:SCOPE_MODE_KEY];
    [self filterGameList];
}

#pragma mark - game images

+(NSURL*)getGameImageURL:(NSDictionary*)info
{
    NSString* name = info[kGameInfoDescription];
    
    if (name == nil)
        return nil;

#if 0
    NSString* titleURL = @"http://thumbnails.libretro.com/MAME/Named_Titles";
#else
    NSString* titleURL = @"https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles";
#endif
    
    /// from [libretro docs](https://docs.libretro.com/guides/roms-playlists-thumbnails/)
    /// The following characters in titles must be replaced with _ in the corresponding filename: &*/:`<>?\|
    for (NSString* str in @[@"&", @"*", @"/", @":", @"`", @"<", @">", @"?", @"\\", @"|"])
        name = [name stringByReplacingOccurrencesOfString:str withString:@"_"];
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.png", titleURL,
                                 [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]]];
}
-(NSURL*)getGameImageURL:(NSDictionary*)info
{
    return [[self class] getGameImageURL:info];
}


-(NSURL*)getGameImageLocalURL:(NSDictionary*)info
{
    NSString* name = info[kGameInfoName];
    
    if (name == nil)
        return nil;
    
    if ([self isSystem:info])
        return [[NSBundle mainBundle] URLForResource:name withExtension:@"png"];
    
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%s/%@.png", get_documents_path("titles"), name] isDirectory:NO];
}

-(CGSize)getGameImageSize:(NSDictionary*)info
{
    NSString* name = info[kGameInfoName];
    CGSize size = CGSizeZero;

    if (name == nil)
        return size;
    
    NSValue* val = _gameImageSize[name];
    
    if (val != nil)
        return [val CGSizeValue];
    
    // Apple has a special [PNG format](http://fileformats.archiveteam.org/wiki/CgBI), and Xcode converts all resources!
    if ([self isSystem:info])
        return CGSizeMake(640, 480);
    
    NSURL* url = [self getGameImageLocalURL:info];
    
    if (url == nil)
        return size;
    
    NSFileHandle* file = [NSFileHandle fileHandleForReadingFromURL:url error:nil];

    if (file == nil)
        return size;

    // because we only need the size, directly read the PNG header and get it.
    // [PNG header](https://en.wikipedia.org/wiki/Portable_Network_Graphics#File_header)
    // 0x89 'PNG' \r\n 0x1A \n [13] 'IHDR' [width] [height] (FYI PNG stores integers in big-endian)
    uint8_t png_header[] = {0x89, 'P','N','G', '\r','\n', 0x1A, '\n', 0,0,0,13, 'I','H','D','R'};
    
    NSData* data = [file readDataOfLength:sizeof(png_header) + 4*2];
    const uint8_t* bytes = [data bytes];
    
    if ([data length] == (sizeof(png_header) + 4*2) && memcmp(png_header, bytes, sizeof(png_header)) == 0)
    {
        NSUInteger width  = (NSUInteger)bytes[sizeof(png_header) + 0*4 + 3] + ((NSUInteger)bytes[sizeof(png_header) + 0*4 + 2] << 8);
        NSUInteger height = (NSUInteger)bytes[sizeof(png_header) + 1*4 + 3] + ((NSUInteger)bytes[sizeof(png_header) + 1*4 + 2] << 8);
        size = CGSizeMake(width, height);
    }
    
    // store this size in the cache, so next time we dont need to do any file I/O
    _gameImageSize = _gameImageSize ?: [[NSMutableDictionary alloc] init];
    _gameImageSize[name] = [NSValue valueWithCGSize:size];
    
    return size;
}

#pragma mark - game filter

- (void)filterGameList
{
    NSArray* filteredGames = _gameList;
    
    // filter all games, multiple keywords will be treated as AND, and #### <#### >#### <=#### >=#### will compare years
    if ([_gameFilterText length] > 0)
    {
        for (NSString* word in [_gameFilterText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]])
        {
            NSPredicate* predicate = nil;
            
            if ([word length] == 0)
                continue;

            // handle YEAR comparisions
            for (NSString* op in @[@"=", @"!=", @"<", @">", @">=", @"<="])
            {
                int year = 0;
                if ([word hasPrefix:op] && (year = [[word substringFromIndex:[op length]] intValue]) >= 1970)
                    predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@.intValue %@ %d", kGameInfoYear, op, year]];
            }

            if ([word length] == 4 && [word intValue] >= 1970)
                predicate = [NSPredicate predicateWithFormat:@"%K = %@", kGameInfoYear, word];

            if (predicate == nil)
                predicate = [NSPredicate predicateWithFormat:@"SUBQUERY(SELF.@allValues, $x, $x CONTAINS[cd] %@).@count > 0", word];
            
            filteredGames = [filteredGames filteredArrayUsingPredicate:predicate];
        }
    }
    
    // group games by category into sections
    NSMutableDictionary* gameData = [[NSMutableDictionary alloc] init];
    NSString* key = nil;
    
    if ([_gameFilterScope isEqualToString:@"Year"])
        key = kGameInfoYear;
    if ([_gameFilterScope isEqualToString:@"Manufacturer"])
        key = kGameInfoManufacturer;
    if ([_gameFilterScope isEqualToString:@"Category"])
        key = kGameInfoCategory;
    if ([_gameFilterScope isEqualToString:@"Genre"])
        key = kGameInfoCategory;
    if ([_gameFilterScope isEqualToString:@"Driver"])
        key = kGameInfoDriver;
    if ([_gameFilterScope isEqualToString:@"Parent"])
        key = kGameInfoParent;

    for (NSDictionary* game in filteredGames) {
        NSString* section = key ? (game[key] ?: @"Unknown") : @"Arcade";
        
        // a UICollectionView will scroll like crap if we have too many sections, so try to filter/combine similar ones.
        section = [[section componentsSeparatedByString:@" ("] firstObject];
        section = [section stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (key != (void*)kGameInfoYear)
            section = [section stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
        
        // if we dont have a parent, we are our own parent!
        if (key == (void*)kGameInfoParent && [section length] <= 1)
            section = game[kGameInfoName];

        if (gameData[section] == nil)
            gameData[section] = [[NSMutableArray alloc] init];
        [gameData[section] addObject:game];
    }

    // and sort section names
    NSArray* gameSectionTitles = [gameData.allKeys sortedArrayUsingSelector:@selector(localizedCompare:)];

    // a UICollectionView will scroll like crap if we have too many sections. go through and merge a few
    if ([gameSectionTitles count] > 200) {
        NSLog(@"TOO MANY SECTIONS: %d!", (int)[gameSectionTitles count]);
        
        for (NSUInteger i=0; i<[gameSectionTitles count]-1; i++) {
            NSString* title_0 = gameSectionTitles[i+0];
            NSString* title_1 = gameSectionTitles[i+1];
            
            if ([[title_0 componentsSeparatedByString:@" "] count] == 1 &&
                [[title_1 componentsSeparatedByString:@" "] count] <= 2 ) {
                
                NSString* new_title = [NSString stringWithFormat:@"%@ • %@", title_0, title_1];
                
                NSLog(@"   MERGE '%@' '%@' => '%@'", title_0, title_1, new_title);

                gameData[new_title] = [gameData[title_0] arrayByAddingObjectsFromArray:gameData[title_1]];
                gameData[title_0] = nil;
                gameData[title_1] = nil;
                i++;
            }
        }
        gameSectionTitles = [gameData.allKeys sortedArrayUsingSelector:@selector(localizedCompare:)];
        NSLog(@"SECTIONS AFTER MERGE: %d!", (int)[gameSectionTitles count]);
    }
    
    // add favorite games
    NSArray* favoriteGames = [[NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY]
        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", filteredGames]];
    
    if ([favoriteGames count] > 0) {
        //NSLog(@"FAVORITE GAMES: %@", favoriteGames);
        gameSectionTitles = [@[FAVORITE_GAMES_TITLE] arrayByAddingObjectsFromArray:gameSectionTitles];
        gameData[FAVORITE_GAMES_TITLE] = favoriteGames;
    }

    // load recent games and put them at the top
    NSArray* recentGames = [[NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY]
        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", filteredGames]];

    if ([recentGames count] > RECENT_GAMES_MAX)
        recentGames = [recentGames subarrayWithRange:NSMakeRange(0, RECENT_GAMES_MAX)];

    if ([recentGames count] > 0) {
        //NSLog(@"RECENT GAMES: %@", recentGames);
        gameSectionTitles = [@[RECENT_GAMES_TITLE] arrayByAddingObjectsFromArray:gameSectionTitles];
        gameData[RECENT_GAMES_TITLE] = recentGames;
    }
    
    _gameSectionTitles = gameSectionTitles;
    _gameData = gameData;

    if (self.isViewLoaded) {
        [self reloadData];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    UISearchBar* searchBar = searchController.searchBar;
    
    NSLog(@"SEARCH: [%@] '%@' active=%d cancel=%d", searchBar.scopeButtonTitles[searchBar.selectedScopeButtonIndex], searchBar.text, searchController.isActive, _searchCancel);
    
    // prevent UISearchController from clearing out our filter when done
    if (_searchCancel) {
        if (_gameFilterText != nil && ![searchBar.text isEqualToString:_gameFilterText])
            searchBar.text = _gameFilterText;
        return;
    }
    NSString* text = searchBar.text;
    
    if (![_gameFilterText isEqualToString:text]) {
        _gameFilterText = text;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(filterGameList) object:nil];
        [self performSelector:@selector(filterGameList) withObject:nil afterDelay:0.500];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchBarTextDidBeginEditing");
    _searchCancel = FALSE;
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchBarTextDidEndEditing");
}

#if TARGET_OS_IOS
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked: active=%d", _searchController.active);
    _searchCancel = TRUE;
    _searchController.active = NO;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarCancelButtonClicked: active=%d", _searchController.active);
    _searchCancel = TRUE;
    
    if (!_searchController.active) {
        [self showSettings];
    }
}
#endif

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController
{
    NSLog(@"didPresentSearchController: active=%d", searchController.active);
}
- (void)didDismissSearchController:(UISearchController *)searchController
{
    NSLog(@"didDismissSearchController: active=%d", searchController.active);
}

#pragma mark - UICollectionView

-(void)kickLayout
{
    // HACK kick the layout in the head, so it gets the location of headers correct
    CGPoint offset = self.collectionView.contentOffset;
    [self.collectionView setContentOffset:CGPointMake(offset.x, offset.y + 0.5)];
    [self.collectionView layoutIfNeeded];
    [self.collectionView setContentOffset:offset];
}

-(void)invalidateLayout
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    _layoutRowHeightCache = nil;   // flush row height cache
    [self kickLayout];
}

-(void)reloadData
{
    [self.collectionView reloadData];
    [self invalidateLayout];
}

-(void)updateLayout
{
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat space = TARGET_OS_IOS ? 8.0 : 16.0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(space, space, space, space);
    layout.minimumLineSpacing = space;
    layout.minimumInteritemSpacing = space;
    layout.sectionHeadersPinToVisibleBounds = YES;
    
#if TARGET_OS_IOS
    CGFloat height = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle].pointSize;
#else
    CGFloat height = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize * 1.5;
#endif
    layout.headerReferenceSize = CGSizeMake(height, height);
    layout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    
    CGFloat width = self.collectionView.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right);
    width -= (self.view.safeAreaInsets.left + self.view.safeAreaInsets.right);
    width -= (self.collectionView.adjustedContentInset.left + self.collectionView.adjustedContentInset.right);

    if (_layoutMode == LayoutTiny)
        _layoutCollums = MAX(2,round(width / CELL_TINY_WIDTH));
    else if (_layoutMode == LayoutSmall)
        _layoutCollums = MAX(2,round(width / CELL_SMALL_WIDTH));
    else if (_layoutMode == LayoutList)
        _layoutCollums = MAX(1,round(width / CELL_LIST_WIDTH));
    else
        _layoutCollums = MAX(1,round(width / CELL_LARGE_WIDTH));
    
    width = width - (_layoutCollums-1) * layout.minimumInteritemSpacing;
    width = floor(width / (CGFloat)_layoutCollums);
    
    if (_layoutMode == LayoutList)
    {
        layout.itemSize = CGSizeMake(width, width / 4.0);
        layout.estimatedItemSize = CGSizeZero;
    }
    else
    {
        layout.itemSize = UICollectionViewFlowLayoutAutomaticSize;
        layout.estimatedItemSize = CGSizeMake(width, width * 1.5);
    }

    [self reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat yTop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top;
    for (GameCell* cell in [self.collectionView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionHeader]) {
        if (yTop > 0.5 && fabs(yTop - cell.frame.origin.y) <= cell.frame.size.height) {
            if (@available(iOS 13.0, *))
                [cell addBlur:UIBlurEffectStyleDark];
            else
                cell.contentView.backgroundColor = HEADER_PINNED_COLOR;
        }
        else {
            if (@available(iOS 13.0, *))
                cell.backgroundView = nil;
            else
                cell.contentView.backgroundColor = HEADER_BACKGROUND_COLOR;
        }
    }
}

#pragma mark System

- (BOOL)isSystem:(NSDictionary*)game
{
    return [@[kGameInfoNameMameMenu, kGameInfoNameSettings] containsObject:game[kGameInfoName]];
}

#pragma mark Favorites

- (BOOL)isFavorite:(NSDictionary*)game
{
    NSArray* favoriteGames = [NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[];
    return [favoriteGames containsObject:game];
}
- (void)setFavorite:(NSDictionary*)game isFavorite:(BOOL)flag
{
    if (game == nil || [game[kGameInfoName] length] == 0)
        return;

    NSMutableArray* favoriteGames = [([NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[]) mutableCopy];

    [favoriteGames removeObject:game];

    if (flag)
        [favoriteGames insertObject:game atIndex:0];
    
    [NSUserDefaults.standardUserDefaults setObject:favoriteGames forKey:FAVORITE_GAMES_KEY];
    [self updateExternal];
}

#pragma mark Recent Games

- (void)setRecent:(NSDictionary*)game isRecent:(BOOL)flag
{
    if (game == nil || [game[kGameInfoName] length] == 0)
        return;
    
    NSMutableArray* recentGames = [([NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY] ?: @[]) mutableCopy];

    [recentGames removeObject:game];
    if (flag)
        [recentGames insertObject:game atIndex:0];
    if ([recentGames count] > RECENT_GAMES_MAX)
        [recentGames removeObjectsInRange:NSMakeRange(RECENT_GAMES_MAX,[recentGames count] - RECENT_GAMES_MAX)];

    [NSUserDefaults.standardUserDefaults setObject:recentGames forKey:RECENT_GAMES_KEY];
    [self updateExternal];
}

#pragma mark Update External

- (void) updateExternal {

#if TARGET_OS_IOS
    [self updateApplicationShortcutItems];
#endif
    
#if TARGET_OS_TV
    // copy standardUserDefaults to sharedUserDefaults for TopShelf
    if (@available(tvOS 13.0, *)) {
        for (NSString* key in @[RECENT_GAMES_KEY, FAVORITE_GAMES_KEY]) {
            NSArray* games = ([NSUserDefaults.standardUserDefaults objectForKey:key] ?: @[]);
            [NSUserDefaults.sharedUserDefaults setObject:games forKey:key];
        }
        [TVTopShelfContentProvider topShelfContentDidChange];
    }
#endif
}

#pragma mark Application Shortcut Items

#define MAX_SHORTCUT_ITEMS 4

#if TARGET_OS_IOS
- (void) updateApplicationShortcutItems {
    NSArray* recentGames = [NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY] ?: @[];
    NSArray* favoriteGames = [NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[];

    recentGames = [recentGames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", favoriteGames]];
    
    NSLog(@"updateApplicationShortcutItems");
    NSLog(@"    RECENT GAMES(%d): %@", (int)[recentGames count], recentGames);
    NSLog(@"    FAVORITE GAMES(%d): %@", (int)[favoriteGames count], favoriteGames);
    
    NSUInteger maxRecent = MAX_SHORTCUT_ITEMS - MIN([favoriteGames count], MAX_SHORTCUT_ITEMS/2);
    NSUInteger numRecent = MIN([recentGames count], maxRecent);
    NSUInteger numFavorite = MIN([favoriteGames count], MAX_SHORTCUT_ITEMS - numRecent);
    
    recentGames = [recentGames subarrayWithRange:NSMakeRange(0, numRecent)];
    favoriteGames = [favoriteGames subarrayWithRange:NSMakeRange(0, numFavorite)];
    
    NSArray* games = [favoriteGames arrayByAddingObjectsFromArray:recentGames];
    
    NSMutableArray* shortcutItems = [[NSMutableArray alloc] init];
    
    for (NSDictionary* game in games) {
        NSString* type = [NSString stringWithFormat:@"%@.%@", NSBundle.mainBundle.bundleIdentifier, @"play"];
        NSString* name = game[kGameInfoDescription] ?: game[kGameInfoName];
        NSString* title = [NSString stringWithFormat:@"%@", [[name componentsSeparatedByString:@" ("] firstObject]];
        UIApplicationShortcutIcon* icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay];
        
        if (@available(iOS 13.0, *))
            icon = [UIApplicationShortcutIcon iconWithSystemImageName:[self isFavorite:game] ? @"gamecontroller.fill" : @"gamecontroller"];
        
        UIApplicationShortcutItem* item = [[UIApplicationShortcutItem alloc] initWithType:type
                                           localizedTitle:title localizedSubtitle:nil
                                           icon:icon userInfo:game];
        [shortcutItems addObject:item];
    }

    [UIApplication sharedApplication].shortcutItems = shortcutItems;
}
#endif

#pragma mark Update Images

-(void)invalidateRowHeight:(NSIndexPath*)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row_start = (indexPath.item / _layoutCollums) * _layoutCollums;
    [_layoutRowHeightCache removeObjectForKey:[NSIndexPath indexPathForItem:row_start inSection:section]];
}

-(void)updateImages
{
    static BOOL g_updating;
    
    if (g_updating || self.collectionView.isDragging || self.collectionView.isTracking || self.collectionView.isDecelerating) {
        NSLog(@"updateImages: SCROLLING (will try again)");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateImages) object:nil];
        [self performSelector:@selector(updateImages) withObject:nil afterDelay:1.0];
        return;
    }

    NSMutableSet* update_items = [[NSMutableSet alloc] init];

    // ok get all the *visible* indexPaths and see if any need a refresh/reload
    NSArray* vis_items = [self.collectionView indexPathsForVisibleItems];
    
    for (NSIndexPath* indexPath in vis_items) {
        NSDictionary* game = [self getGameInfo:indexPath];
        NSURL* url = [self getGameImageURL:game];
        if (![_updated_urls containsObject:url])
            continue;

        [self invalidateRowHeight:indexPath];

        // we need to update the entire row
        NSUInteger section = indexPath.section;
        NSUInteger row_start = (indexPath.item / _layoutCollums) * _layoutCollums;
        NSUInteger row_end = MIN(row_start + _layoutCollums, [self collectionView:self.collectionView numberOfItemsInSection:section]);
        
        for (NSUInteger item = row_start; item < row_end; item++)
            [update_items addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    
    NSLog(@"updateImages: %d visible items, %d dirty images, %d cells need updated", (int)vis_items.count, (int)_updated_urls.count, (int)update_items.count);
    [_updated_urls removeAllObjects];

    if (update_items.count > 0) {
        NSIndexPath* selectedIndexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
        
        if (selectedIndexPath != nil && ![update_items containsObject:selectedIndexPath])
            selectedIndexPath = nil;

        g_updating = TRUE;
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:[update_items allObjects]];
        } completion:^(BOOL finished) {
            NSLog(@"updateImages DONE!");
            g_updating = FALSE;
            if (selectedIndexPath != nil) {
                [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
            }
            [self kickLayout];
        }];
    }
}

// update all cells with this image
-(void)updateImage:(NSURL*)url
{
    _updated_urls = _updated_urls ?: [[NSMutableSet alloc] init];
    [_updated_urls addObject:url];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateImages) object:nil];
    [self performSelector:@selector(updateImages) withObject:nil afterDelay:1.0];
}


#pragma mark UICollectionView data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_gameSectionTitles count];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section >= _gameSectionTitles.count)
        return 0;
    NSString* title = _gameSectionTitles[section];
    NSInteger num = [_gameData[title] count];
    // restrict the Recent items to a single row, always
    if ([title isEqualToString:RECENT_GAMES_TITLE])
        num = MIN(num, _layoutCollums);
    return num;
}
-(NSDictionary*)getGameInfo:(NSIndexPath*)indexPath
{
    if (indexPath.section >= _gameSectionTitles.count)
        return nil;
    
    NSArray* items = _gameData[_gameSectionTitles[indexPath.section]];
    
    if (indexPath.item >= items.count)
        return nil;
        
    return items[indexPath.item];
}

//  get the text based on the LayoutMode
//
//  TINY        SMALL                       LARGE or LIST
//  ----        -----                       -------------
//  romname     short Description           full Description
//              short Manufacturer • Year   full Manufacturer • Year  • romname [parent-rom]
//
+(NSAttributedString*)getGameText:(NSDictionary*)info layoutMode:(LayoutMode)layoutMode textAlignment:(NSTextAlignment)textAlignment
{
    NSString* title;
    NSString* detail;
    NSString* str;

    if (layoutMode == LayoutTiny) {
        title = info[kGameInfoName];
    }
    else if (layoutMode == LayoutSmall) {
        title = [[info[kGameInfoDescription] componentsSeparatedByString:@" ("] firstObject];
        detail = [NSString stringWithFormat:@"%@ • %@",
                    [[info[kGameInfoManufacturer] componentsSeparatedByString:@" ("] firstObject],
                    info[kGameInfoYear]];
    }
    else { // LayoutLarge and LayoutList
        title = info[kGameInfoDescription];
        detail = info[kGameInfoManufacturer];

        if ((str = info[kGameInfoYear]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];
        
        if ((str = info[kGameInfoName]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];

        if ((str = info[kGameInfoParent]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ [%@]", detail, str];
    }
    
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName:CELL_TITLE_FONT,
        NSForegroundColorAttributeName:CELL_TITLE_COLOR
    }];

    if (detail != nil)
    {
        detail = [@"\n" stringByAppendingString:detail];

        [text appendAttributedString:[[NSAttributedString alloc] initWithString:detail attributes:@{
            NSFontAttributeName:CELL_DETAIL_FONT,
            NSForegroundColorAttributeName:CELL_DETAIL_COLOR
        }]];
    }
    
    if (textAlignment != NSTextAlignmentLeft)
    {
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        [paragraph setAlignment:textAlignment];
        [text addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
    }
    
    return [text copy];
}

-(NSAttributedString*)getGameText:(NSDictionary*)game
{
    return [[self class] getGameText:game layoutMode:_layoutMode textAlignment:_layoutMode == LayoutList ? NSTextAlignmentLeft : CELL_TEXT_ALIGN];
}

// compute the size(s) of a single item. returns: (x = image_height, y = text_height)
- (CGPoint)heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    NSDictionary* info = [self getGameInfo:indexPath];
    NSAttributedString* text = [self getGameText:info];
    
    // start with the (estimatedSize.width,0.0)
    CGFloat item_width = layout.estimatedItemSize.width;
    CGFloat image_height, text_height;
    
    // get the title image size, assume the image is 4:3 if we dont know.
    CGSize imageSize = [self getGameImageSize:info];
    
    if (imageSize.height == 0.0 || imageSize.width == 0.0 || imageSize.width > imageSize.height)
        image_height = ceil(item_width * 3.0 / 4.0);
    else
        image_height = ceil(item_width * 4.0 / 3.0);

    // get the text height, in LayoutTiny we only show one line.
    CGSize textSize = CGSizeMake(item_width - CELL_INSET_X*2, 9999.0);
    if (_layoutMode == LayoutTiny)
        textSize.width = 9999.0;
    textSize = [text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    
    text_height = CELL_INSET_Y + ceil(textSize.height) + CELL_INSET_Y;
    
    NSLog(@"heightForItemAtIndexPath: %d.%d %@ -> %@", (int)indexPath.section, (int)indexPath.item, info[kGameInfoName], NSStringFromCGSize(CGSizeMake(image_height, text_height)));
    return CGPointMake(image_height, text_height);
}

// compute (or return from cache) the height(s) of a single row. the height of a row is the maximum of all items in that row.
// returns: (x = image_height, y = text_height)
- (CGPoint)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // this code should not be called in this case
    NSParameterAssert(!(_layoutMode == LayoutList || _layoutCollums <= 1));

    // if we are in list mode, or we only have one collum, no need to do extra work computing sizes
    if (_layoutMode == LayoutList || _layoutCollums <= 1)
        return CGPointZero;
    
    NSUInteger section = indexPath.section;
    NSUInteger row_start = (indexPath.item / _layoutCollums) * _layoutCollums;
    NSUInteger row_end = MIN(row_start + _layoutCollums, [self collectionView:self.collectionView numberOfItemsInSection:section]);
    indexPath = [NSIndexPath indexPathForItem:row_start inSection:section];

    // check row height cache
    NSValue* val = _layoutRowHeightCache[indexPath];
    if (val != nil)
        return [val CGPointValue];

    // go over each item in the row and compute the max image_height and max text_height
    CGPoint row_height = CGPointZero;
    for (NSUInteger item = row_start; item < row_end; item++) {
        CGPoint item_height = [self heightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
        row_height.x = MAX(row_height.x, item_height.x);
        row_height.y = MAX(row_height.y, item_height.y);
    }
    
    NSLog(@"heightForRow: %d.%d -> %@ = %f", (int)indexPath.section, (int)indexPath.item, NSStringFromCGPoint(row_height), row_height.x + row_height.y);
    _layoutRowHeightCache = _layoutRowHeightCache ?: [[NSMutableDictionary alloc] init];
    _layoutRowHeightCache[indexPath] = [NSValue valueWithCGPoint:row_height];
    return row_height;
}

// create a cell for an item.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForItemAtIndexPath: %d.%d", (int)indexPath.section, (int)indexPath.item);
    
    NSDictionary* info = [self getGameInfo:indexPath];
    
    GameCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    
    cell.text.attributedText = [self getGameText:info];
    
    if (_layoutMode == LayoutTiny) {
        cell.text.numberOfLines = 1;
        cell.text.adjustsFontSizeToFitWidth = TRUE;
    }
    
    if (_layoutMode == LayoutTiny || _layoutMode == LayoutList) {
        [cell setCornerRadius:CELL_CORNER_RADIUS / 2];
    }
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat space = layout.minimumInteritemSpacing;
    CGFloat scale = 1.0 + (space * 1.5 / cell.bounds.size.width);
    [cell setSelectScale:scale];

    [cell setHorizontal:_layoutMode == LayoutList];
    [cell setTextInsets:UIEdgeInsetsMake(CELL_INSET_Y, CELL_INSET_X, CELL_INSET_Y, CELL_INSET_X)];
    
    CGPoint row_height = CGPointZero;
    if (_layoutMode != LayoutList && _layoutCollums > 1) {
        row_height = [self heightForRowAtIndexPath:indexPath];
        [cell setHeight:(row_height.x + row_height.y)];
    }

    NSURL* url = [self getGameImageURL:info];
    NSURL* local = [self getGameImageLocalURL:info];

    cell.tag = url.hash;
    [[ImageCache sharedInstance] getImage:url size:CGSizeZero localURL:local completionHandler:^(UIImage *image) {
        
        // cell has been re-used bail
        if (cell.tag != url.hash)
            return;
        
        // if this is syncronous set image and be done
        if (cell.image.image == nil) {
            
            image = image ?: self->_defaultImage;
            
            // MAME games always ran on horz or vertical CRTs so it does not matter what the PAR of
            // the title image is force a aspect of 3:4 or 4:3
            
            if (image.size.width < image.size.height) {
                // image is a portrait (3:4) image
                CGFloat aspect = 3.0/4.0;
                
                if (self->_layoutMode == LayoutList)
                    image = [image scaledToSize:CGSizeMake(cell.bounds.size.height / aspect, cell.bounds.size.height) aspect:aspect mode:UIViewContentModeScaleAspectFit];
                else
                    [cell setImageAspect:aspect];
            }
            else {
                // image is a landscape (4:3) image
                CGFloat aspect = 4.0/3.0;
                
                if (self->_layoutMode == LayoutList || self->_layoutCollums <= 1 || row_height.x <= ceil(cell.bounds.size.width * 3.0 / 4.0))
                    [cell setImageAspect:aspect];
                else
                    image = [image scaledToSize:CGSizeMake(cell.bounds.size.width, cell.bounds.size.width * aspect) aspect:aspect mode:UIViewContentModeScaleAspectFit];
            }

            cell.image.image = image ?: self->_defaultImage;
            return;
        }
        
        NSLog(@"CELL ASYNC LOAD: %@ %d:%d", info[kGameInfoName], (int)indexPath.section, (int)indexPath.item);
        [self updateImage:url];
        [self invalidateRowHeight:indexPath];
    }];
    
    // use a placeholder image if the image did not load right away.
    if (cell.image.image == nil) {
        cell.image.image = _loadingImage;
        if (row_height.x != 0.0)
            [cell setImageAspect:(cell.bounds.size.width / row_height.x)];
        [cell startWait];
    }
    
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)layout insetForSectionAtIndex:(NSInteger)section
{
    // UICollectionViewFlowLayout will center a section with a single item in it, else it will left align, WTF!
    // we want left aligned all the time, so mess with the section inset to make it do the right thing.
    
    if (section >= [_gameSectionTitles count] || [_gameData[_gameSectionTitles[section]] count] != 1)
        return layout.sectionInset;
            
    CGFloat itemWidth = (layout.estimatedItemSize.width != 0.0) ? layout.estimatedItemSize.width : layout.itemSize.width;
    CGFloat width = collectionView.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right) - (self.view.safeAreaInsets.left + self.view.safeAreaInsets.right);
    return UIEdgeInsetsMake(layout.sectionInset.top, layout.sectionInset.left, layout.sectionInset.bottom, layout.sectionInset.right + (width - itemWidth));
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)layout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section >= [_gameSectionTitles count] || [_gameSectionTitles[section] length] == 0)
        return CGSizeMake(0.0, 0.0);
    else
        return layout.headerReferenceSize;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    GameCell* cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HEADER_IDENTIFIER forIndexPath:indexPath];
    [cell setHorizontal:TRUE];
    cell.text.text = _gameSectionTitles[indexPath.section];
    cell.text.font = [UIFont systemFontOfSize:cell.bounds.size.height * 0.8 weight:UIFontWeightHeavy];
    cell.text.textColor = HEADER_TEXT_COLOR;
    cell.contentView.backgroundColor = HEADER_BACKGROUND_COLOR;
    [cell setTextInsets:UIEdgeInsetsMake(2.0, self.view.safeAreaInsets.left + 2.0, 2.0, self.view.safeAreaInsets.right + 2.0)];
    [cell setCornerRadius:0.0];
    [cell setBorderWidth:0.0];

    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* game = [self getGameInfo:indexPath];
    
    NSLog(@"DID SELECT ITEM[%d.%d] %@", (int)indexPath.section, (int)indexPath.item, game[kGameInfoName]);
    
    // add (or move to front) of the recent game LRU list...
    [self setRecent:game isRecent:TRUE];
    
    // tell the code upstream that the user had selected a game to play!
    if (self.selectGameCallback != nil)
        self.selectGameCallback(game);
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(GameCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"willDisplayCell: %d.%d %@", (int)indexPath.section, (int)indexPath.row, [self getGameInfo:indexPath][kGameInfoName]);
    
    if (![cell isKindOfClass:[GameCell class]])
        return;

    // if this cell still have the loading image, it went offscreen, got canceled, came back on screen ==> reload just to be safe.
    if (cell.image.image == _loadingImage)
    {
        NSDictionary* game = [self getGameInfo:indexPath];
        NSURL* url = [self getGameImageURL:game];

        if (url != nil)
            [self updateImage:url];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(GameCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"endDisplayCell: %d.%d %@", (int)indexPath.section, (int)indexPath.row, [self getGameInfo:indexPath][kGameInfoName]);

    if (![cell isKindOfClass:[GameCell class]])
        return;

    if (cell.image.image == _loadingImage)
    {
        NSDictionary* game = [self getGameInfo:indexPath];
        NSURL* url = [self getGameImageURL:game];
    
        if (url != nil)
            [[ImageCache sharedInstance] cancelImage:url];
    }
}

#pragma mark - game context menu actions...

// get the files associated with a game, if allFiles is NO only the settings files are returned.
// file paths are relative to our document root.
-(NSArray*)getGameFiles:(NSDictionary*)game allFiles:(BOOL)all
{
    NSString* name = game[kGameInfoName];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    for (NSString* file in @[@"titles/%@.png", @"cfg/%@.cfg", @"ini/%@.ini", @"sta/%@/1.sta", @"sta/%@/2.sta", @"hi/%@.hi", @"nvram/%@.nv", @"inp/%@.inp",
                             @"snap/%@.png", @"snap/%@.mng", @"snap/%@.avi", @"snap/%@/"])
        [files addObject:[NSString stringWithFormat:file, name]];
    
    if (all) {
        for (NSString* file in @[@"roms/%@.zip", @"roms/%@/", @"artwork/%@.zip", @"samples/%@.zip"])
            [files addObject:[NSString stringWithFormat:file, name]];
    }
    
    return files;
}

-(void)delete:(NSDictionary*)game
{
    NSString* title = [self menuTitleForGame:game];
    NSString* message = nil;

    [self showAlertWithTitle:title message:message buttons:@[@"Delete All Settings", @"Delete Everything", @"Cancel"] handler:^(NSUInteger button) {
        
        // cancel get out!
        if (button == 2)
            return;
        
        // 0=Settings, 1=All Files
        BOOL allFiles = (button == 1);
        NSArray* files = [self getGameFiles:game allFiles:allFiles];
        
        NSString* root = [NSString stringWithUTF8String:get_documents_path("")];
        for (NSString* file in files) {
            NSString* delete_path = [root stringByAppendingPathComponent:file];
            NSLog(@"DELETE: %@", delete_path);
            [[NSFileManager defaultManager] removeItemAtPath:delete_path error:nil];
        }
        
        [[ImageCache sharedInstance] flush:[self getGameImageURL:game] size:CGSizeZero];
        
        if (allFiles) {
            [self setRecent:game isRecent:FALSE];
            [self setFavorite:game isFavorite:FALSE];

            [self setGameList:[self->_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", game]]];

            // if we have deleted the last game, excpet for the MAMEMENU, then exit with no game selected and let a re-scan happen.
            if ([self->_gameList count] <= 1) {
                if (self.selectGameCallback != nil)
                    self.selectGameCallback(nil);
            }
        }
    }];
}

#if TARGET_OS_IOS
// Export a game as a ZIP file with all the game state and settings, make the export file be named "SHORT-DESCRIPTION (ROMNAME).zip"
// NOTE we specificaly *dont* export CHDs because they are huge
-(void)share:(NSDictionary*)game
{
    NSString* title = [NSString stringWithFormat:@"%@ (%@)",[[game[kGameInfoDescription] componentsSeparatedByString:@" ("] firstObject], game[kGameInfoName]];
    
    FileItemProvider* item = [[FileItemProvider alloc] initWithTitle:title typeIdentifier:@"public.zip-archive" saveHandler:^BOOL(NSURL* url, FileItemProviderProgressHandler progressHandler) {
        NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
        NSArray* files = [self getGameFiles:game allFiles:YES];
        return [ZipFile exportTo:url.path fromDirectory:rootPath withFiles:files withOptions:(ZipFileWriteFiles | ZipFileWriteAtomic) progressBlock:progressHandler];
    }];
    UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:@[item] applicationActivities:nil];

    if (activity.popoverPresentationController != nil) {
        UIView* view = self.view;
        activity.popoverPresentationController.sourceView = view;
        activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0.0f, 0.0f);
        activity.popoverPresentationController.permittedArrowDirections = 0;
    }

    [self presentViewController:activity animated:YES completion:nil];
}
#endif

-(void)info:(NSDictionary*)_game
{
    NSMutableDictionary* game = [_game mutableCopy];
    NSString* name = game[kGameInfoName];

    NSDictionary* atributes = @{
        UIFontTextStyleHeadline: @{
            NSFontAttributeName:INFO_HEAD_FONT,
            NSForegroundColorAttributeName:INFO_HEAD_COLOR
        },
        UIFontTextStyleBody: @{
            NSFontAttributeName:INFO_BODY_FONT,
            NSForegroundColorAttributeName:INFO_BODY_COLOR
        },
    };

    // add in our history/mameinfo to game dict.
    game[kGameInfoHistory] = [_history attributedStringForKey:name attributes:atributes];
    game[kGameInfoMameInfo] = [_mameinfo attributedStringForKey:name attributes:atributes];

    GameInfoController* gameInfoController = [[GameInfoController alloc] initWithGame:game];
    gameInfoController.title = @"Info";

#if TARGET_OS_IOS
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:gameInfoController];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nav animated:YES completion:nil];
#else
    [self presentViewController:gameInfoController animated:YES completion:nil];
#endif
}

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(NSDictionary*)game
{
    NSString* name = game[kGameInfoName];

    if (name == nil || [name length] <= 1 || [name isEqualToString:kGameInfoNameMameMenu])
        return nil;
    
    // if we only have the ROM name, try to find full info for this game in Recents or Favorites
    if (game[kGameInfoDescription] == nil) {
        NSArray* list = [[NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY] arrayByAddingObjectsFromArray:
                         [NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY]];
        game = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kGameInfoName, game[kGameInfoName]]].firstObject;
        
        if (game == nil)
            return nil;
    }
    
    NSString* type = [NSString stringWithFormat:@"%@.%@", NSBundle.mainBundle.bundleIdentifier, @"play"];
    NSString* description = game[kGameInfoDescription];
    NSString* title = [NSString stringWithFormat:@"Play %@", [[description componentsSeparatedByString:@" ("] firstObject]];
    
    NSUserActivity* activity = [[NSUserActivity alloc] initWithActivityType:type];
    
    activity.title = title;
    activity.userInfo = game;
    activity.eligibleForSearch = TRUE;
    
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = TRUE;
        activity.persistentIdentifier = game[kGameInfoName];
        activity.suggestedInvocationPhrase = title;
    }
    return activity;
}
-(INVoiceShortcut*)getVoiceShortcut:(NSUserActivity*)activity API_AVAILABLE(ios(12.0)) {
    __block INVoiceShortcut* found_shortcut = nil;
    __block NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [INVoiceShortcutCenter.sharedCenter getAllVoiceShortcutsWithCompletion:^(NSArray<INVoiceShortcut*>* shortcuts, NSError* error) {
        time = [NSDate timeIntervalSinceReferenceDate] - time;
        NSLog(@"getAllVoiceShortcuts took %0.3fsec", time);
        for (INVoiceShortcut* shortcut in shortcuts) {
            NSLog(@"    SHORTCUT: %@", shortcut);
            if ([shortcut.shortcut.userActivity.activityType isEqual:activity.activityType] &&
                [shortcut.shortcut.userActivity.persistentIdentifier isEqual:activity.persistentIdentifier]) {
                NSLog(@"    **** FOUND ACTIVITY: %@", activity);
                found_shortcut = shortcut;
            }
        }
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.200 * NSEC_PER_SEC)));
    return found_shortcut;
}
-(void)siri:(NSDictionary*)game activity:(NSUserActivity*)activity shortcut:(INVoiceShortcut*)shortcut API_AVAILABLE(ios(12.0)){
    UIViewController* viewController;
    
    if (shortcut == nil) {
        INShortcut* shortcut = [[INShortcut alloc] initWithUserActivity:activity];
        viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortcut];
    }
    else {
        viewController = [[INUIEditVoiceShortcutViewController alloc] initWithVoiceShortcut:shortcut];
    }
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    [(id)viewController setDelegate:self];
    [self presentViewController:viewController animated:YES completion:nil];
}
// INUIAddVoiceShortcutViewControllerDelegate
- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller didFinishWithVoiceShortcut:(INVoiceShortcut *)voiceShortcut error:(NSError *) error API_AVAILABLE(ios(12.0)) {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller API_AVAILABLE(ios(12.0)) {
    [self dismissViewControllerAnimated:YES completion:nil];
}
// INUIEditVoiceShortcutViewControllerDelegate
- (void)editVoiceShortcutViewController:(INUIEditVoiceShortcutViewController *)controller didUpdateVoiceShortcut:(INVoiceShortcut *)voiceShortcut error: (NSError *)error API_AVAILABLE(ios(12.0)) {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)editVoiceShortcutViewController:(INUIEditVoiceShortcutViewController *)controller didDeleteVoiceShortcutWithIdentifier:(NSUUID *)deletedVoiceShortcutIdentifier API_AVAILABLE(ios(12.0)) {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)editVoiceShortcutViewControllerDidCancel:(INUIEditVoiceShortcutViewController *)controller API_AVAILABLE(ios(12.0)) {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#endif


#pragma mark - Context Menu

// on iOS 13 create a UIAction for use in a UIContextMenu, on pre-iOS 13 create a UIAlertAction for use in a UIAlertController
- (id)actionWithTitle:(NSString*)title image:(UIImage*)image destructive:(BOOL)destructive handler:(void (^)(id action))handler {
    if (NSClassFromString(@"UIContextMenuConfiguration") != nil) {
        if (@available(iOS 13.0, tvOS 13.0, *)) {
            UIAction* action = [UIAction actionWithTitle:title image:image identifier:nil handler:handler];
            action.attributes = destructive ? UIMenuElementAttributesDestructive : 0;
            return action;
        }
        return nil;
    }
    else
    {
        UIAlertAction* action = [UIAlertAction actionWithTitle:title
                                                         style:(destructive ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault)
                                                       handler:handler];
        return action;
    }
}

// get the items in the ContextMenu for a item
- (NSArray*)menuActionsForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* game = [self getGameInfo:indexPath];
    NSString* name = game[kGameInfoName];
    
    if (game == nil || [name length] == 0)
        return nil;

    // prime the image cache, in case any menu items ask for the image later.
    [[ImageCache sharedInstance] getImage:[self getGameImageURL:game] size:CGSizeZero localURL:[self getGameImageLocalURL:game] completionHandler:^(UIImage *image) {}];

    NSLog(@"menuActionsForItemAtIndexPath: [%d.%d] %@ %@", (int)indexPath.section, (int)indexPath.row, game[kGameInfoName], game);
    
    BOOL is_fav = [self isFavorite:game];
    
    NSString* fav_text = is_fav ? @"Unfavorite" : @"Favorite";
    NSString* fav_icon = is_fav ? @"heart.slash" : @"heart";
    
    NSArray* actions = @[
        [self actionWithTitle:@"Play" image:[UIImage systemImageNamed:@"gamecontroller"] destructive:NO handler:^(id action) {
            [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
        }],
        
        [self actionWithTitle:fav_text image:[UIImage systemImageNamed:fav_icon] destructive:NO handler:^(id action) {
            [self setFavorite:game isFavorite:!is_fav];
            [self filterGameList];
        }],
    ];
    
    if ([_history boolForKey:name] || [_mameinfo boolForKey:name]) {
        actions = [actions arrayByAddingObjectsFromArray:@[
            [self actionWithTitle:@"Info" image:[UIImage systemImageNamed:@"info.circle"] destructive:NO handler:^(id action) {
                [self info:game];
            }]
        ]];
    }
    
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    if (@available(iOS 12.0, *)) {
        NSUserActivity* activity = [ChooseGameController userActivityForGame:game];
        INVoiceShortcut* shortcut = [self getVoiceShortcut:activity];
        if (activity != nil) {
            actions = [actions arrayByAddingObjectsFromArray:@[
                [self actionWithTitle:@"Add to Siri" image:[UIImage systemImageNamed:shortcut ? @"checkmark.circle" : @"plus.circle"] destructive:NO handler:^(id action) {
                    [self siri:game activity:activity shortcut:shortcut];
                }]
            ]];
        }
    }
#endif

    if (![self isSystem:game]) {
        actions = [actions arrayByAddingObjectsFromArray:@[
#if TARGET_OS_IOS
            [self actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] destructive:NO handler:^(id action) {
                [self share:game];
            }],
#endif
            [self actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] destructive:YES handler:^(id action) {
                [self delete:game];
            }]
        ]];
    }
    return actions;
}

// get the title for the ContextMenu
- (NSString*)menuTitleForGame:(NSDictionary *)game {

    if (game == nil || [game[kGameInfoName] length] == 0)
        return nil;
    
    return [NSString stringWithFormat:@"%@\n%@ • %@\n%@%@",
            game[kGameInfoDescription],
            game[kGameInfoManufacturer],
            game[kGameInfoYear],
            (game[kGameInfoDriver] == nil || [game[kGameInfoDriver] isEqualToString:game[kGameInfoName]]) ? @"" : [game[kGameInfoDriver] stringByAppendingString:@" • "],
            ([game[kGameInfoParent] length] > 1) ?
                [NSString stringWithFormat:@"%@ [%@]", game[kGameInfoName], game[kGameInfoParent]] :
                game[kGameInfoName]
            ];
}
- (NSString*)menuTitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self menuTitleForGame:[self getGameInfo:indexPath]];
}

#pragma mark - UIContextMenu (iOS 13+ only)

#if TARGET_OS_IOS

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];

    NSArray* actions = [self menuActionsForItemAtIndexPath:indexPath];
    NSString* title = [self menuTitleForItemAtIndexPath:indexPath];

    if ([actions count] == 0)
        return nil;
    
    return [UIContextMenuConfiguration configurationWithIdentifier:indexPath
            previewProvider:^UIViewController* () {
                return nil;     // use default
            }
            actionProvider:^UIMenu* (NSArray* suggestedActions) {
                return [UIMenu menuWithTitle:title children:actions];
            }
    ];
}

- (void)collectionView:(UICollectionView *)collectionView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0))
{
    NSIndexPath* indexPath = (id)configuration.identifier;
    
    if (indexPath == nil || ![indexPath isKindOfClass:[NSIndexPath class]])
        return;
    
    animator.preferredCommitStyle = UIContextMenuInteractionCommitStyleDismiss;
    [animator addCompletion:^{
        [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }];
}
#endif

#pragma mark - LongPress menu (pre iOS 13 and tvOS only)

-(void)runMenu:(NSIndexPath*)indexPath {

    if (indexPath == nil)
        return;
    
    NSArray* actions = [self menuActionsForItemAtIndexPath:indexPath];
    NSString* title = [self menuTitleForItemAtIndexPath:indexPath];
    
    if ([actions count] == 0)
        return;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (UIAlertAction* action in actions)
        [alert addAction:action];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    if (alert.popoverPresentationController != nil) {
        UIView* view = [self.collectionView cellForItemAtIndexPath:indexPath] ?: self.view;
        alert.popoverPresentationController.sourceView = view;
        alert.popoverPresentationController.sourceRect = view.bounds;
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {

    if (context.nextFocusedIndexPath != nil)
        NSLog(@"didUpdateFocusInContext: %d.%d", (int)context.nextFocusedIndexPath.section, (int)context.nextFocusedIndexPath.item);
    else
        NSLog(@"didUpdateFocusInContext: %@", NSStringFromClass(context.nextFocusedItem.class));

    _currentlyFocusedIndexPath = context.nextFocusedIndexPath;
}

-(void)handleLongPress:(UIGestureRecognizer*)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
        return;

#if TARGET_OS_TV
    NSIndexPath *indexPath = _currentlyFocusedIndexPath;
#else
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[sender locationInView:self.collectionView]];
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
#endif
    [self runMenu:indexPath];
}

#pragma mark MENU

#if TARGET_OS_IOS
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;

    if (action == @selector(filePlay) || action == @selector(fileInfo) || action == @selector(fileFavorite))
        return indexPath != nil;
    else
        return [super canPerformAction:action withSender:sender];
}


-(void)filePlay {
    [self onCommandSelect];
}
-(void)fileFavorite {
    NSDictionary* game = [self getGameInfo:self.collectionView.indexPathsForSelectedItems.firstObject];
    [self setFavorite:game isFavorite:![self isFavorite:game]];
    [self filterGameList];
}
-(void)fileInfo {
    NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
    [self info:[self getGameInfo:indexPath]];
}
#endif

#pragma mark Keyboard and Game Controller navigation

#if TARGET_OS_IOS
- (void)onCommandUp    { [self onCommandMove:-1 * _layoutCollums]; }
- (void)onCommandDown  { [self onCommandMove:+1 * _layoutCollums]; }
- (void)onCommandLeft  { [self onCommandMove:-1]; }
- (void)onCommandRight { [self onCommandMove:+1]; }
- (void)onCommandSelect {
    NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
    if (indexPath != nil)
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}
- (void)onCommandMove:(NSInteger)delta {

    if (delta < 0)
        NSLog(@"MOVE: %@", (delta == -1) ? @"LEFT" : @"UP");
    else
        NSLog(@"MOVE: %@", (delta == +1) ? @"RIGHT" : @"DOWN");

    if ([self.collectionView numberOfSections] == 0)
        return;
    
    NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject ?: [NSIndexPath indexPathForItem:-delta inSection:0];
    
    NSInteger section = indexPath.section;
    NSInteger item = indexPath.item;
    NSInteger col = item % _layoutCollums;
    NSInteger num_rows = ([self.collectionView numberOfItemsInSection:section] + _layoutCollums - 1) / _layoutCollums;

    if (section == 0 && item + delta < 0)
        return;
    if (section == self.collectionView.numberOfSections-1 && item + delta >= [self.collectionView numberOfItemsInSection:section])
        return;

    item += delta;
    
    NSInteger new_row = item / (int)_layoutCollums;
    
    if (item < 0 && section > 0)
    {
        section--;
        item = (([self.collectionView numberOfItemsInSection:section] + _layoutCollums-1) / _layoutCollums - 1) * _layoutCollums + col;
    }
    else if (new_row >= num_rows && section+1 < self.collectionView.numberOfSections)
    {
        section++;
        item = col;
    }
    
    section = CLAMP(section, self.collectionView.numberOfSections);
    item = CLAMP(item, [self.collectionView numberOfItemsInSection:section]);

    indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
}

// called when input happens on a gamecontroller, keyboard, or touch screen
// check for input related to moving and selecting.
-(void)handleButtonPress:(UIPressType)type
{
    switch (type) {
        case UIPressTypeUpArrow:
            return [self onCommandUp];
        case UIPressTypeDownArrow:
            return [self onCommandDown];
        case UIPressTypeLeftArrow:
            return [self onCommandLeft];
        case UIPressTypeRightArrow:
            return [self onCommandRight];
        case UIPressTypeSelect:
            return [self onCommandSelect];
        default:
            break;
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (NSArray*)keyCommands {
    
    if (_searchController.isActive)
        return @[];
    
    if (_key_commands == nil) {
        _key_commands = @[
            // standard keyboard
            [UIKeyCommand keyCommandWithInput:@"\r"                 modifierFlags:0 action:@selector(onCommandSelect)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow     modifierFlags:0 action:@selector(onCommandUp)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow   modifierFlags:0 action:@selector(onCommandDown)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow   modifierFlags:0 action:@selector(onCommandLeft)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow  modifierFlags:0 action:@selector(onCommandRight)],
            // iCade
            [UIKeyCommand keyCommandWithInput:@"y" modifierFlags:0 action:@selector(onCommandSelect)], // SELECT
            [UIKeyCommand keyCommandWithInput:@"h" modifierFlags:0 action:@selector(onCommandSelect)], // START
            [UIKeyCommand keyCommandWithInput:@"k" modifierFlags:0 action:@selector(onCommandSelect)], // A
            [UIKeyCommand keyCommandWithInput:@"w" modifierFlags:0 action:@selector(onCommandUp)],
            [UIKeyCommand keyCommandWithInput:@"x" modifierFlags:0 action:@selector(onCommandDown)],
            [UIKeyCommand keyCommandWithInput:@"a" modifierFlags:0 action:@selector(onCommandLeft)],
            [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:0 action:@selector(onCommandRight)],
        ];
    }
    return _key_commands;
}
#endif

#pragma mark UIEvent handling for button presses

#if TARGET_OS_TV
-(void)menuPress {
    NSLog(@"MENU PRESS");
    if ([self.navigationController topViewController] == self) {
        if ([self.topViewController isKindOfClass:[UIAlertController class]]) {
            NSLog(@"MENU PRESS: DISSMIS MENU");
            [(UIAlertController*)self.topViewController dismissWithCancel];
        }
        else if (_currentlyFocusedIndexPath != nil) {
            NSLog(@"MENU PRESS: SHOW MENU");
            [self runMenu:_currentlyFocusedIndexPath];
        } else {
            NSLog(@"MENU PRESS: IGNORE!");
        }
    }
    else {
        NSLog(@"MENU PRESS: POP TO ROOT");
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}
#endif

@end

#pragma mark - Custom ImageView

@interface ImageView : UIImageView
@property (readwrite, nonatomic) CGSize contentSize;
@property (readwrite, nonatomic) CGFloat aspect;
@end

@implementation ImageView
- (CGSize)intrinsicContentSize {
    CGSize size = _contentSize;
    
    if (self.image == nil)
        return size;
    
    if (size.width == 0.0 && size.height == 0.0)
        return self.image.size;
    
    if (size.width == 0.0)
        size.width = floor(size.height * self.aspect);
    if (size.height == 0.0)
        size.height = floor(size.width / self.aspect);
    
    return size;
}
- (void)setContentSize:(CGSize)contentSize {
    _contentSize = contentSize;
    [self invalidateIntrinsicContentSize];
}
// return the aspect ratio of the image, or an override (if set)
-(CGFloat)aspect {
    if (_aspect != 0.0)
        return _aspect;
    if (self.image.size.height == 0.0)
        return 1.0;
    return self.image.size.width / self.image.size.height;
}
@end


#pragma mark - GameCell

@interface GameCell () {
    UIStackView* _stackView;
    UIStackView* _stackText;
    CGFloat _height;
    CGFloat _scale;
}
@end

@implementation GameCell

// Two different cell typres, horz or vertical
//
// +-----------------+   +----------+-----------------+
// |                 |   |          |                 |
// |                 |   |  Image   | Text            |
// |    Image        |   |          |                 |
// |                 |   +----------+-----------------+
// |                 |
// +-----------------+
// | Text            |
// +-----------------+
//
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    _image = [[ImageView alloc] init];
    _text = [[UILabel alloc] init];
    UIView* decoy = [[UIView alloc] init];
#ifdef XDEBUG
    decoy.backgroundColor = [UIColor systemOrangeColor];
#endif
    _stackText = [[UIStackView alloc] initWithArrangedSubviews:@[_text]];
    _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_image, _stackText, decoy]];

    _stackView.translatesAutoresizingMaskIntoConstraints = YES;
    _stackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _stackView.frame = self.contentView.bounds;
    [self.contentView addSubview:_stackView];
    
    [self prepareForReuse];
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setNeedsLayout];
    [self setNeedsUpdateConstraints];
    
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = nil;

    [self setBackgroundColor:CELL_BACKGROUND_COLOR];
    [self setCornerRadius:CELL_CORNER_RADIUS];
    [self setBorderWidth:CELL_BORDER_WIDTH];
    [self setShadowColor:CELL_SHADOW_COLOR];
    
    _scale = 1.0;

    _text.text = nil;
    _text.attributedText = nil;
    _text.font = nil;
    _text.textColor = nil;
    _text.numberOfLines = 0;
    _text.adjustsFontSizeToFitWidth = FALSE;
    _text.textAlignment = NSTextAlignmentLeft;
    
    _height = 0.0;

    _image.image = nil;
    _image.highlightedImage = nil;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.layer.minificationFilter = kCAFilterLinear;
    ((ImageView*)_image).aspect = 0.0;
    [_image setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [_image setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [_image setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [_image setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

#if TARGET_OS_TV
    _image.adjustsImageWhenAncestorFocused = NO;
#endif
    [self stopWait];

    _stackView.axis = UILayoutConstraintAxisVertical;
    _stackView.alignment = UIStackViewAlignmentFill;
    _stackView.distribution = UIStackViewDistributionFill;
    _stackView.layoutMarginsRelativeArrangement = NO;
    _stackView.preservesSuperviewLayoutMargins = NO;
    
    _stackText.axis = UILayoutConstraintAxisVertical;
    _stackText.alignment = UIStackViewAlignmentFill;
    _stackText.distribution = UIStackViewDistributionFill;
    _stackText.layoutMargins = UIEdgeInsetsMake(4.0, 8.0, 4.0, 8.0);
    _stackText.layoutMarginsRelativeArrangement = YES;
    _stackText.insetsLayoutMarginsFromSafeArea = NO;
}

- (void)updateConstraints
{
    CGFloat width = self.bounds.size.width;
    
    if (_stackView.axis == UILayoutConstraintAxisVertical)
        ((ImageView*)_image).contentSize = CGSizeMake(width, 0.0);
    else
        ((ImageView*)_image).contentSize = CGSizeMake(0.0,self.bounds.size.height);

    if (_stackView.axis == UILayoutConstraintAxisHorizontal)
        width -= _image.intrinsicContentSize.width;

    width -= (_stackText.layoutMargins.left + _stackText.layoutMargins.right);

    _text.preferredMaxLayoutWidth = width;
    
    [super updateConstraints];
}

-(void)setHorizontal:(BOOL)horizontal
{
    if (horizontal)
    {
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
    }
    else
    {
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.alignment = UIStackViewAlignmentFill;
    }
    [self setNeedsUpdateConstraints];
}

-(void)setTextInsets:(UIEdgeInsets)insets
{
    _stackText.layoutMargins = insets;
    [self setNeedsUpdateConstraints];
}
-(void)setImageAspect:(CGFloat)aspect
{
    _image.contentMode = UIViewContentModeScaleToFill;
    ((ImageView*)_image).aspect = aspect;
}
-(void)setHeight:(CGFloat)height
{
    _height = height;
    [self setNeedsUpdateConstraints];
}
-(void)setBorderWidth:(CGFloat)width
{
    self.contentView.layer.borderWidth = width;
    self.contentView.layer.borderColor = self.contentView.backgroundColor.CGColor;
}
-(void)setCornerRadius:(CGFloat)radius
{
    if (self.contentView.backgroundColor == UIColor.clearColor) {
        _image.layer.cornerRadius = radius;
        _image.clipsToBounds = radius != 0.0;
    }
    else {
        self.layer.cornerRadius = radius;
        self.contentView.layer.cornerRadius = radius;
        self.contentView.clipsToBounds = radius != 0.0;
        _image.layer.cornerRadius = 0.0;
        _image.clipsToBounds = NO;
    }
}
-(void)setBackgroundColor:(UIColor*)color
{
    self.contentView.backgroundColor = color;
    self.contentView.layer.borderColor = color.CGColor;
}
-(void)setShadowColor:(UIColor*)color
{
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0f);
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOpacity = 1.0;
}
-(void)setSelectScale:(CGFloat)scale
{
    _scale = scale;
}
-(void)addBlur:(UIBlurEffectStyle)style {
    if (self.backgroundView != nil)
        return;
    UIBlurEffect* blur = [UIBlurEffect effectWithStyle:style];
    UIVisualEffectView* effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
    effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    effectView.frame = self.bounds;
    self.backgroundView = effectView;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_13_0
#define UIActivityIndicatorViewStyleMedium UIActivityIndicatorViewStyleWhite
#define UIActivityIndicatorViewStyleLarge UIActivityIndicatorViewStyleWhiteLarge
#endif

-(void)startWait
{
    UIActivityIndicatorView* wait = _image.subviews.lastObject;
    if (![wait isKindOfClass:[UIActivityIndicatorView class]])
    {
        wait = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        wait.activityIndicatorViewStyle = self.bounds.size.width <= 100.0 ? UIActivityIndicatorViewStyleMedium : UIActivityIndicatorViewStyleLarge;
        [wait sizeToFit];
        
        wait.color = self.tintColor;
        [_image addSubview:wait];

        wait.translatesAutoresizingMaskIntoConstraints = NO;
        [wait.centerXAnchor constraintEqualToAnchor:_image.centerXAnchor].active = TRUE;
        [wait.centerYAnchor constraintEqualToAnchor:_image.centerYAnchor].active = TRUE;
    }
    [wait startAnimating];
}
-(void)stopWait
{
    for (UIView* view in _image.subviews)
        [view removeFromSuperview];
}

- (CGSize)sizeThatFits:(CGSize)targetSize
{
    if (_stackView.axis == UILayoutConstraintAxisHorizontal)
        return targetSize;
    
    if (_height != 0.0) {
        targetSize.height = _height;
        return targetSize;
    }
    
    [self updateConstraintsIfNeeded];
    targetSize.height = ceil([_stackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    
    return targetSize;
}
-(CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
{
    return [self sizeThatFits:targetSize];
}
- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    return [self systemLayoutSizeFittingSize:targetSize];
}

- (void)updateSelected
{
    BOOL selected = self.selected || self.focused;
#if TARGET_OS_IOS || !TVOS_PARALLAX
    if (_image.image == nil)
        return;
    if (!(CELL_BACKGROUND_COLOR == UIColor.clearColor))
        [self setBackgroundColor:selected ? CELL_SELECTED_COLOR : CELL_BACKGROUND_COLOR];
    [self setShadowColor:selected ? CELL_SELECTED_COLOR : CELL_SHADOW_COLOR];
    self.transform = selected ? CGAffineTransformMakeScale(_scale, _scale) : (self.highlighted ? CGAffineTransformMakeScale(2.0 - _scale, 2.0 - _scale) : CGAffineTransformIdentity);
#endif
#if TARGET_OS_TV && TVOS_PARALLAX
    if (selected)
        [self.superview bringSubviewToFront:self];
    else
        [self.superview sendSubviewToBack:self];
#endif
}
- (void)setHighlighted:(BOOL)highlighted
{
    NSLog(@"setHighlighted(%@): %@", self.text.text, highlighted ? @"YES" : @"NO");
    [super setHighlighted:highlighted];
    [self updateSelected];
}
- (void)setSelected:(BOOL)selected
{
    NSLog(@"setSelected(%@): %@", self.text.text, selected ? @"YES" : @"NO");
    [super setSelected:selected];
    [self updateSelected];
}

#if TARGET_OS_TV && TVOS_PARALLAX
-(void)drawRect:(CGRect)rect
{
    // on tvOS we flatten the cell into a single image so the parallax selection works.
    // NOTE we do this in drawRect so we know the cell is ready to be displayed, passing afterScreenUpdates:YES is crazy slow.
    if (_image.image != nil && !_image.adjustsImageWhenAncestorFocused && _image.subviews.count == 0 && self.bounds.size.height < self.window.bounds.size.height) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.image.adjustsImageWhenAncestorFocused && self.image.subviews.count == 0) {
                CGRect rect = self.bounds;
                UIImage* image = [[[UIGraphicsImageRenderer alloc] initWithSize:rect.size] imageWithActions:^(UIGraphicsImageRendererContext * context) {
                    [self drawViewHierarchyInRect:rect afterScreenUpdates:NO];
                }];
                self.image.adjustsImageWhenAncestorFocused = YES;
                self.image.image = image;
                self.text.text = nil;
                [self setTextInsets:UIEdgeInsetsZero];
                [self setImageAspect:0.0];
                [self setBorderWidth:0.0];
                self.contentView.clipsToBounds = NO;
                self.image.clipsToBounds = NO;
            }
        });
    }
}
#endif

#if TARGET_OS_TV
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        [self updateSelected];
    } completion:nil];
}
#endif
@end

#pragma mark - Custom TextLabel

// a UITextView that behaves like a UILabel, and you can put it in a UIStackView!
@interface TextLabel : UITextView
@property(nonatomic) CGFloat preferredMaxLayoutWidth;
@property(nonatomic) NSInteger numberOfLines;
@property(nonatomic) BOOL adjustsFontSizeToFitWidth;
@end

@implementation TextLabel
- (CGSize)intrinsicContentSize {

    if (self.attributedText.length == 0)
        return CGSizeZero;
    
    CGSize size = CGSizeMake(self.preferredMaxLayoutWidth, CGFLOAT_MAX);
    if (size.width == 0.0)
        size.width = CGFLOAT_MAX;
    size = [self.attributedText boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    size.height = ceil(size.height);
    return size;
}
- (void)setPreferredMaxLayoutWidth:(CGFloat)width {
    _preferredMaxLayoutWidth = width;
    [self invalidateIntrinsicContentSize];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.layoutManager.usesFontLeading = NO;
#if TARGET_OS_IOS
    self.editable = NO;
#endif
    self.selectable = NO;
    self.scrollEnabled = NO;
    self.backgroundColor = UIColor.clearColor;
    return self;
}
@end

#pragma mark GameInfoController

@implementation GameInfoController {
    NSDictionary* _game;
    CGFloat _layoutWidth;
    CGFloat _titleSwitchOffset;
    UIImage* _image;
}
-(instancetype)initWithGame:(NSDictionary*)game {
    self = [self initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    _game = game;
    return self;
}
- (void)done {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad {
    [self.collectionView registerClass:[GameCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER];
    
    self.collectionView.backgroundColor = INFO_BACKGROUND_COLOR;
    self.collectionView.allowsSelection = TARGET_OS_IOS ? NO : YES;
    
#if TARGET_OS_IOS
    if (@available(iOS 13.0, tvOS 13.0, *))
        self.navigationController.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    else
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    // set our title (scrollViewDidScroll will set the correct text)
    UILabel* title = [[UILabel alloc] init];
    title.textAlignment = NSTextAlignmentCenter;
    title.numberOfLines = 0;
    title.textColor = CELL_TITLE_COLOR;
    self.navigationItem.titleView = title;
    
    // we are a self dismissing controller
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
#else
    // TODO: I tried and tried to get the focus engine to give focus to the UITextView nested inside the GameCell
    // but I gave up, and am just gonna do a manual pan gesture handler and scroll myself!!
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    [self.view addGestureRecognizer:pan];
#endif
}
#if TARGET_OS_TV
- (void)pan:(UIPanGestureRecognizer*)pan {

    GameCell* cell = (GameCell*)UIScreen.mainScreen.focusedView;
    if (![cell isKindOfClass:[GameCell class]])
        return;

    CGPoint translation = [pan translationInView:self.view];
    [pan setTranslation:CGPointZero inView:self.view];
    
    if (fabs(translation.y) < fabs(translation.x))
        return;
    
    UITextView* textView = (UITextView*)cell.text;
    CGPoint contentOffset = textView.contentOffset;
    contentOffset.y -= translation.y;
    if (pan.state == UIGestureRecognizerStateEnded) {
        contentOffset.y = MAX(0.0, MIN(textView.contentSize.height - textView.bounds.size.height, contentOffset.y));
        [textView setContentOffset:contentOffset animated:YES];
    }
    else {
        [textView setContentOffset:contentOffset animated:NO];
    }
}
#endif
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    if (_layoutWidth == self.view.bounds.size.width)
        return;
    
    _layoutWidth = self.view.bounds.size.width;
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat space = TARGET_OS_IOS ? 8.0 : 32.0;
    layout.sectionInset = UIEdgeInsetsMake(space, space, space, space);
    layout.minimumLineSpacing = space;
    layout.minimumInteritemSpacing = space;
       
    CGRect rect = self.collectionView.bounds;
    rect = UIEdgeInsetsInsetRect(rect, layout.sectionInset);
    rect.size.height -= self.collectionView.safeAreaInsets.top;
    rect.size.width  -= self.collectionView.safeAreaInsets.left + self.collectionView.safeAreaInsets.right;
    
    NSURL* url = [ChooseGameController getGameImageURL:_game];
    UIImage* image = [[ImageCache sharedInstance] getImage:url size:CGSizeZero];
    CGFloat aspect = image.size.width > image.size.height ? 4.0/3.0 : 3.0/4.0;

    CGSize image_size = CGSizeMake(INFO_IMAGE_WIDTH, INFO_IMAGE_WIDTH / aspect);
    image_size.height = MIN(image_size.height, rect.size.height * 0.60);
    image_size.width  = image_size.height * aspect;
    
    _image = [image scaledToSize:image_size];
    
    BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height * 1.33;
    
    layout.scrollDirection = landscape ? UICollectionViewScrollDirectionHorizontal : UICollectionViewScrollDirectionVertical;

    self.collectionView.alwaysBounceVertical = !landscape;
    self.collectionView.alwaysBounceHorizontal = landscape;

    if (landscape)
        rect.size.width -= image_size.width + space;

    layout.itemSize = rect.size;

    CGFloat firstItemHeight = [self collectionView:self.collectionView layout:layout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].height;
    _titleSwitchOffset= firstItemHeight + space - self.collectionView.adjustedContentInset.top;
    
    [self.collectionView reloadData];
}
#if TARGET_OS_IOS
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    UILabel* title = (UILabel*)self.navigationItem.titleView;
    
    if (scrollView.contentOffset.y <= _titleSwitchOffset && title.text == self.title)
        return; // -- no change to title

    if (scrollView.contentOffset.y > _titleSwitchOffset && title.text != self.title)
        return; // -- no change to title
    
    // add a push animation
    CATransition *animation = [CATransition new];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionPush;
    animation.subtype = (scrollView.contentOffset.y > _titleSwitchOffset) ? kCATransitionFromTop : kCATransitionFromBottom;
    animation.duration = 0.5;
    [title.layer addAnimation:animation forKey:kCATransitionPush];
    title.superview.clipsToBounds = YES;
 
    title.attributedText = [ChooseGameController getGameText:_game layoutMode:LayoutSmall textAlignment:NSTextAlignmentCenter];
    [title sizeToFit];
    if (scrollView.contentOffset.y <= _titleSwitchOffset) {
        title.text = self.title;
        title.transform = CGAffineTransformIdentity;
    }
    else {
        CGFloat scale = MIN(44.0 / title.bounds.size.height, 1.0);
        title.transform = CGAffineTransformMakeScale(scale, scale);
    }
}
#endif
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;   // Image+Metadata, History, MAME Info
}
- (NSAttributedString*)getText:(NSIndexPath*)indexPath {
    
    if (indexPath.item == 0)
        return [ChooseGameController getGameText:_game layoutMode:LayoutLarge textAlignment:NSTextAlignmentCenter];
    
    NSAttributedString* text = _game[indexPath.item == 1 ? kGameInfoHistory : kGameInfoMameInfo];
    
    // add a title to the top of the text
    if (text != nil) {
        NSString* title = indexPath.item == 1 ? @"History" : @"MAME Info";
        
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.alignment = NSTextAlignmentCenter;
        paragraph.paragraphSpacing = 4.0;

        NSMutableAttributedString* new_text = [[NSMutableAttributedString alloc] initWithString:[title stringByAppendingString:@"\n"] attributes:@{
            NSFontAttributeName:INFO_TITLE_FONT,
            NSForegroundColorAttributeName:INFO_TITLE_COLOR,
            NSParagraphStyleAttributeName: paragraph
        }];
        
        [new_text appendAttributedString:text];
        text = new_text;
    }
    
    return text;
}
- (BOOL)collectionView:(UICollectionView *)collectionView canFocusItemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.item != 0;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSAttributedString* text = [self getText:indexPath];
    
    if ([text length] == 0)
        return CGSizeZero;
    
    CGSize size = CGSizeMake(layout.itemSize.width, CGFLOAT_MAX);
    
    if (indexPath.item == 0 && layout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
        size.width = _image ? _image.size.width : INFO_IMAGE_WIDTH;

    // compute the size of the text, dont forget to account for insets
    size.width -= INFO_INSET_X * 2;
    CGSize textSize = [text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    size.height = textSize.height;
    size.width += INFO_INSET_X * 2;
    size.height = INFO_INSET_Y + ceil(size.height) + INFO_INSET_Y;

    // item zero is the title image and metadata text
    if (indexPath.item == 0) {
        size.height += _image.size.height;
        size.width = MAX(ceil(textSize.width) + INFO_INSET_X * 2, _image.size.width);
        return size;
    }
    
    // item 1 and 2 are just large text (HISTORY, MAMEINFO) in landscape they are fixed size
    if (layout.scrollDirection == UICollectionViewScrollDirectionHorizontal)
        return layout.itemSize;

    // in portrait that are as tall as they need to be....
    return size;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    GameCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    
    // a UILabel cant (or wont) hold this much text, so replace UILabel with a UITextView
    if (![cell.text isKindOfClass:[TextLabel class]]) {
        TextLabel* textView = [[TextLabel alloc] init];
        NSAssert([cell.text.superview isKindOfClass:[UIStackView class]], @"ack!");
        [(UIStackView*)cell.text.superview addArrangedSubview:textView];
        [cell.text removeFromSuperview];
        cell.text = (UILabel*)textView;
    }

    NSAttributedString* text = [self getText:indexPath];

    if (indexPath.item == 0) {
        cell.image.image = _image;
        cell.contentView.backgroundColor = self.collectionView.backgroundColor;
        [cell setBorderWidth:0.0];
        [cell setCornerRadius:0.0];
    }
    
    if ([text length] != 0)
        [cell setTextInsets:UIEdgeInsetsMake(INFO_INSET_Y, INFO_INSET_X, INFO_INSET_Y, INFO_INSET_X)];
    else
        [cell setTextInsets:UIEdgeInsetsZero];

    cell.text.attributedText = text;

    // always enable scrolling even if we dont need to, or UITextView may not draw on pre-iOS13
    [(TextLabel*)cell.text setScrollEnabled:YES];

    return cell;
}
@end






