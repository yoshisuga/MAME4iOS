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
#import "Alert.h"
#import "Globals.h"
#import "MAME4iOS-Swift.h"
#import "libmame.h"

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
#define HEADER_IDENTIFIER   @"GameInfoHeader"

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

#define CELL_BACKGROUND_COLOR   UIColor.clearColor
#define CELL_CORNER_RADIUS      16.0

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
#define SECTION_ITEM_SPACING    48.0
#endif

#define LAYOUT_MODE_KEY     @"LayoutMode"
#define LAYOUT_MODE_DEFAULT LayoutSmall
#define SCOPE_MODE_KEY      @"ScopeMode"
#define SCOPE_MODE_DEFAULT  @"System"
#define ALL_SCOPES          @[@"System", @"Software", @"Clones", @"Manufacturer", @"Year", @"Genre", @"Driver"]
#define RECENT_GAMES_MAX    8

#define SELECTED_GAME_KEY         @"SelectedGame"
#define SELECTED_GAME_SECTION_KEY @"SelectedGameSection"
#define COLLAPSED_STATE_KEY       @"CollapsedSectionState"

#define CLAMP(x, num) MIN(MAX(x,0), (num)-1)

typedef NS_ENUM(NSInteger, LayoutMode) {
    LayoutTiny,
    LayoutSmall,
    LayoutLarge,
    LayoutList,
    LayoutCount
};

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
    NSArray<GameInfo*>* _gameList;         // all games
    NSDictionary<NSString*,NSArray<GameInfo*>*>* _gameData;    // filtered and separated into sections/scope
    NSArray<NSString*>* _gameSectionTitles;// sorted section names
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
    UIImage* _loadingImage;
    NSCache* _system_description;
}
@end

@implementation ChooseGameController

+ (NSArray<NSString*>*) allSettingsKeys {
    return @[LAYOUT_MODE_KEY, SCOPE_MODE_KEY, RECENT_GAMES_KEY, FAVORITE_GAMES_KEY, COLLAPSED_STATE_KEY, SELECTED_GAME_KEY, SELECTED_GAME_SECTION_KEY];
}

- (instancetype)init
{
    self = [self initWithCollectionViewLayout:[[GameInfoCellLayout alloc] init]];
    
    // filter scope
    _gameFilterScope = [NSUserDefaults.standardUserDefaults stringForKey:SCOPE_MODE_KEY];
    
    if (![ALL_SCOPES containsObject:_gameFilterScope])
        _gameFilterScope = SCOPE_MODE_DEFAULT;
    
    // layout mode
    if ([NSUserDefaults.standardUserDefaults objectForKey:LAYOUT_MODE_KEY] == nil)
        _layoutMode = LAYOUT_MODE_DEFAULT;
    else
        _layoutMode = CLAMP([NSUserDefaults.standardUserDefaults integerForKey:LAYOUT_MODE_KEY], LayoutCount);
    
    _loadingImage = [UIImage imageWithColor:[UIColor clearColor] size:CGSizeMake(4, 3)];
    
    return self;
}

- (void)viewDidLoad
{
#if USE_TITLE_IMAGE
    CGFloat height = TARGET_OS_IOS ? 42.0 : (44.0 * 2.0);
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
        [UIImage systemImageNamed:@"square.grid.4x3.fill"    withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]] ?: @"⚏",
        [UIImage systemImageNamed:@"rectangle.grid.2x2.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]] ?: @"☷",
        [UIImage systemImageNamed:@"rectangle.stack.fill"    withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]] ?: @"▢",
        [UIImage systemImageNamed:@"rectangle.grid.1x2.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]] ?: @"☰"
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
    
    // on a small phone, make the group button/scope just show a icon
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    if (UIApplication.sharedApplication.keyWindow.bounds.size.width <= 375)
        [seg2 setImage:[UIImage systemImageNamed:@"list.dash" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]] forSegmentAtIndex:UISegmentedControlNoSegment];
    #pragma clang diagnostic pop

#if TARGET_OS_TV
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    UIColor* color = UIApplication.sharedApplication.keyWindow.tintColor;
    #pragma clang diagnostic pop
    [seg2 setTitleTextAttributes:@{NSForegroundColorAttributeName:color} forState:UIControlStateNormal];
    [seg2 setTitleTextAttributes:@{NSForegroundColorAttributeName:color} forState:UIControlStateSelected];
#endif
    
    // settings
    UIImage* settingsImage = [UIImage systemImageNamed:@"gear" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]];
#if TARGET_OS_TV
    UIBarButtonItem* settings = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)];
#else
    UISegmentedControl* seg3 = [[UISegmentedControl alloc] initWithItems:@[settingsImage]];
    seg3.momentary = YES;
    [seg3 addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem* settings = [[UIBarButtonItem alloc] initWithCustomView:seg3];
#endif
    
    // add roms
    UIImage* addRomsImage = [UIImage systemImageNamed:@"plus" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:height]];
#if TARGET_OS_TV
    UIBarButtonItem* addRoms = [[UIBarButtonItem alloc] initWithImage:addRomsImage style:UIBarButtonItemStylePlain target:self action:@selector(addRoms:)];
#else
    UISegmentedControl* seg4 = [[UISegmentedControl alloc] initWithItems:@[addRomsImage]];
    seg4.momentary = YES;
    [seg4 addTarget:self action:@selector(addRoms:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem* addRoms = [[UIBarButtonItem alloc] initWithCustomView:seg4];
#endif
    
    self.navigationItem.rightBarButtonItems = @[addRoms, settings, layout, scope];

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
    [self.collectionView registerClass:[GameInfoCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER];
    [self.collectionView registerClass:[GameInfoHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HEADER_IDENTIFIER];
    
    self.collectionView.backgroundColor = BACKGROUND_COLOR;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.alwaysBounceVertical = YES;

#if TARGET_OS_IOS
    // we do our own navigation via game controllers
    if (@available(iOS 15.0, *)) {
        self.collectionView.allowsFocus = NO;
    }
#endif
    
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self restoreSelection];
    
    // hide the search bar if we are at the top
    if (self.collectionView.contentOffset.y <= 0.0)
        [self scrollToTop];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveSelection];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
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

-(void)showSettings:(id)sender
{
    if (_settingsCallback)
        _settingsCallback(sender);
}

-(void)addRoms:(id)sender
{
    if (_romsCallback)
        _romsCallback(sender);
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

- (void)addSnapshots:(NSMutableArray*)games
{
    // remove any snapshots
    // TODO: this needs changed is gameType is an enum
    [games filterUsingPredicate:[NSPredicate predicateWithFormat:@"gameType != %@", kGameInfoTypeSnapshot]];
    
    // add all snapshots on disk
    for (NSString* snap in [NSFileManager.defaultManager enumeratorAtPath:getDocumentPath(@"snap")].allObjects) {
        
        NSString* file = [@"snap" stringByAppendingPathComponent:snap];

        if (![snap.pathExtension.lowercaseString isEqualToString:@"png"] || snap.stringByDeletingLastPathComponent.length == 0)
            continue;
        
        [games addObject:[[GameInfo alloc] initWithDictionary:@{
            kGameInfoType:kGameInfoTypeSnapshot,
            kGameInfoFile:file,
            kGameInfoManufacturer:snap.lastPathComponent.stringByDeletingPathExtension,
            kGameInfoName:snap.stringByDeletingLastPathComponent.lastPathComponent,
            kGameInfoDescription:snap.stringByDeletingLastPathComponent.lastPathComponent,
        }]];
    }
}

- (void)addSoftware:(NSMutableArray*)games
{
    // software not a thing on 139 (pre MESS)
    if (myosd_get(MYOSD_VERSION) == 139)
        return;
    
    // remove any previous software
    // TODO: this needs changed is gameType is an enum
    [games filterUsingPredicate:[NSPredicate predicateWithFormat:@"gameType != %@", kGameInfoTypeSoftware]];
    
    // add all software on disk
    for (NSString* soft in [NSFileManager.defaultManager enumeratorAtPath:getDocumentPath(@"software")].allObjects) {
        
        NSString* file = [@"software" stringByAppendingPathComponent:soft];

        if (file.pathExtension.length == 0 || file.lastPathComponent.stringByDeletingPathExtension.length == 0)
            continue;
        
        if ([@[@"txt", @"json", @"png"] containsObject:file.pathExtension.lowercaseString])
            continue;

        // construct a short name
        // TODO: need a better short name
        NSString* name = file.lastPathComponent.stringByDeletingPathExtension;
        name = [name componentsSeparatedByCharactersInSet:[NSCharacterSet alphanumericCharacterSet].invertedSet].firstObject;

        GameInfo* game = [[GameInfo alloc] initWithDictionary:@{
            kGameInfoType:kGameInfoTypeSoftware,
            kGameInfoFile:file,
            kGameInfoName:name,
            kGameInfoDescription:file.lastPathComponent.stringByDeletingPathExtension
        }];
        
        // add any user custom metadata from sidecar
        [game gameLoadMetadata];
    
        [games addObject:game];
    }
}

- (void)setGameList:(NSArray*)_games
{
    NSMutableArray* games = [_games mutableCopy];
    
    // add all snapshots on disk
    [self addSnapshots:games];

    // add any software on disk
    [self addSoftware:games];

    // sort the list by description
    [games sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"gameDescription" ascending:TRUE]]];
    
    _gameList = [games copy];
    [self filterGameList];
}

- (void)reload
{
    [self setGameList:_gameList];
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
        GameInfo* game = [_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"gameName == %@", system]].firstObject;
        description = game.gameDescription;
        if (description.length == 0)
            description = system;
        [_system_description setObject:description forKey:system];
        
        // if this system is a clone, default section to collapsed
        if (game.gameIsClone && [self getCollapsed:description] == nil)
            [self setCollapsed:description isCollapsed:TRUE];
    }
    
    return description;
}

