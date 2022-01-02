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
#import "GameInfo.h"
#import "SoftwareList.h"
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
#if (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)
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
#define TITLE_COLOR             [UIColor whiteColor]
#define HEADER_TEXT_COLOR       [UIColor whiteColor]
#define HEADER_BACKGROUND_COLOR [UIColor clearColor]
#define HEADER_SELECTED_COLOR   [self.tintColor colorWithAlphaComponent:0.333]
#define HEADER_PINNED_COLOR     [BACKGROUND_COLOR colorWithAlphaComponent:0.8]

#define BACKGROUND_COLOR        [UIColor colorWithWhite:0.066 alpha:1.0]

#define CELL_SHADOW_COLOR       UIColor.clearColor
#define CELL_BACKGROUND_COLOR   UIColor.clearColor

#define CELL_SELECTED_SHADOW_COLOR      UIColor.clearColor
#define CELL_SELECTED_BACKGROUND_COLOR  UIColor.clearColor
#define CELL_SELECTED_BORDER_COLOR      [self.tintColor colorWithAlphaComponent:0.800]
#define CELL_SELECTED_BORDER_WIDTH      4.0

#define CELL_CORNER_RADIUS      16.0
#define CELL_BORDER_WIDTH       0.0
#define CELL_TEXT_ALIGN         NSTextAlignmentCenter

#if (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)
#define CELL_TITLE_FONT         [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
#define CELL_TITLE_COLOR        [UIColor whiteColor]
#define CELL_CLONE_COLOR        [UIColor colorWithWhite:0.555 alpha:1.0]
#define CELL_DETAIL_FONT        [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
#define CELL_DETAIL_COLOR       [UIColor colorWithWhite:0.333 alpha:1.0]
#define CELL_MAX_LINES          3
#else   // tvOS and mac
#define CELL_TITLE_FONT         [UIFont boldSystemFontOfSize:20.0]
#define CELL_TITLE_COLOR        [UIColor whiteColor]
#define CELL_CLONE_COLOR        [UIColor colorWithWhite:0.555 alpha:1.0]
#define CELL_DETAIL_FONT        [UIFont systemFontOfSize:20.0]
#define CELL_DETAIL_COLOR       [UIColor colorWithWhite:0.333 alpha:1.0]
#define CELL_MAX_LINES          3
#endif

// Section insets and spacing
#if (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)
#define SECTION_INSET_X         8.0
#define SECTION_INSET_Y         8.0
#define SECTION_LINE_SPACING    8.0
#define SECTION_ITEM_SPACING    8.0
#else   // tvOS or mac
#define SECTION_INSET_X         8.0
#define SECTION_INSET_Y         32.0
#define SECTION_LINE_SPACING    48.0
#define SECTION_ITEM_SPACING    32.0
#endif

#define INFO_BACKGROUND_COLOR   [UIColor colorWithWhite:0.111 alpha:1.0]
#define INFO_IMAGE_WIDTH        (TARGET_OS_IOS ? 260.0 : 580.0)
#define INFO_INSET_X            8.0
#define INFO_INSET_Y            8.0

#if (TARGET_OS_IOS && !TARGET_OS_MACCATALYST)
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
#define ALL_SCOPES          @[@"System", @"Clones", @"Manufacturer", @"Year", @"Genre", @"Driver"]
#define RECENT_GAMES_MAX    8

#define SECTIONS_COLLAPSED_KEY    @"CollapsedSections"

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
    BOOL _isSearchResults;      // TRUE when we are used as a search results controller on tvOS
    NSArray* _key_commands;
    BOOL _searchCancel;
    NSIndexPath* _currentlyFocusedIndexPath;
    UIImage* _defaultImage;
    UIImage* _loadingImage;
    NSMutableSet* _updated_urls;
    InfoDatabase* _history;
    InfoDatabase* _mameinfo;
    NSCache* _system_description;
}
@end

@implementation ChooseGameController