// removed duplicates from an array based on key, NOTE order of array not preserved
- (NSArray*)dedupArray:(NSArray<NSDictionary*>*)items uniqueKey:(NSString*)key {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    for (NSDictionary* item in items) {
        if ([item isKindOfClass:[NSDictionary class]] && item[key] != nil)
            dict[item[key]] = item;
    }
    return [dict allValues];
}

// filter (based on search text, or options) and group into sections
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
                    predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"gameYear.intValue %@ %d", op, year]];
            }

            if ([word length] == 4 && [word intValue] >= 1970 && [word intValue] < 2600)
                predicate = [NSPredicate predicateWithFormat:@"gameYear == %@", word];

            if (predicate == nil)
                predicate = [NSPredicate predicateWithFormat:@"SUBQUERY(gameDictionary.@allValues, $x, $x CONTAINS[cd] %@).@count > 0", word];
            
            filteredGames = [filteredGames filteredArrayUsingPredicate:predicate];
        }
    }
    
    // remove Console root (aka BIOS) machines
    // a Console is type=Console and System="" (ie just a machine of type Console)
    // NOTE we dont filter out Consoles at a higher level, cuz we need them to run Software (ie let user select)
    if (self.hideConsoles) {
        filteredGames = [filteredGames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (gameType == %@ AND gameSystem == '')", kGameInfoTypeConsole]];
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
    if ([_gameFilterScope isEqualToString:@"Software"])
        key = kGameInfoSoftwareList;
    if ([_gameFilterScope isEqualToString:@"Type"])
        key = kGameInfoType;
    if ((clones = [_gameFilterScope isEqualToString:@"Clones"]))
        key = kGameInfoSystem;

    for (GameInfo* game in filteredGames) {
        NSString* section = game.gameDictionary[key];
        
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

        if ([section length] != 0 && key == (void*)kGameInfoSoftwareList)
            section = [SoftwareList.sharedInstance getSoftwareListDescription:section] ?: section;

        if ([section length] == 0 && key == (void*)kGameInfoSoftwareList)
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
        
        // put software that is assigned a system in generic Software section also
        if (key == (void*)kGameInfoSystem && game.gameIsSoftware && game.gameSystem.length != 0)
            sections = @[section, kGameInfoTypeSoftware];
        if (key == (void*)kGameInfoSoftwareList && game.gameIsSoftware && game.gameSoftwareList.length != 0)
            sections = @[section, kGameInfoTypeSoftware];

        for (NSString* section in sections) {
            if (gameData[section] == nil)
                gameData[section] = [[NSMutableArray alloc] init];
            [gameData[section] addObject:game];
        }
    }
    
    // if we are grouping by SoftwareList remove duplicates (multiple machines run games in a list...)
    if (key == (void*)kGameInfoSoftwareList) {
        for (NSString* section in gameData.allKeys) {
            if ([@[kGameInfoTypeArcade, kGameInfoTypeSoftware, kGameInfoTypeSnapshot] containsObject:section])
                continue;
 
            // remove dups based on name, and sort
            gameData[section] = [[self dedupArray:gameData[section] uniqueKey:kGameInfoName]
                sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kGameInfoDescription ascending:TRUE]]];
         }
    }

    // and sort section names
    NSArray* gameSectionTitles = [gameData.allKeys sortedArrayUsingSelector:@selector(localizedCompare:)];
    
    // move Computer(s) and Console(s) etc to the end
    for (NSString* section in @[kGameInfoTypeSoftware, kGameInfoTypeConsole, kGameInfoTypeComputer, kGameInfoTypeBIOS, kGameInfoTypeSnapshot, @"Unknown"]) {
        for (NSString* title in @[section, [NSString stringWithFormat:@"%@ • Clones", section]]) {
            if ([gameSectionTitles containsObject:title]) {
                gameSectionTitles = [gameSectionTitles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", title]];
                gameSectionTitles = [gameSectionTitles arrayByAddingObject:title];
            }
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
        NSMutableArray* favoriteGames = [[NSUserDefaults.standardUserDefaults arrayForKey:FAVORITE_GAMES_KEY] mutableCopy];
        for (int i=0; i<favoriteGames.count; i++)
            favoriteGames[i] = [[GameInfo alloc] initWithDictionary:favoriteGames[i]];
        [favoriteGames filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", filteredGames]];
        
        if ([favoriteGames count] > 0) {
            //NSLog(@"FAVORITE GAMES: %@", favoriteGames);
            gameSectionTitles = [@[FAVORITE_GAMES_TITLE] arrayByAddingObjectsFromArray:gameSectionTitles];
            gameData[FAVORITE_GAMES_TITLE] = [favoriteGames copy];
        }

        // load recent games and put them at the top
        NSMutableArray* recentGames = [[NSUserDefaults.standardUserDefaults arrayForKey:RECENT_GAMES_KEY] mutableCopy];
        for (int i=0; i<recentGames.count; i++)
            recentGames[i] = [[GameInfo alloc] initWithDictionary:recentGames[i]];
        [recentGames filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", filteredGames]];

        if ([recentGames count] > 0) {
            //NSLog(@"RECENT GAMES: %@", recentGames);
            gameSectionTitles = [@[RECENT_GAMES_TITLE] arrayByAddingObjectsFromArray:gameSectionTitles];
            gameData[RECENT_GAMES_TITLE] = recentGames;
        }
    }
    
    if (self.isViewLoaded)
        [self saveSelection];
    
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

-(void)invalidateLayout
{
    // NOTE calling reloadData and/or invalidateLayout does not actualy work, we also need a FlowLayout subclass!, see GameCellLayout
    _layoutRowHeightCache = nil;   // flush row height cache
    [self.collectionView.collectionViewLayout invalidateLayout];
}

-(void)reloadData
{
    [self saveSelection];
    [self invalidateLayout];
    [self.collectionView reloadData];
    [self restoreSelection];
}

-(NSIndexPath*)getSelection {
#if TARGET_OS_TV
    return _currentlyFocusedIndexPath;
#else
    return self.collectionView.indexPathsForSelectedItems.firstObject;
#endif
}

-(void)setSelection:(NSIndexPath*)indexPath {
#if TARGET_OS_TV
    _currentlyFocusedIndexPath = indexPath;
    [self setNeedsFocusUpdate];
#else
    BOOL is_vis = [self.collectionView.indexPathsForVisibleItems containsObject:indexPath];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:is_vis ? UICollectionViewScrollPositionNone : UICollectionViewScrollPositionCenteredVertically];
    [self scrollViewDidScroll:self.collectionView]; // update headers
#endif
}
-(void)saveSelection {
    NSIndexPath* indexPath = [self getSelection];
    if (indexPath != nil && indexPath.section < _gameSectionTitles.count) {
        GameInfo* game = [self getGameInfo:indexPath];
        [NSUserDefaults.standardUserDefaults setValue:_gameSectionTitles[indexPath.section] forKey:SELECTED_GAME_SECTION_KEY];
        [NSUserDefaults.standardUserDefaults setValue:game.gameDictionary forKey:SELECTED_GAME_KEY];
    }
}
-(void)restoreSelection {
    NSString* title = [NSUserDefaults.standardUserDefaults valueForKey:SELECTED_GAME_SECTION_KEY] ?: @"";
    NSDictionary* info = [NSUserDefaults.standardUserDefaults valueForKey:SELECTED_GAME_KEY] ?: @{};
    GameInfo* game = [[GameInfo alloc] initWithDictionary:info];
    NSUInteger section = [_gameSectionTitles indexOfObject:title];
    if (section != NSNotFound && section < [self.collectionView numberOfSections] && [self.collectionView numberOfItemsInSection:section] != 0) {
        NSUInteger item = [_gameData[title] indexOfObject:game];
        if (item == NSNotFound || item >= [self.collectionView numberOfItemsInSection:section])
            item = 0;
        NSIndexPath* indexPath = [NSIndexPath indexPathForItem:item inSection:section];
        [self setSelection:indexPath];
    }
}

-(void)moveSelectionForDelete:(NSIndexPath*)indexPath {
    if (indexPath != nil) {
        if (indexPath.item < [self.collectionView numberOfItemsInSection:indexPath.section]-1)
            indexPath = [NSIndexPath indexPathForItem:indexPath.item+1 inSection:indexPath.section];
        else if (indexPath.item > 0)
            indexPath = [NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section];
        [self setSelection:indexPath];
    }
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
        layout.itemSize = CGSizeMake(width, width / 4.0);
    else
        layout.itemSize = CGSizeMake(width, width * 1.5);

    [self reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat yTop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top;
    for (GameInfoCell* cell in [self.collectionView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionHeader]) {
        if (yTop > 0.5 && fabs(yTop - cell.frame.origin.y) <= cell.frame.size.height) {
#if TARGET_OS_IOS
            [cell addBlur:UIBlurEffectStyleDark];
#else
            cell.backgroundColor = HEADER_PINNED_COLOR;
#endif
        }
        else {
            cell.backgroundView = nil;
            cell.backgroundColor = HEADER_BACKGROUND_COLOR;
            cell.selected = cell.selected;  // update selected/focused state
        }
    }
}

#pragma mark Favorites

- (BOOL)isFavorite:(GameInfo*)game
{
    NSArray* favoriteGames = [NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[];
    return [favoriteGames containsObject:game.gameDictionary];
}
- (void)setFavorite:(GameInfo*)game isFavorite:(BOOL)flag
{
    if (game == nil || game.gameName.length == 0)
        return;

    NSMutableArray* favoriteGames = [([NSUserDefaults.standardUserDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[]) mutableCopy];

    [favoriteGames removeObject:game.gameDictionary];

    if (flag)
        [favoriteGames insertObject:game.gameDictionary atIndex:0];
    
    [NSUserDefaults.standardUserDefaults setObject:favoriteGames forKey:FAVORITE_GAMES_KEY];
    [self updateExternal];
}

#pragma mark Recent Games

- (BOOL)isRecent:(GameInfo*)game
{
    NSArray* recentGames = [NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY] ?: @[];
    return [recentGames containsObject:game.gameDictionary];
}
- (void)setRecent:(GameInfo*)game isRecent:(BOOL)flag
{
    if (game == nil || game.gameName.length == 0)
        return;
    
    NSMutableArray* recentGames = [([NSUserDefaults.standardUserDefaults objectForKey:RECENT_GAMES_KEY] ?: @[]) mutableCopy];

    [recentGames removeObject:game.gameDictionary];
    if (flag)
        [recentGames insertObject:game.gameDictionary atIndex:0];
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
            NSArray* games = ([NSUserDefaults.standardUserDefaults arrayForKey:key] ?: @[]);
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
    NSArray* recentGames = [NSUserDefaults.standardUserDefaults arrayForKey:RECENT_GAMES_KEY] ?: @[];
    NSArray* favoriteGames = [NSUserDefaults.standardUserDefaults arrayForKey:FAVORITE_GAMES_KEY] ?: @[];

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
    
    for (NSDictionary* info in games) {
        GameInfo* game = [[GameInfo alloc] initWithDictionary:info];
        NSString* type = [NSString stringWithFormat:@"%@.%@", NSBundle.mainBundle.bundleIdentifier, @"play"];
        NSString* title = game.gameTitle;
        UIApplicationShortcutIcon* icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay];
        
        if (@available(iOS 13.0, *))
            icon = [UIApplicationShortcutIcon iconWithSystemImageName:[self isFavorite:game] ? @"gamecontroller.fill" : @"gamecontroller"];
        
        UIApplicationShortcutItem* item = [[UIApplicationShortcutItem alloc] initWithType:type
                                           localizedTitle:title localizedSubtitle:nil
                                           icon:icon userInfo:info];
        [shortcutItems addObject:item];
    }

    [UIApplication sharedApplication].shortcutItems = shortcutItems;
}
#endif

#pragma mark Section collapse

-(id)getCollapsed:(NSString*)title
{
    NSDictionary* state = [NSUserDefaults.standardUserDefaults objectForKey:COLLAPSED_STATE_KEY] ?: @{};
    return state[title];
}
-(BOOL)isCollapsed:(NSString*)title
{
    if (_isSearchResults)
        return FALSE;
    return [[self getCollapsed:title] boolValue];
}
- (void)setCollapsed:(NSString*)title isCollapsed:(BOOL)flag
{
    NSMutableDictionary* state = [([NSUserDefaults.standardUserDefaults objectForKey:COLLAPSED_STATE_KEY] ?: @{}) mutableCopy];
    state[title] = @(flag);
    [NSUserDefaults.standardUserDefaults setObject:state forKey:COLLAPSED_STATE_KEY];
}

-(void)headerTap:(UITapGestureRecognizer*)sender
{
    NSLog(@"HEADER TAP: %d", (int)sender.view.tag);
    if (_isSearchResults)
        return;
    NSInteger section = sender.view.tag;
    if (section >= 0 && section < _gameSectionTitles.count)
    {
        NSString* title = _gameSectionTitles[section];
        [self setCollapsed:title isCollapsed:![self isCollapsed:title]];
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
        } completion:nil];
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
    NSString* title = _gameSectionTitles[section];
    if ([self isCollapsed:title])
        return 0;
    NSInteger num = [_gameData[title] count];
    // restrict the Recent items to a single row, always
    if ([title isEqualToString:RECENT_GAMES_TITLE])
        num = MIN(num, _layoutCollums);
    return num;
}
-(GameInfo*)getGameInfo:(NSIndexPath*)indexPath
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
//              short Manufacturer • Year   short Manufacturer • Year   Manufacturer • Year  • system:romname [parent-rom]
//
+(NSAttributedString*)getGameText:(GameInfo*)game layoutMode:(LayoutMode)layoutMode textAlignment:(NSTextAlignment)textAlignment badge:(NSString*)badge clone:(BOOL)clone
{
    NSString* title;
    NSString* detail;
    NSString* str;

    if (game.gameName.length == 0 || game.gameDescription.length == 0)
        return nil;
    
    if (layoutMode == LayoutTiny) {
        title = @"";
        detail = game.gameName;
    }
    else if (layoutMode == LayoutSmall) {
        title = game.gameTitle;
        detail = [game.gameManufacturer componentsSeparatedByString:@" ("].firstObject;

        if ((str = game.gameYear).length > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];
    }
    else if (layoutMode == LayoutLarge) {
        title = game.gameDescription;
        detail = [game.gameManufacturer componentsSeparatedByString:@" ("].firstObject;

        if ((str = game.gameYear).length > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", detail, str];
    }
    else { // LayoutList
        title = game.gameDescription;
        detail = game.gameName;

        if ((str = game.gameSystem).length > 1)
            detail = [NSString stringWithFormat:@"%@:%@", str, detail];
        
        if ((str = game.gameYear).length > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", str, detail];

        if ((str = game.gameManufacturer).length > 1)
            detail = [NSString stringWithFormat:@"%@ • %@", str, detail];
        
        if ((str = game.gameParent).length > 1)
            detail = [NSString stringWithFormat:@"%@ [%@]", detail, str];
    }
    
#ifdef XXDEBUG
    if (layoutMode != LayoutTiny)
        title = [NSString stringWithFormat:@" Blah Blah Blah %@ Blah Blah Blah Blah Blah Blah", title];
#endif
    
    UIColor* titleColor = clone ? CELL_CLONE_COLOR : CELL_TITLE_COLOR;

    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName:CELL_TITLE_FONT,
        NSForegroundColorAttributeName:titleColor
    }];
    
    if (detail.length != 0 && ![title isEqualToString:detail])
    {
        if (text.length != 0)
            detail = [@"\n" stringByAppendingString:detail];

        [text appendAttributedString:[[NSAttributedString alloc] initWithString:detail attributes:@{
            NSFontAttributeName:CELL_DETAIL_FONT,
            NSForegroundColorAttributeName:title.length == 0 ? titleColor : CELL_DETAIL_COLOR
        }]];
    }
    
    if (badge.length != 0 && layoutMode != LayoutTiny)
    {
        UIImage* image = [UIImage systemImageNamed:badge withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleSmall]];
        NSTextAttachment* att = [[NSTextAttachment alloc] init];
        att.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        NSMutableAttributedString* badge_text = [[NSAttributedString attributedStringWithAttachment:att] mutableCopy];
        [badge_text addAttributes:@{NSForegroundColorAttributeName:UIColor.systemBlueColor} range:NSMakeRange(0, badge_text.length)];

        [text insertAttributedString:[[NSAttributedString alloc] initWithString:@"\u2009"] atIndex:0];  // U+2009 Thin Space
        [text insertAttributedString:badge_text atIndex:0];
    }

    if (textAlignment != NSTextAlignmentLeft)
    {
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        [paragraph setAlignment:textAlignment];
        [text addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
    }
    
    return [text copy];
}

+(NSAttributedString*)getGameText:(GameInfo*)game layoutMode:(LayoutMode)layoutMode
{
    return [self getGameText:game layoutMode:layoutMode textAlignment:NSTextAlignmentCenter badge:nil clone:NO];
}

+(NSAttributedString*)getGameText:(GameInfo*)game
{
    return [self getGameText:game layoutMode:LayoutLarge];
}

-(NSAttributedString*)getGameText:(GameInfo*)game
{
    return [[self class] getGameText:game layoutMode:_layoutMode
                       textAlignment:_layoutMode == LayoutList ? NSTextAlignmentLeft : NSTextAlignmentCenter
                               badge:[self isFavorite:game] ? @"star.fill" : @""
                               clone:game.gameParent.length != 0];
}

// compute the size(s) of a single item. returns: (x = image_height, y = text_height)
- (CGPoint)heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    GameInfo* game = [self getGameInfo:indexPath];
    NSAttributedString* text = [self getGameText:game];
    
    // start with the (itemSize.width,0.0)
    CGFloat item_width = layout.itemSize.width;
    CGFloat image_height, text_height;
    
    // get the screen, assume the game is 4:3 if we dont know.
    BOOL is_vert = [game.gameScreen containsString:kGameInfoScreenVertical];

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
    
    NSLog(@"heightForItemAtIndexPath: %d.%d %@ -> %@", (int)indexPath.section, (int)indexPath.item, game.gameName, NSStringFromCGSize(CGSizeMake(image_height, text_height)));
    return CGPointMake(image_height, text_height);
}

// compute (or return from cache) the height(s) of a single row.
// returns: (x = image_height, y = text_height)
- (CGPoint)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // this code should not be called in this case
    NSParameterAssert(_layoutMode != LayoutList && _layoutCollums != 0);

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
    if (urls.count == 0 && localURL != nil)
        return handler([UIImage imageWithContentsOfFile:localURL.path]);

    if (urls.count == 0)
        return handler(nil);
    
    [ImageCache.sharedInstance getImage:urls.firstObject localURL:localURL completionHandler:^(UIImage *image) {
        if (image != nil)
           handler(image);
        else
           [self getImage:[urls subarrayWithRange:NSMakeRange(1, urls.count-1)] localURL:localURL completionHandler:handler];
    }];
}

// make a default icon if we cant find one
+(UIImage*)makeIcon:(GameInfo*)game
{
    UIImage* image = [UIImage imageNamed:@"default_game_icon"];

    if (game.gameFile.pathExtension.length == 0)
        return image;
    
    CGSize size = image.size;

    NSString* text = game.gameFile.pathExtension;
    UIFont* font =  [UIFont systemFontOfSize:size.height / 8 weight:UIFontWeightHeavy];
    CGSize sizeText = [text sizeWithAttributes:@{NSFontAttributeName:font}];
    CGFloat pad = font.lineHeight / 4;
    UIColor* backColor = UIColor.systemBlueColor; // self.view.tintColor;
    UIColor* textColor = UIColor.whiteColor;

    return [[[UIGraphicsImageRenderer alloc] initWithSize:size] imageWithActions:^(UIGraphicsImageRendererContext * context) {
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        [backColor setFill];
        CGRect rect = CGRectMake(size.width - sizeText.width - pad * 4,
                                 size.height - sizeText.height - pad * 4,
                                 sizeText.width + pad * 2,
                                 sizeText.height + pad * 2);
        [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:pad] fill];
        [text drawAtPoint:CGPointMake(rect.origin.x + pad, rect.origin.y + pad) withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor}];
    }];
}

+(UIImage*)getGameIcon:(GameInfo*)game
{
    UIImage* image = [UIImage imageWithContentsOfFile:game.gameLocalImageURL.path];
    // force the image to be 4:3 or 3:4, to correct for any anamorphic
    // TODO: maybe dont do this for *large* or *square* art, ie not a CRT screenshot
    if (image) {
        CGFloat aspect =  [game.gameScreen containsString:kGameInfoScreenVertical] ? (3.0 / 4.0) : (4.0 / 3.0);
        image = [image scaledToSize:CGSizeMake(image.size.width, image.size.width / aspect)];
    }
    return image ?: [self makeIcon:game];
}

// get size of an item
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (_layoutMode == LayoutList || _layoutCollums == 0)
        return layout.itemSize;

    CGPoint row_height = [self heightForRowAtIndexPath:indexPath];
    return CGSizeMake(layout.itemSize.width, row_height.x + row_height.y);
}

// convert an IndexPath to a non-zero NSInteger, and back
#define INDEXPATH_TO_INT(indexPath) ((indexPath.section << 24) | (indexPath.item+1))
#define INT_TO_INDEXPATH(i) [NSIndexPath indexPathForItem:((i) & 0xFFFFFF)-1 inSection:(i) >> 24]

// create a cell for an item.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForItemAtIndexPath: %d.%d %@", (int)indexPath.section, (int)indexPath.item, [self getGameInfo:indexPath].gameName);
    
    GameInfo* game = [self getGameInfo:indexPath];
    
    GameInfoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    [cell setBackgroundColor:CELL_BACKGROUND_COLOR];
    
    cell.text.attributedText = [self getGameText:game];
    
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
    else {
        [cell setCornerRadius:CELL_CORNER_RADIUS];
    }
    
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat space = layout.minimumInteritemSpacing;
    CGFloat scale = 1.0 + (space * 1.5 / cell.bounds.size.width);
    [cell setSelectScale:scale];

    [cell setHorizontal:_layoutMode == LayoutList];
    [cell setTextInsets:UIEdgeInsetsMake(CELL_INSET_Y, CELL_INSET_X, CELL_INSET_Y, CELL_INSET_X)];
    
    CGFloat image_height = 0.0;
    if (_layoutMode != LayoutList && _layoutCollums > 1) {
        image_height = [self heightForRowAtIndexPath:indexPath].x;
    }
    
    // see if this cell got reused while loading, and stop any network activity, if we can
    if (cell.tag != 0 && cell.tag != INDEXPATH_TO_INT(indexPath)) {
        GameInfo* game = [self getGameInfo:INT_TO_INDEXPATH(cell.tag)];
        NSLog(@"CELL REUSED WHILE LOADING: %@ %d:%d", game.gameName, (int)INT_TO_INDEXPATH(cell.tag).section, (int)INT_TO_INDEXPATH(cell.tag).item);
        // cancel all urls
        for (NSURL* url in game.gameImageURLs) {
            if ([ImageCache.sharedInstance getLoadingCount:url] > 1)
                NSLog(@"...LOADING COUNT FOR URL(%@) IS %d", url.path, (int)[ImageCache.sharedInstance getLoadingCount:url]);

            // if two cells share the same image and one is still visible and loading we dont want to cancel!
            if ([ImageCache.sharedInstance getLoadingCount:url] == 1)
                [ImageCache.sharedInstance cancelImage:url];
        }
    }

    NSArray* urls = game.gameImageURLs;
    NSURL* localURL = game.gameLocalImageURL;

    cell.tag = INDEXPATH_TO_INT(indexPath);
    [self getImage:urls localURL:localURL completionHandler:^(UIImage *image) {

        // cell has been re-used bail, ie dont set the wrong image
        if (cell.tag != INDEXPATH_TO_INT(indexPath)) {
            NSLog(@"CELL ASYNC LOAD: %@ %d:%d != %d:%d *** WRONG CELL", game.gameName, (int)indexPath.section, (int)indexPath.item,
                  (int)INT_TO_INDEXPATH(cell.tag).section, (int)INT_TO_INDEXPATH(cell.tag).item);
            return;
        }

        if (cell.image.image != nil) {
            NSLog(@"CELL ASYNC LOAD: %@ %d:%d", game.gameName, (int)indexPath.section, (int)indexPath.item);
            [cell stopWait];
        }

        // mark cell as done loading
        cell.tag = 0;
        
        image = image ?: [[self class] makeIcon:game];
        NSParameterAssert(image != nil);
        
        // MAME games always ran on horz or vertical CRTs so it does not matter what the PAR of
        // the title image is force a aspect of 3:4 or 4:3
        
        BOOL is_vert = [game.gameScreen containsString:kGameInfoScreenVertical];
        if (self->_layoutMode == LayoutList) {
            CGFloat aspect = 4.0 / 3.0;
            [cell setImageAspect:aspect];
            cell.image.contentMode = is_vert ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleToFill;
        }
        else if (image_height != 0.0) {
            CGFloat aspect = (cell.bounds.size.width / image_height);
            [cell setImageAspect:aspect];
            cell.image.contentMode = (is_vert && aspect > 1.0) ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleToFill;
        }
        else {
            CGFloat aspect = is_vert ? (3.0 / 4.0) : (4.0 / 3.0);
            [cell setImageAspect:aspect];
            cell.image.contentMode = UIViewContentModeScaleToFill;
        }
        
        if (game.gameIsSnapshot)
            cell.image.contentMode = UIViewContentModeScaleAspectFill;

        cell.image.image = image;
    }];
    
    // use a placeholder image if the image did not load right away.
    if (cell.image.image == nil) {
        cell.image.image = _loadingImage;
        if (image_height != 0.0)
            [cell setImageAspect:(cell.bounds.size.width / image_height)];
        [cell startWait];
    }
    