+ (NSArray<NSString*>*) allSettingsKeys {
    return @[LAYOUT_MODE_KEY, SCOPE_MODE_KEY, RECENT_GAMES_KEY, FAVORITE_GAMES_KEY, SECTIONS_COLLAPSED_KEY];
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
    
#if TARGET_OS_TV
    UIColor* color = UIApplication.sharedApplication.keyWindow.tintColor;
    [seg2 setTitleTextAttributes:@{NSForegroundColorAttributeName:color} forState:UIControlStateNormal];
    [seg2 setTitleTextAttributes:@{NSForegroundColorAttributeName:color} forState:UIControlStateSelected];
#endif
    
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
    resultsController->_isSearchResults = TRUE;
    // search results are always grouped by `System`
    resultsController->_gameFilterScope = SCOPE_MODE_DEFAULT;
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
    // remove any snapshots
    games = [games filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K != %@", kGameInfoType, kGameInfoTypeSnapshot]];
    
    // add all snapshots on disk
    for (NSString* snap in [NSFileManager.defaultManager enumeratorAtPath:getDocumentPath(@"snap")].allObjects) {
        
        if (![snap.pathExtension.lowercaseString isEqualToString:@"png"] || snap.stringByDeletingLastPathComponent.length == 0)
            continue;
        
        games = [games arrayByAddingObject:@{
            kGameInfoType:kGameInfoTypeSnapshot,
            kGameInfoFile:snap,
            kGameInfoManufacturer:snap.lastPathComponent.stringByDeletingPathExtension,
            kGameInfoName:snap.stringByDeletingLastPathComponent.lastPathComponent,
            kGameInfoDescription:snap.stringByDeletingLastPathComponent.lastPathComponent,
        }];
    }

    // sort the list by description
    _gameList = [games sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kGameInfoDescription ascending:TRUE]]];
    
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

#pragma mark - game filter

- (NSString*)getSystemDescription:(NSString*)system {
    
    NSParameterAssert(system.length != 0);
    
    _system_description = _system_description ?: [[NSCache alloc] init];
    NSString* description = [_system_description objectForKey:system];

    if (description == nil) {
        // find the system in the gameList
        NSDictionary* game = [_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kGameInfoName, system]].firstObject;
        description = game[kGameInfoDescription] ?: system;
        [_system_description setObject:description forKey:system];
    }
    
    return description;
}