#if TARGET_OS_IOS
    if ([self getSelection] == indexPath) {
        cell.selected = YES;
    }
#endif

    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)layout insetForSectionAtIndex:(NSInteger)section
{
    // UICollectionViewFlowLayout will center a section with a single item in it, else it will left align, WTF!
    // we want left aligned all the time, so mess with the section inset to make it do the right thing.
    
    if (section >= [_gameSectionTitles count] || [_gameData[_gameSectionTitles[section]] count] != 1)
        return layout.sectionInset;
            
    CGFloat itemWidth = layout.itemSize.width;
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
    
    if (arr.count != 3 || (image = [UIImage systemImageNamed:arr[1] withConfiguration:[UIImageSymbolConfiguration configurationWithFont:font]]) == nil)
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
    GameInfoHeader* cell = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HEADER_IDENTIFIER forIndexPath:indexPath];
    [cell setHorizontal:TRUE];
    NSString* title = _gameSectionTitles[indexPath.section];
    cell.text.text = title;
    cell.text.font = [UIFont systemFontOfSize:cell.bounds.size.height * 0.8 weight:UIFontWeightHeavy];
    cell.text.textColor = HEADER_TEXT_COLOR;
    cell.backgroundColor = HEADER_BACKGROUND_COLOR;
    [cell setTextInsets:UIEdgeInsetsMake(2.0, self.view.safeAreaInsets.left + 2.0, 2.0, self.view.safeAreaInsets.right + 2.0)];
    
    // make the section title tappable to toggle collapse/expand section
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        BOOL is_collapsed = [self isCollapsed:title];
        
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
    GameInfo* game = [self getGameInfo:indexPath];
    
    NSLog(@"DID SELECT ITEM[%d.%d] %@", (int)indexPath.section, (int)indexPath.item, game.gameName);
#if TARGET_OS_TV
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
#endif
    [self play:game];
}

#pragma mark - play game

-(void)play:(GameInfo*)game
{
    if (game.gameIsSnapshot)
        return;
    
    // if this is software, and no system is assigned we need to ask
    if (game.gameIsSoftware && (game.gameSystem.length == 0 || game.gameMediaType.length == 0))
        return [self play:game with:nil];

    // if we are sorting by software list, we also should ask.
    if ([_gameFilterScope isEqualToString:@"Software"] && game.gameSystem.length != 0)
        return [self play:game with:nil];
    
    // add or move to front of the recent game MRU list...
    [self setRecent:game isRecent:TRUE];
    
    // add any custom options
    [self addCustomOptions:game];
    
    // tell the code upstream that the user had selected a game to play!
    if (self.selectGameCallback != nil)
        self.selectGameCallback(game);
}

-(void)play:(GameInfo*)game with:(GameInfo*)system
{
    NSLog(@"PLAY: %@ WITH: %@", game, system);

    if (system == nil)
    {
        NSArray* list = [self getSystemsForGame:game];
        NSString* title = [ChooseGameController getGameText:game layoutMode:LayoutSmall].string;

        if (list.count == 0)
        {
            NSString* message = @"Cant find a System to play.";
            [self showAlertWithTitle:title message:message buttons:@[@"Ok"] handler:nil];
            return;
        }
        
        if (list.count == 1)
        {
            [self play:game with:list.firstObject];
            return;
        }
        
        NSString* message = @"Select a System to play";
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        for (GameInfo* system in list)
        {
            NSString* title = [NSString stringWithFormat:@"%@", system.gameDescription];
            [alert addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                [self play:game with:system];
            }]];
            if (game.gameSystem.length != 0 && [game.gameSystem isEqualToString:system.gameName])
                alert.preferredAction = alert.actions.lastObject;
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    // mark recent before we modify the system
    [self setRecent:game isRecent:TRUE];

    // modify the system
    [game gameSetValue:system.gameName forKey:kGameInfoSystem];
    
    // modify the media kind
    if (game.gameFile.length != 0) {
        for (NSString* media in [system.gameSoftwareMedia componentsSeparatedByString:@","]) {
            NSArray* arr = [media componentsSeparatedByString:@":"];
            if (arr.count==2 && [arr.lastObject isEqualToString:game.gameFile.pathExtension.lowercaseString]) {
                [game gameSetValue:arr.firstObject forKey:kGameInfoMediaType];
                // stop after we find the first media that matches, this way we will use "-flop1" and *not* "-flop4" etc.
                break;
            }
        }
    }

    // add any custom options
    [self addCustomOptions:game];
    
    // tell the code upstream that the user had selected a game to play!
    if (self.selectGameCallback != nil)
        self.selectGameCallback(game);
}