- (void)filterGameList
{
    NSArray* filteredGames = _gameList;
    
    // when search is active, empty search string will find zero games
    if (_isSearchResults && [_gameFilterText length] == 0)
        filteredGames = @[];
    
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
    BOOL clones = FALSE;
    
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
    if ([_gameFilterScope isEqualToString:@"System"])
        key = kGameInfoSystem;
    if ([_gameFilterScope isEqualToString:@"Type"])
        key = kGameInfoType;
    if ((clones = [_gameFilterScope isEqualToString:@"Clones"]))
        key = kGameInfoSystem;

    for (NSDictionary* game in filteredGames) {
        NSString* section = game[key];
        
        // a UICollectionView will scroll like crap if we have too many sections, so try to filter/combine similar ones.
        if (key != (void*)kGameInfoCategory)
            section = [[section componentsSeparatedByString:@" ("] firstObject];
        section = [section stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (key != (void*)kGameInfoYear)
            section = [section stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
        
        // if we dont have a parent, we are our own parent!
        if (key == (void*)kGameInfoParent && [section length] <= 1)
            section = game.gameName;
        
        if ([section length] != 0 && key == (void*)kGameInfoSystem)
            section = [self getSystemDescription:section];

        if ([section length] == 0 && key == (void*)kGameInfoSystem)
            section = game.gameType;
        
        if ([section length] != 0 && clones && game.gameIsClone)
            section = [NSString stringWithFormat:@"%@ • Clones", section];
        
        if ([section length] == 0)
            section = @"Unknown";
        
        NSArray* sections;
        if (key == (void*)kGameInfoCategory)
            sections = [section componentsSeparatedByString:@","];
        else
            sections = @[section];

        for (NSString* section in sections) {
            if (gameData[section] == nil)
                gameData[section] = [[NSMutableArray alloc] init];
            [gameData[section] addObject:game];
        }
    }

    // and sort section names
    NSArray* gameSectionTitles = [gameData.allKeys sortedArrayUsingSelector:@selector(localizedCompare:)];
    
    // move Computer(s) and Console(s) etc to the end
    for (NSString* title in @[kGameInfoTypeConsole, kGameInfoTypeComputer, kGameInfoTypeBIOS, @"Unknown"]) {
        if ([gameSectionTitles containsObject:title]) {
            gameSectionTitles = [gameSectionTitles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", title]];
            gameSectionTitles = [gameSectionTitles arrayByAddingObject:title];
        }
    }

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
    
    // dont add Recents or Favorites when we are searching
    if (!_isSearchResults) {

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
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(SECTION_INSET_Y, SECTION_INSET_X, SECTION_INSET_Y, SECTION_INSET_X);
    layout.minimumLineSpacing = SECTION_LINE_SPACING;
    layout.minimumInteritemSpacing = SECTION_ITEM_SPACING;
    layout.sectionHeadersPinToVisibleBounds = YES;
    
#if TARGET_OS_MACCATALYST
    CGFloat height = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle].pointSize * 1.5;
#elif TARGET_OS_IOS
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
#if TARGET_OS_IOS
            if (@available(iOS 13.0, *))
                [cell addBlur:UIBlurEffectStyleDark];
            else
                cell.contentView.backgroundColor = HEADER_PINNED_COLOR;
#else
            cell.contentView.backgroundColor = HEADER_PINNED_COLOR;
#endif
        }
        else {
            cell.backgroundView = nil;
            cell.contentView.backgroundColor = HEADER_BACKGROUND_COLOR;
            cell.selected = cell.selected;  // update selected/focused state
        }
    }
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

- (BOOL)isRecent:(NSDictionary*)game
{
    NSArray* recentGames = [NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY] ?: @[];
    return [recentGames containsObject:game];
}
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
        NSString* title = game.gameTitle;
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
        if (![_updated_urls containsObject:game.gameLocalImageURL])
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


#pragma mark Section collapse

-(BOOL)isCollapsed:(NSInteger)section
{
    if (_isSearchResults)
        return FALSE;
    NSString* title = _gameSectionTitles[section];
    NSArray* sections = [NSUserDefaults.standardUserDefaults objectForKey:SECTIONS_COLLAPSED_KEY] ?: @[];
    return [sections containsObject:title];
}
- (void)setCollapsed:(NSInteger)section isCollapsed:(BOOL)flag
{
    NSString* title = _gameSectionTitles[section];
    NSMutableArray* sections = [([NSUserDefaults.standardUserDefaults objectForKey:SECTIONS_COLLAPSED_KEY] ?: @[]) mutableCopy];

    [sections removeObject:title];

    if (flag)
        [sections addObject:title];
    
    [NSUserDefaults.standardUserDefaults setObject:sections forKey:SECTIONS_COLLAPSED_KEY];
}

-(void)headerTap:(UITapGestureRecognizer*)sender
{
    NSLog(@"HEADER TAP: %d", (int)sender.view.tag);
    NSInteger section = sender.view.tag;
    if (section >= 0 && section < _gameSectionTitles.count)
    {
        [self setCollapsed:section isCollapsed:![self isCollapsed:section]];
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
        } completion:^(BOOL finished){
            [self kickLayout];
            [self performSelector:@selector(reloadData) withObject:nil afterDelay:0.250];
        }];
    }
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
    if ([self isCollapsed:section])
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
//  TINY        SMALL                       LARGE                       LIST
//  ----        -----                       -----                       ----
//  romname     short Description           Description                 Description
//              short Manufacturer • Year   short Manufacturer • Year   Manufacturer • Year  • romname [parent-rom]
//
+(NSAttributedString*)getGameText:(NSDictionary*)info layoutMode:(LayoutMode)layoutMode textAlignment:(NSTextAlignment)textAlignment badge:(NSString*)badge clone:(BOOL)clone
{
    NSString* title;
    NSString* detail;
    NSString* str;
    
    if (info[kGameInfoName] == nil || info[kGameInfoDescription] == nil)
        return nil;
    
    if (layoutMode == LayoutTiny) {
        title = @"";
        detail = info[kGameInfoName];
    }
    else if (layoutMode == LayoutSmall) {
        title = info.gameTitle;
        detail = [info[kGameInfoManufacturer] componentsSeparatedByString:@" ("].firstObject;

        if ((str = info[kGameInfoYear]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];
    }
    else if (layoutMode == LayoutLarge) {
        title = info[kGameInfoDescription];
        detail = [info[kGameInfoManufacturer] componentsSeparatedByString:@" ("].firstObject;

        if ((str = info[kGameInfoYear]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];
    }
    else { // LayoutList
        title = info[kGameInfoDescription];
        detail = info[kGameInfoManufacturer];

        if ((str = info[kGameInfoYear]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];
        
        if ((str = info[kGameInfoName]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];

        if ((str = info[kGameInfoParent]) && [str length] > 1)
            detail = [NSString stringWithFormat:@"%@ [%@]", detail, str];
    }
    
#ifdef XXDEBUG
    if (layoutMode != LayoutTiny)
        title = [NSString stringWithFormat:@" Blah Blah Blah %@ Blah Blah Blah Blah Blah Blah", title];
#endif

    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName:CELL_TITLE_FONT,
        NSForegroundColorAttributeName:clone ? CELL_CLONE_COLOR : CELL_TITLE_COLOR
    }];

    if (detail != nil)
    {
        if (text.length != 0)
            detail = [@"\n" stringByAppendingString:detail];

        [text appendAttributedString:[[NSAttributedString alloc] initWithString:detail attributes:@{
            NSFontAttributeName:CELL_DETAIL_FONT,
            NSForegroundColorAttributeName:CELL_DETAIL_COLOR
        }]];
    }
    
    if (@available(iOS 13.0, tvOS 13.0, *))
    {
        if (badge.length != 0)
        {
            UIFont* text_font = [text attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
            UIFont* badge_font = [UIFont systemFontOfSize:text_font.pointSize * 0.5];
            CGFloat dy = floor((text_font.capHeight - badge_font.capHeight) / 2);
            
            UIImage* image = [UIImage systemImageNamed:badge withFont:badge_font];
            NSTextAttachment* att = [[NSTextAttachment alloc] init];
            att.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            NSMutableAttributedString* badge_text = [[NSAttributedString attributedStringWithAttachment:att] mutableCopy];
            [badge_text addAttributes:@{
                NSForegroundColorAttributeName:UIColor.systemBlueColor,
                NSBaselineOffsetAttributeName:@(dy)} range:NSMakeRange(0, badge_text.length)];

            [text insertAttributedString:[[NSAttributedString alloc] initWithString:@"\u2009"] atIndex:0];  // U+2009 Thin Space
            [text insertAttributedString:badge_text atIndex:0];
        }
    }
    
    if (textAlignment != NSTextAlignmentLeft)
    {
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        [paragraph setAlignment:textAlignment];
        [text addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
    }
    
    return [text copy];
}

+(NSAttributedString*)getGameText:(NSDictionary*)game layoutMode:(LayoutMode)layoutMode
{
    return [self getGameText:game layoutMode:layoutMode textAlignment:NSTextAlignmentCenter badge:nil clone:NO];
}

+(NSAttributedString*)getGameText:(NSDictionary*)game
{
    return [self getGameText:game layoutMode:LayoutLarge];
}

-(NSAttributedString*)getGameText:(NSDictionary*)game
{
    return [[self class] getGameText:game layoutMode:_layoutMode
                       textAlignment:_layoutMode == LayoutList ? NSTextAlignmentLeft : CELL_TEXT_ALIGN
                               badge:[self isFavorite:game] ? @"star.fill" : @""
                               clone:game.gameParent.length != 0];
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
    
    // get the screen, assume the game is 4:3 if we dont know.
    BOOL is_vert = [info.gameScreen containsString:kGameInfoScreenVertical];

    if (is_vert)
        image_height = ceil(item_width * 4.0 / 3.0);
    else
        image_height = ceil(item_width * 3.0 / 4.0);

    // get the text height
    CGSize textSize = CGSizeMake(item_width - CELL_INSET_X*2, 9999.0);
    
    // in LayoutTiny we only show one line.
    if (_layoutMode == LayoutTiny)
        textSize.width = 9999.0;
    
    textSize = [text boundingRectWithSize:textSize options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;

    // in LayoutSmall we only show `CELL_MAX_LINES` lines
    if (CELL_MAX_LINES != 0 && (_layoutMode == LayoutSmall || _layoutMode == LayoutLarge) && _layoutCollums > 1)
        textSize.height = MIN(textSize.height, ceil(CELL_TITLE_FONT.lineHeight) * CELL_MAX_LINES);

    text_height = CELL_INSET_Y + ceil(textSize.height) + CELL_INSET_Y;
    
    NSLog(@"heightForItemAtIndexPath: %d.%d %@ -> %@", (int)indexPath.section, (int)indexPath.item, info[kGameInfoName], NSStringFromCGSize(CGSizeMake(image_height, text_height)));
    return CGPointMake(image_height, text_height);
}

// compute (or return from cache) the height(s) of a single row.
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

    // go over each item in the row and compute the MIN image_height and MAX text_height
    // the idea is if all the items in the row are 3:4 then go with that, else use 4:3
    CGPoint row_height = CGPointZero;
    for (NSUInteger item = row_start; item < row_end; item++) {
        CGPoint item_height = [self heightForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
        row_height.x = (row_height.x == 0.0) ? item_height.x : MIN(row_height.x, item_height.x);
        row_height.y = MAX(row_height.y, item_height.y);
    }
    
    NSLog(@"heightForRow: %d.%d -> %@ = %f", (int)indexPath.section, (int)indexPath.item, NSStringFromCGPoint(row_height), row_height.x + row_height.y);
    _layoutRowHeightCache = _layoutRowHeightCache ?: [[NSMutableDictionary alloc] init];
    _layoutRowHeightCache[indexPath] = [NSValue valueWithCGPoint:row_height];
    return row_height;
}

// load image from *one* of a list of urls
-(void)getImage:(NSArray*)urls localURL:(NSURL*)localURL completionHandler:(void (^)(UIImage* image))handler
{
    if (urls.count == 0)
        return handler(nil);
    
    [ImageCache.sharedInstance getImage:urls.firstObject size:CGSizeZero localURL:localURL completionHandler:^(UIImage *image) {
        if (image != nil)
           handler(image);
        else
           [self getImage:[urls subarrayWithRange:NSMakeRange(1, urls.count-1)] localURL:localURL completionHandler:handler];
    }];
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
        cell.text.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    if ((_layoutMode == LayoutSmall || _layoutMode == LayoutLarge) && _layoutCollums > 1) {
        cell.text.numberOfLines = CELL_MAX_LINES;
        cell.text.lineBreakMode = NSLineBreakByTruncatingTail;
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

    NSArray* urls = info.gameImageURLs;
    NSURL* localURL = info.gameLocalImageURL;

    cell.tag = localURL.hash;
    [self getImage:urls localURL:localURL completionHandler:^(UIImage *image) {
        
        // cell has been re-used bail
        if (cell.tag != localURL.hash)
            return;
        
        // if this is syncronous set image and be done
        if (cell.image.image == nil) {
            
            image = image ?: self->_defaultImage;
            
            // MAME games always ran on horz or vertical CRTs so it does not matter what the PAR of
            // the title image is force a aspect of 3:4 or 4:3
            
            BOOL is_vert = [info.gameScreen containsString:kGameInfoScreenVertical];
            
            if (self->_layoutMode == LayoutList) {
                CGFloat aspect = 4.0 / 3.0;
                [cell setImageAspect:aspect];
                if (is_vert)
                    cell.image.contentMode = UIViewContentModeScaleAspectFill;
            }
            else if (row_height.x != 0.0) {
                CGFloat aspect = (cell.bounds.size.width / row_height.x);
                [cell setImageAspect:aspect];
                if (is_vert && aspect > 1.0)
                    cell.image.contentMode = UIViewContentModeScaleAspectFill;
            }
            else {
                CGFloat aspect = is_vert ? (3.0 / 4.0) : (4.0 / 3.0);
                [cell setImageAspect:aspect];
            }
            
            if (info.gameIsSnapshot)
                cell.image.contentMode = UIViewContentModeScaleAspectFill;
 
            cell.image.image = image;
            return;
        }
        
        NSLog(@"CELL ASYNC LOAD: %@ %d:%d", info[kGameInfoName], (int)indexPath.section, (int)indexPath.item);
        [self updateImage:localURL];
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

// make an attributed string, replacing any :symbol: with an SF Symbol
NSAttributedString* attributedString(NSString* text, UIFont* font, UIColor* color) {
    NSDictionary* attributes = @{NSFontAttributeName:font,NSForegroundColorAttributeName:color};
    UIImage* image = nil;
    NSArray* arr = [text componentsSeparatedByString:@":"];
    
    if (arr.count != 3 || (image = [UIImage systemImageNamed:arr[1] withFont:font]) == nil)
        return [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    NSMutableAttributedString* result = [[NSMutableAttributedString alloc] initWithString:arr[0] attributes:attributes];
    
    NSTextAttachment* att = [[NSTextAttachment alloc] init];
    att.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [result appendAttributedString:[NSAttributedString attributedStringWithAttachment:att]];

    [result appendAttributedString:[[NSAttributedString alloc] initWithString:arr[2] attributes:attributes]];

    return [result copy];
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
    
    // make the section title tappable to toggle collapse/expand section
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        BOOL is_collapsed = [self isCollapsed:indexPath.section];
        
        // dont allow collapse if we only have a single (+MAME) section
        if (!_isSearchResults && (_gameSectionTitles.count >= 2 || is_collapsed))
        {
            // only show a chevron if collapsed?
            if (is_collapsed)
            {
                NSString* str = [NSString stringWithFormat:@"%@ :%@:", cell.text.text, is_collapsed ? @"chevron.right" : @"chevron.down"];
                cell.text.attributedText = attributedString(str, cell.text.font, cell.text.textColor);
            }
            // install tap handler to toggle collapsed
            cell.tag = indexPath.section;
            [cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerTap:)]];
        }
    }
        
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* game = [self getGameInfo:indexPath];
    
    NSLog(@"DID SELECT ITEM[%d.%d] %@", (int)indexPath.section, (int)indexPath.item, game[kGameInfoName]);
    
    if (game.gameIsSnapshot)
        return;
    
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
        NSURL* url = game.gameLocalImageURL;

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
        for (NSURL* url in game.gameImageURLs)
            [ImageCache.sharedInstance cancelImage:url];
    }
}

#pragma mark - game context menu actions...

// get the files associated with a game, if allFiles is NO only the settings files are returned.
// file paths are relative to our document root.
-(NSArray*)getGameFiles:(NSDictionary*)game allFiles:(BOOL)all
{
    NSString* name = game.gameName;
    
    if (game.gameSoftwareList.length != 0)
        name = [game.gameSoftwareList stringByAppendingPathComponent:name];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    for (NSString* file in @[@"titles/%@.png", @"cfg/%@.cfg", @"ini/%@.ini", @"sta/%@/1.sta", @"sta/%@/2.sta", @"hi/%@.hi", @"hiscore/%@.hi",
                             @"nvram/%@.nv", @"inp/%@.inp", @"snap/%@.png", @"snap/%@.mng", @"snap/%@.avi", @"snap/%@/"])
        [files addObject:[NSString stringWithFormat:file, name]];
    
    if (all) {
        for (NSString* file in @[@"roms/%@.zip", @"roms/%@.7z", @"roms/%@/%@.chd", @"roms/%@/", @"artwork/%@.zip", @"samples/%@.zip"])
            [files addObject:[NSString stringWithFormat:file, name, name]];
    }

    // if we are a parent ROM include all of our clones
    if (game.gameParent.length <= 1 && all) {
        NSArray* clones = [_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", kGameInfoSystem, game[kGameInfoSystem], kGameInfoParent, game.gameName]];
        for (NSDictionary* clone in clones) {
            // TODO: check if this is a merged romset??
            [files addObjectsFromArray:[self getGameFiles:clone allFiles:YES]];
        }
    }
    
    return files;
}

-(void)delete:(NSDictionary*)game
{
    NSString* title = [self menuTitleForGame:game];
    NSString* message = nil;

    [self showAlertWithTitle:title message:message buttons:@[@"Delete Settings", @"Delete Files", @"Cancel"] handler:^(NSUInteger button) {
        
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
        
        for (NSURL* url in game.gameImageURLs)
            [ImageCache.sharedInstance flush:url size:CGSizeZero];
        
        if (allFiles) {
            [self setRecent:game isRecent:FALSE];
            [self setFavorite:game isFavorite:FALSE];
            
            NSArray* list = [self->_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", game]];

            // if this is a parent romset, delete all the clones too.
            if (game.gameParent.length <= 1)
                list = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (%K == %@ AND %K == %@)", kGameInfoSystem, game[kGameInfoSystem], kGameInfoParent, game.gameName]];
            
            // TODO: if you delete a machine/system shoud we delete all the Software too?

            [self setGameList:list];

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
    NSString* title = [NSString stringWithFormat:@"%@ (%@)",game.gameTitle, game.gameName];
    
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
    game[kGameInfoHistory] = [_history attributedStringForKey:game.gameName attributes:atributes] ?:
                             [_history attributedStringForKey:game.gameParent attributes:atributes];
    game[kGameInfoMameInfo] = [_mameinfo attributedStringForKey:game.gameName attributes:atributes] ?:
                              [_mameinfo attributedStringForKey:game.gameParent attributes:atributes];

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
    NSString* title = [NSString stringWithFormat:@"Play %@", game.gameTitle];
    
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
    [self getImage:game.gameImageURLs localURL:game.gameLocalImageURL completionHandler:^(UIImage *image) {}];

    NSLog(@"menuActionsForItemAtIndexPath: [%d.%d] %@ %@", (int)indexPath.section, (int)indexPath.row, game[kGameInfoName], game);
    
    if (game.gameIsSnapshot) {
        return @[
            [self actionWithTitle:@"Use as Title Image" image:[UIImage systemImageNamed:@"photo"] destructive:NO handler:^(id action) {
                NSString* src = game.gameLocalImageURL.path;
                NSString* dst = [NSString stringWithFormat:@"%@/%@.png", getDocumentPath(@"titles"), game.gameFile.stringByDeletingLastPathComponent];
                [NSFileManager.defaultManager removeItemAtPath:dst error:nil];
                [NSFileManager.defaultManager copyItemAtPath:src toPath:dst error:nil];
                [ImageCache.sharedInstance flush];
                [self updateImage:[NSURL fileURLWithPath:dst]];
            }],
#if TARGET_OS_IOS
            [self actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] destructive:NO handler:^(id action) {
                NSURL* url = game.gameLocalImageURL;
                UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
                activity.popoverPresentationController.sourceView = self.view;
                activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0.0f, 0.0f);
                activity.popoverPresentationController.permittedArrowDirections = 0;
                [self presentViewController:activity animated:YES completion:nil];
            }],
#endif
            [self actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] destructive:YES handler:^(id action) {
                [NSFileManager.defaultManager removeItemAtPath:game.gameLocalImageURL.path error:nil];
                [self setGameList:self->_gameList];
            }]
        ];
    }
    
    BOOL is_fav = [self isFavorite:game];
    
    NSString* fav_text = is_fav ? @"Unfavorite" : @"Favorite";
    NSString* fav_icon = is_fav ? @"star.slash" : @"star";
    
    NSArray* actions = @[
        [self actionWithTitle:@"Play" image:[UIImage systemImageNamed:@"gamecontroller"] destructive:NO handler:^(id action) {
            [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
        }],
        
        [self actionWithTitle:fav_text image:[UIImage systemImageNamed:fav_icon] destructive:NO handler:^(id action) {
            [self setFavorite:game isFavorite:!is_fav];
            [self filterGameList];
        }],
    ];
    
    if ([self isRecent:game]) {
        actions = [actions arrayByAddingObjectsFromArray:@[
            [self actionWithTitle:@"Remove from Recently Played" image:[UIImage systemImageNamed:@"minus.circle"] destructive:NO handler:^(id action) {
                [self setRecent:game isRecent:NO];
                [self filterGameList];
            }]
        ]];
    }
    
    if ([_history boolForKey:game.gameName]   || [_mameinfo boolForKey:game.gameName] ||
        [_history boolForKey:game.gameParent] || [_mameinfo boolForKey:game.gameParent]) {
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

    if (!game.gameIsFake) {
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
    return [ChooseGameController getGameText:game layoutMode:LayoutList].string;
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
    
    self.view.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    
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

- (BOOL)collectionView:(UICollectionView *)collectionView canFocusItemAtIndexPath:(NSIndexPath *)indexPath {
    // always set focus to the first collum when jumping from non indexPath to indexPath focus item
    if (_currentlyFocusedIndexPath == nil && _layoutCollums > 1)
        return (indexPath.item % _layoutCollums) == 0;
    else
        return TRUE;
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
- (void)onCommandExit  { }
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
        while ([self.collectionView numberOfItemsInSection:section] == 0 && section > 0)
            section--;
        item = (([self.collectionView numberOfItemsInSection:section] + _layoutCollums-1) / _layoutCollums - 1) * _layoutCollums + col;
    }
    else if (new_row >= num_rows && section+1 < self.collectionView.numberOfSections)
    {
        section++;
        while ([self.collectionView numberOfItemsInSection:section] == 0 && section+1 < self.collectionView.numberOfSections)
            section++;
        item = col;
    }
    
    section = CLAMP(section, self.collectionView.numberOfSections);
    item = CLAMP(item, [self.collectionView numberOfItemsInSection:section]);

    indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    if ([self.collectionView numberOfItemsInSection:section] != 0)
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
    
    if (_searchController.isActive || self.presentedViewController != nil)
        return @[];
    
    if (_key_commands == nil) {
        _key_commands = @[
            // standard keyboard
            [UIKeyCommand keyCommandWithInput:@"\r"                 modifierFlags:0 action:@selector(onCommandSelect)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow     modifierFlags:0 action:@selector(onCommandUp)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow   modifierFlags:0 action:@selector(onCommandDown)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow   modifierFlags:0 action:@selector(onCommandLeft)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow  modifierFlags:0 action:@selector(onCommandRight)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputEscape      modifierFlags:0 action:@selector(onCommandExit)],
            // iCade
            [UIKeyCommand keyCommandWithInput:@"y" modifierFlags:0 action:@selector(onCommandSelect)], // SELECT
            [UIKeyCommand keyCommandWithInput:@"h" modifierFlags:0 action:@selector(onCommandSelect)], // START
            [UIKeyCommand keyCommandWithInput:@"k" modifierFlags:0 action:@selector(onCommandSelect)], // A
            [UIKeyCommand keyCommandWithInput:@"w" modifierFlags:0 action:@selector(onCommandUp)],
            [UIKeyCommand keyCommandWithInput:@"x" modifierFlags:0 action:@selector(onCommandDown)],
            [UIKeyCommand keyCommandWithInput:@"a" modifierFlags:0 action:@selector(onCommandLeft)],
            [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:0 action:@selector(onCommandRight)],
        ];
        
#ifdef __IPHONE_15_0
        if (@available(iOS 15.0, *)) {
            for (UIKeyCommand* key_command in _key_commands)
                key_command.wantsPriorityOverSystemBehavior = YES;
        }
#endif
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
    _text.lineBreakMode = NSLineBreakByTruncatingTail;
    _text.adjustsFontSizeToFitWidth = FALSE;
    _text.textAlignment = NSTextAlignmentLeft;
#ifdef XDEBUG
    _text.backgroundColor = UIColor.systemPinkColor;
#endif

    _height = 0.0;

    _image.image = nil;
    _image.highlightedImage = nil;
    _image.contentMode = UIViewContentModeScaleAspectFit;
    _image.layer.minificationFilter = kCAFilterTrilinear;
    _image.layer.minificationFilterBias = 0.0;
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
    
    // remove any GRs
    while (self.gestureRecognizers.firstObject != nil)
        [self removeGestureRecognizer:self.gestureRecognizers.firstObject];
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
        self.layer.cornerRadius = 0.0;
        self.contentView.layer.cornerRadius = 0.0;
        self.contentView.clipsToBounds = NO;
        _image.layer.cornerRadius = radius;
        _image.clipsToBounds = YES; // radius != 0.0;
    }
    else {
        self.layer.cornerRadius = radius;
        self.contentView.layer.cornerRadius = radius;
        self.contentView.clipsToBounds = radius != 0.0;
        _image.layer.cornerRadius = 0.0;
        _image.clipsToBounds = YES; // NO;
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
    if (_image.image == nil) {
#if TARGET_OS_TV
        // GameInfoController will change this class, so ignore that case
        if ([_text isKindOfClass:[UILabel class]])
            self.contentView.backgroundColor = selected ? HEADER_SELECTED_COLOR : HEADER_BACKGROUND_COLOR;
#endif
        return;
    }
    
    [self setBackgroundColor:selected ? CELL_SELECTED_BACKGROUND_COLOR : CELL_BACKGROUND_COLOR];
    [self setShadowColor:selected ? CELL_SELECTED_SHADOW_COLOR : CELL_SHADOW_COLOR];
    
    if (CELL_SELECTED_BORDER_COLOR != UIColor.clearColor) {
        [_image.layer setBorderWidth:selected ? CELL_SELECTED_BORDER_WIDTH : 0.0];
        [_image.layer setBorderColor:(selected ? CELL_SELECTED_BORDER_COLOR : UIColor.clearColor).CGColor];
    }
    CGFloat scale = selected ? _scale : self.highlighted ? (2.0 - _scale) : 1.0;
    _stackView.transform = CGAffineTransformMakeScale(scale, scale);
#if TARGET_OS_TV
    if (selected)
        [self.superview bringSubviewToFront:self];
    else
        [self.superview sendSubviewToBack:self];
#endif
}
- (void)setHighlighted:(BOOL)highlighted
{
    NSLog(@"setHighlighted(%@): %@", [self.text.text stringByReplacingOccurrencesOfString:@"\n" withString:@" • "], highlighted ? @"YES" : @"NO");
    [super setHighlighted:highlighted];
    [self updateSelected];
}
- (void)setSelected:(BOOL)selected
{
    NSLog(@"setSelected(%@): %@", [self.text.text stringByReplacingOccurrencesOfString:@"\n" withString:@" • "] , selected ? @"YES" : @"NO");
    [super setSelected:selected];
    [self updateSelected];
}

#if TARGET_OS_TV
- (BOOL)canBecomeFocused {
    // we want headers with a tap GR to get the focus
    if (self.gestureRecognizers.count != 0)
        return YES;
    return [super canBecomeFocused];
}
- (void)didHintFocusMovement:(UIFocusMovementHint *)hint {
    NSLog(@"didHintFocusMovement(%@): dir=%@", [self.text.text stringByReplacingOccurrencesOfString:@"\n" withString:@" • "],
          NSStringFromCGVector(hint.movementDirection));
    if (_image.image == nil)
        return;
    [self updateSelected];
    _stackView.transform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(hint.translation.dx, hint.translation.dy), _stackView.transform);
}
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
@property(nonatomic) NSLineBreakMode lineBreakMode;
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
    layout.sectionInset = UIEdgeInsetsMake(SECTION_INSET_Y, SECTION_INSET_X, SECTION_INSET_Y, SECTION_INSET_X);
    layout.minimumLineSpacing = SECTION_LINE_SPACING;
    layout.minimumInteritemSpacing = SECTION_ITEM_SPACING;
       
    CGRect rect = self.collectionView.bounds;
    rect = UIEdgeInsetsInsetRect(rect, layout.sectionInset);
    rect.size.height -= self.collectionView.safeAreaInsets.top;
    rect.size.width  -= self.collectionView.safeAreaInsets.left + self.collectionView.safeAreaInsets.right;
    
    UIImage* image = [[ImageCache sharedInstance] getImage:_game.gameImageURLs.firstObject size:CGSizeZero];
    CGFloat aspect = [_game.gameScreen containsString:kGameInfoScreenVertical] ? 3.0/4.0 : 4.0/3.0;

    CGSize image_size = CGSizeMake(INFO_IMAGE_WIDTH, INFO_IMAGE_WIDTH / aspect);
    image_size.height = MIN(image_size.height, rect.size.height * 0.60);
    image_size.width  = image_size.height * aspect;
    
    _image = [image scaledToSize:image_size];
    
    BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height * 1.33;
    
    layout.scrollDirection = landscape ? UICollectionViewScrollDirectionHorizontal : UICollectionViewScrollDirectionVertical;

    self.collectionView.alwaysBounceVertical = !landscape;
    self.collectionView.alwaysBounceHorizontal = landscape;

    if (landscape)
        rect.size.width -= image_size.width + SECTION_ITEM_SPACING;

    layout.itemSize = rect.size;

    CGFloat firstItemHeight = [self collectionView:self.collectionView layout:layout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].height;
    _titleSwitchOffset= firstItemHeight + SECTION_INSET_Y - self.collectionView.adjustedContentInset.top;
    
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
 
    title.attributedText = [ChooseGameController getGameText:_game];
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
        return [ChooseGameController getGameText:_game layoutMode:LayoutList];
    
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