-(void)addCustomOptions:(GameInfo*)game
{
    CommandLineArgsHelper *cmdLineArgsHelper = [[CommandLineArgsHelper alloc] initWithGameInfo:game];
    NSString *customArgs = [cmdLineArgsHelper commandLineArgs];
    if (customArgs)
    {
        [game gameSetValue:customArgs forKey:kGameInfoCustomCmdline];
    }
}

-(NSArray<GameInfo*>*)getSystemsForGame:(GameInfo*)game
{
    NSMutableArray* list = [[NSMutableArray alloc] init];
    
    for (GameInfo* system in _gameList) {
        
        if (system.gameSoftwareMedia.length == 0)
            continue;
        
        // the SoftwareMedia list is a list of two types of strings, either <software list name>, or <media kind>:<file extension>
        for (NSString* media in [system.gameSoftwareMedia componentsSeparatedByString:@","]) {
            NSArray* arr = [media componentsSeparatedByString:@":"];
            if ([media isEqualToString:game.gameSoftwareList] || (arr.count==2 && [arr.lastObject isEqualToString:game.gameFile.pathExtension.lowercaseString])) {
                [list addObject:system];
                break;
            }
        }
    }
    return list;
}

#pragma mark - game context menu actions...

// get the files associated with a game, if allFiles is NO only the settings files are returned.
// file paths are relative to our document root.
-(NSArray*)getGameFiles:(GameInfo*)game allFiles:(BOOL)all
{
    NSString* name = game.gameName;
    
    if (game.gameSoftwareList.length != 0)
        name = [game.gameSoftwareList stringByAppendingPathComponent:name];
    
    NSMutableArray* files = [[NSMutableArray alloc] init];
    
    if (game.gameIsSoftware) {
        for (NSString* ext in @[@"png", @"json"])
            [files addObject:[game.gameFile stringByAppendingPathExtension:ext]];
        if (all)
            [files addObject:game.gameFile];
    }
    else {
        for (NSString* file in @[@"roms/%@.json", @"titles/%@.png", @"cfg/%@.cfg", @"ini/%@.ini", @"sta/%@/1.sta", @"sta/%@/2.sta", @"hi/%@.hi", @"hiscore/%@.hi",
                                 @"nvram/%@.nv", @"inp/%@.inp", @"snap/%@/"])
            [files addObject:[NSString stringWithFormat:file, name]];
        
        if (all) {
            for (NSString* file in @[@"roms/%@.zip", @"roms/%@.7z", @"roms/%@/%@.chd", @"roms/%@/", @"artwork/%@.zip", @"samples/%@.zip"])
                [files addObject:[NSString stringWithFormat:file, name, name]];

            // if we are a parent ROM include all of our clones
            if (game.gameParent.length <= 1) {
                NSArray* clones = [_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"gameSystem == %@ AND gameParent == %@", game.gameSystem, game.gameName]];
                for (GameInfo* clone in clones) {
                    // TODO: check if this is a merged romset??
                    [files addObjectsFromArray:[self getGameFiles:clone allFiles:YES]];
                }
            }
        }
    }
    
    // only return files that exist
    [files filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* file, id bindings) {
        return [NSFileManager.defaultManager fileExistsAtPath:getDocumentPath(file)];
    }]];
    
    return files;
}
-(NSArray*)getGameFiles:(GameInfo*)game
{
    return [self getGameFiles:game allFiles:YES];
}

// ask user if we should DELETE ALL files or just Setting Files
-(void)delete:(GameInfo*)game
{
    NSString* title = [self menuTitleForGame:game];
    NSString* message = nil;

    [self showAlertWithTitle:title message:message buttons:@[@"Delete Settings", @"Delete Settings and ROMs", @"Cancel"] handler:^(NSUInteger button) {
        
        // cancel get out!
        if (button == 2)
            return;
        
        // 0=Settings, 1=All Files
        BOOL allFiles = (button == 1);
        NSArray* files = [self getGameFiles:game allFiles:allFiles];
        
        for (NSString* file in files) {
            NSString* delete_path = getDocumentPath(file);
            NSLog(@"DELETE: %@", delete_path);
            [[NSFileManager defaultManager] removeItemAtPath:delete_path error:nil];
        }
        
        for (NSURL* url in game.gameImageURLs)
            [ImageCache.sharedInstance flush:url];
        
        if (allFiles) {
            [self setRecent:game isRecent:FALSE];
            [self setFavorite:game isFavorite:FALSE];
            
            NSArray* list = [self->_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", game]];

            // if this is a parent romset, delete all the clones too.
            if (game.gameParent.length <= 1)
                list = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (gameSystem == %@ AND gameParent == %@)", game.gameSystem, game.gameName]];
            
            // TODO: if you delete a machine/system shoud we delete all the Software too?

            [self setGameList:list];
        }
        else {
            [self reload];
        }
        
        [[[CommandLineArgsHelper alloc] initWithGameInfo:game] delete];
    }];
}

#if TARGET_OS_IOS
// Export a game as a ZIP file with all the game state and settings, make the export file be named "SHORT-DESCRIPTION (ROMNAME).zip"
// NOTE we specificaly *dont* export CHDs because they are huge
-(void)share:(GameInfo*)game
{
    NSString* title = [NSString stringWithFormat:@"%@ (%@)",game.gameTitle, game.gameName];
    
    // prevent non-file system characters, and duplicate title and name
    if ([title containsString:@"/"] || [title containsString:@":"] || [game.gameTitle isEqualToString:game.gameName])
        title = game.gameName;
    
    FileItemProvider* item = [[FileItemProvider alloc] initWithTitle:title typeIdentifier:@"public.zip-archive" saveHandler:^BOOL(NSURL* url, FileItemProviderProgressHandler progressHandler) {
        NSString *rootPath = [NSString stringWithUTF8String:get_documents_path("")];
        NSArray* files = [self getGameFiles:game];
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

-(void)info:(GameInfo*)game
{
    GameInfoController* gameInfoController = [[GameInfoController alloc] initWithGame:game];

#if TARGET_OS_IOS
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:gameInfoController];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nav animated:YES completion:nil];
#else
    [self presentViewController:gameInfoController animated:YES completion:nil];
#endif
}

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(GameInfo*)game
{
    NSString* name = game.gameName;

    if (name == nil || [name length] <= 1 || [name isEqualToString:kGameInfoNameMameMenu])
        return nil;
    
    // if we only have the ROM name, try to find full info for this game in Recents or Favorites
    if (game.gameDescription.length == 0) {
        NSArray* list = [[NSUserDefaults.standardUserDefaults arrayForKey:RECENT_GAMES_KEY] arrayByAddingObjectsFromArray:
                         [NSUserDefaults.standardUserDefaults arrayForKey:FAVORITE_GAMES_KEY]];
        NSDictionary* dict = [list filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"gameSystem == %@ AND gameName == %@", game.gameSystem, game.gameName]].firstObject;
        
        if (dict == nil)
            return nil;
        
        game = [[GameInfo alloc] initWithDictionary:dict];
    }
    
    NSString* type = [NSString stringWithFormat:@"%@.%@", NSBundle.mainBundle.bundleIdentifier, @"play"];
    NSString* title = [NSString stringWithFormat:@"Play %@", game.gameTitle];
    
    NSUserActivity* activity = [[NSUserActivity alloc] initWithActivityType:type];
    
    activity.title = title;
    activity.userInfo = game.gameDictionary;
    activity.eligibleForSearch = TRUE;
    
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = TRUE;
        activity.persistentIdentifier = game.gameName;
        activity.suggestedInvocationPhrase = title;
    }
    return activity;
}
#endif


#pragma mark - Context Menu

// get the items in the ContextMenu for a item
- (NSArray*)menuActionsForItemAtIndexPath:(NSIndexPath *)indexPath {
    GameInfo* game = [self getGameInfo:indexPath];
    NSString* name = game.gameName;
    
    if (game == nil || [name length] == 0)
        return nil;

    // prime the image cache, in case any menu items ask for the image later.
    [self getImage:game.gameImageURLs localURL:game.gameLocalImageURL completionHandler:^(UIImage *image) {}];

    NSLog(@"menuActionsForItemAtIndexPath: [%d.%d] %@ %@", (int)indexPath.section, (int)indexPath.row, game.gameName, game);
    
    if (game.gameIsSnapshot) {
        return @[
            [UIAlertAction actionWithTitle:@"Use as Title Image" symbol:@"photo" style:UIAlertActionStyleDefault handler:^(id action) {
                NSString* src = game.gameLocalImageURL.path;
                // convert /snap/XXXX/YYYY/0000.png to /titles/XXXX/YYYY.png
                NSString* dst = [[src.stringByDeletingLastPathComponent stringByReplacingOccurrencesOfString:@"/snap/" withString:@"/titles/"] stringByAppendingPathExtension:@"png"];
                [NSFileManager.defaultManager removeItemAtPath:dst error:nil];
                [NSFileManager.defaultManager copyItemAtPath:src toPath:dst error:nil];
                [ImageCache.sharedInstance flush];
                [self reload];  // use a big hammer and reload everything
            }],
#if TARGET_OS_IOS
            [UIAlertAction actionWithTitle:@"Share" symbol:@"square.and.arrow.up" style:UIAlertActionStyleDefault handler:^(id action) {
                NSURL* url = game.gameLocalImageURL;
                UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
                activity.popoverPresentationController.sourceView = self.view;
                activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0.0f, 0.0f);
                activity.popoverPresentationController.permittedArrowDirections = 0;
                [self presentViewController:activity animated:YES completion:nil];
            }],
#endif
            [UIAlertAction actionWithTitle:@"Delete" symbol:@"trash" style:UIAlertActionStyleDefault handler:^(id action) {
                [self moveSelectionForDelete:indexPath];
                [NSFileManager.defaultManager removeItemAtPath:game.gameLocalImageURL.path error:nil];
                [self reload];
            }]
        ];
    }
    
    NSArray* actions = @[
        [UIAlertAction actionWithTitle:@"Play" symbol:@"gamecontroller" style:UIAlertActionStyleDefault handler:^(id action) {
            [self play:game];
        }]
    ];
    
    if ([self getSystemsForGame:game].count > 1) {
        actions = [actions arrayByAddingObject:
            [UIAlertAction actionWithTitle:@"Play With..." symbol:@"ellipsis.circle" style:UIAlertActionStyleDefault handler:^(id action) {
                [self play:game with:nil];
            }]
        ];
    }
    
    BOOL is_fav = [self isFavorite:game];
    NSString* fav_text = is_fav ? @"Remove from Favorites" : @"Add to Favorites";
    NSString* fav_icon = is_fav ? @"star.slash" : @"star";
    
    actions = [actions arrayByAddingObject:
        [UIAlertAction actionWithTitle:fav_text symbol:fav_icon style:UIAlertActionStyleDefault handler:^(id action) {
            if ([self->_gameSectionTitles[indexPath.section] isEqualToString:FAVORITE_GAMES_TITLE])
                [self moveSelectionForDelete:indexPath];
            [self setFavorite:game isFavorite:!is_fav];
            [self filterGameList];
        }]
    ];
    
    if ([self isRecent:game]) {
        actions = [actions arrayByAddingObjectsFromArray:@[
            [UIAlertAction actionWithTitle:@"Remove from Recently Played" symbol:@"minus.circle" style:UIAlertActionStyleDefault handler:^(id action) {
                if ([self->_gameSectionTitles[indexPath.section] isEqualToString:RECENT_GAMES_TITLE])
                    [self moveSelectionForDelete:indexPath];
                [self setRecent:game isRecent:NO];
                [self filterGameList];
            }]
        ]];
    }
    
    actions = [actions arrayByAddingObjectsFromArray:@[
        [UIAlertAction actionWithTitle:@"Info" symbol:@"info.circle" style:UIAlertActionStyleDefault handler:^(id action) {
            [self info:game];
        }]
    ]];
    
    // Paste image
#if !TARGET_OS_TV
    if (!game.gameIsMame && UIPasteboard.generalPasteboard.hasImages) {
        actions = [actions arrayByAddingObjectsFromArray:@[
            [UIAlertAction actionWithTitle:@"Paste Image" symbol:@"photo" style:UIAlertActionStyleDefault handler:^(id action) {
                UIImage* image = UIPasteboard.generalPasteboard.image;
                if (image == nil)
                    return;
                NSData* data = UIImagePNGRepresentation(image);
                if (data == nil)
                    return;
            
                [data writeToURL:game.gameLocalImageURL atomically:YES];
                [ImageCache.sharedInstance flush];
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }]
        ]];
    }
#endif
    
    CommandLineArgsHelper *cmdLineArgsHelper = [[CommandLineArgsHelper alloc] initWithGameInfo:game];
    NSString *cmdLineActionTitle = [cmdLineArgsHelper commandLineArgs] != nil ? @"Edit Arguments..." : @"Add Arguments...";
    actions = [actions arrayByAddingObjectsFromArray:@[
        [UIAlertAction actionWithTitle:cmdLineActionTitle symbol:@"text.and.command.macwindow" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self presentViewController:cmdLineArgsHelper.viewController animated:true completion:nil];
    }]
    ]];
    
    // get the files for this game, filter out the title image, and only allow delete if any other files
    NSArray* files = [self getGameFiles:game];
    files = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension != 'png'"]];
    if (files.count > 0) {
        actions = [actions arrayByAddingObjectsFromArray:@[
#if TARGET_OS_IOS
            [UIAlertAction actionWithTitle:@"Share" symbol:@"square.and.arrow.up" style:UIAlertActionStyleDefault handler:^(id action) {
                [self share:game];
            }],
#endif
            [UIAlertAction actionWithTitle:@"Delete" symbol:@"trash" style:UIAlertActionStyleDestructive handler:^(id action) {
                [self moveSelectionForDelete:indexPath];
                [self delete:game];
            }]
        ]];
    }
    return actions;
}

-(UIViewController*)menuForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray* actions = [self menuActionsForItemAtIndexPath:indexPath];
    NSString* title = [self menuTitleForItemAtIndexPath:indexPath];

    if ([actions count] == 0)
        return nil;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    for (UIAlertAction* action in actions)
        [alert addAction:action];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
 
    return alert;
 }


// get the title for the ContextMenu
- (NSString*)menuTitleForGame:(GameInfo*)game {
    return [ChooseGameController getGameText:game layoutMode:LayoutList].string;
}
- (NSString*)menuTitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self menuTitleForGame:[self getGameInfo:indexPath]];
}

#pragma mark - UIContextMenu (iOS 13+ only)

#if TARGET_OS_IOS

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    
    UIViewController* menu = [self menuForItemAtIndexPath:indexPath];
    
    return [UIContextMenuConfiguration configurationWithIdentifier:indexPath
            previewProvider:^UIViewController* () {
                return nil;     // use default
            }
            actionProvider:^UIMenu* (NSArray* suggestedActions) {
                return [(UIAlertController*)menu convertToMenu];
            }
    ];
}
#endif

#pragma mark - LongPress menu (pre iOS 13 and tvOS only)

-(void)runMenu:(NSIndexPath*)indexPath {

    if (indexPath == nil)
        return;
    
    UIViewController* menu = [self menuForItemAtIndexPath:indexPath];
    
    if (menu == nil)
        return;

    if (menu.popoverPresentationController != nil) {
        UIView* view = [self.collectionView cellForItemAtIndexPath:indexPath] ?: self.view;
        menu.popoverPresentationController.sourceView = view;
        menu.popoverPresentationController.sourceRect = view.bounds;
        menu.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    [self presentViewController:menu animated:YES completion:nil];
}

#if TARGET_OS_TV
- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {

    if (context.nextFocusedIndexPath != nil)
        NSLog(@"didUpdateFocusInContext: %d.%d", (int)context.nextFocusedIndexPath.section, (int)context.nextFocusedIndexPath.item);
    else
        NSLog(@"didUpdateFocusInContext: %@", NSStringFromClass(context.nextFocusedItem.class));
    
    if (context.nextFocusedIndexPath == nil)
        [self saveSelection];

    _currentlyFocusedIndexPath = context.nextFocusedIndexPath;
}

- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView {
    
    if (_currentlyFocusedIndexPath == nil)
        [self restoreSelection];
    
    if (_currentlyFocusedIndexPath.section < collectionView.numberOfSections && _currentlyFocusedIndexPath.item < [collectionView numberOfItemsInSection:_currentlyFocusedIndexPath.section])
        return _currentlyFocusedIndexPath;
    
    return nil;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canFocusItemAtIndexPath:(NSIndexPath *)indexPath {
    // always set focus to the first collum when jumping from non indexPath to indexPath focus item
    if (_currentlyFocusedIndexPath == nil && _layoutCollums > 1)
        return (indexPath.item % _layoutCollums) == 0;
    else
        return TRUE;
}
#endif

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
    GameInfo* game = [self getGameInfo:self.collectionView.indexPathsForSelectedItems.firstObject];
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
-(void)handleButtonPress:(ButtonPressType)type
{
    switch (type) {
        case ButtonPressTypeUp:
            return [self onCommandMove:-1 * _layoutCollums];
        case ButtonPressTypeDown:
            return [self onCommandMove:+1 * _layoutCollums];
        case ButtonPressTypeLeft:
            return [self onCommandMove:-1];
        case ButtonPressTypeRight:
            return [self onCommandMove:+1];
        case ButtonPressTypeSelect:
        {
            NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
            if (indexPath != nil)
                [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
            break;
        }
        case ButtonPressTypeMenu:
        {
            NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
            [self runMenu:indexPath];
            break;
        }
        case ButtonPressTypeOptions:
            return [self showSettings:nil];
        default:
            break;
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

// just forward key input to EmulatorController and let it dispatch it.
- (void)onCommandUp    { [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeUp]; }
- (void)onCommandDown  { [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeDown]; }
- (void)onCommandLeft  { [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeLeft]; }
- (void)onCommandRight { [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeRight]; }
- (void)onCommandSelect{ [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeSelect]; }
- (void)onCommandMenu  { [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeMenu]; }
- (void)onCommandEsc   { [(id)self.presentingViewController handleButtonPress:(UIPressType)ButtonPressTypeBack]; }

- (NSArray*)keyCommands {
    
    if (_searchController.isActive)
        return nil;
    
    // forward key input to EmulatorController and let it dispatch it.
    if (![self.presentingViewController respondsToSelector:@selector(handleButtonPress:)])
        return nil;
    
    if (_key_commands == nil) {
        _key_commands = @[
            // standard keyboard
            [UIKeyCommand keyCommandWithInput:@"\r"                 modifierFlags:0 action:@selector(onCommandSelect)],
            [UIKeyCommand keyCommandWithInput:@"`"                  modifierFlags:0 action:@selector(onCommandMenu)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow     modifierFlags:0 action:@selector(onCommandUp)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow   modifierFlags:0 action:@selector(onCommandDown)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow   modifierFlags:0 action:@selector(onCommandLeft)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow  modifierFlags:0 action:@selector(onCommandRight)],
            [UIKeyCommand keyCommandWithInput:UIKeyInputEscape      modifierFlags:0 action:@selector(onCommandEsc)],
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
        // make sure the focus system on iOS 15 does not harsh our mellow
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
        else if (_currentlyFocusedIndexPath != nil && self.topViewController == nil) {
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
