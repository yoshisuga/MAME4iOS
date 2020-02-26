//
//  ChooseGameController.m
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#import <UIKit/UIKit.h>
#import <GameController/GameController.h>
#import "ChooseGameController.h"
#import "ImageCache.h"
#import "Globals.h"
#import "myosd.h"

#if !__has_feature(objc_arc)
#error("This file assumes ARC")
#endif

#define DebugLog 1
#if DebugLog == 0
#define NSLog(...) (void)0
#endif

#define CELL_IDENTIFIER   @"GameInfoCell"
#if TARGET_OS_IOS
#define CELL_SMALL_WIDTH   200.0
#define CELL_LARGE_WIDTH   400.0
#else
#define CELL_SMALL_WIDTH   400.0
#define CELL_LARGE_WIDTH   600.0
#endif

#define HEADER_IDENTIFIER   @"GameInfoHeader"

#define LAYOUT_MODE_KEY     @"LayoutMode"
#define SCOPE_MODE_KEY      @"ScopeMode"
#define RECENT_GAMES_MAX    4
#define RECENT_GAMES_MIN    2
#define ALL_SCOPES          @[@"All", @"Author", @"Year", @"Category"]

#define CLAMP(x, num) MIN(MAX(x,0), (num)-1)

typedef NS_ENUM(NSInteger, LayoutMode) {
    LayoutSmall,
    LayoutLarge,
    LayoutList,
    LayoutCount
};

@interface GameCell : UICollectionViewCell
@property (readwrite, nonatomic, strong) UIImageView* image;
@property (readwrite, nonatomic, strong) UILabel* title;
@property (readwrite, nonatomic, strong) UILabel* detail;
@property (readwrite, nonatomic, strong) UILabel* info;
-(void)setHorizontal:(BOOL)horizontal;
-(void)setTextInsets:(UIEdgeInsets)insets;
@end

#pragma mark Safe Area helper for UIViewController (for pre and post iOS11)

@interface UIViewController (SafeArea)
@property (nonatomic, readonly, assign) UIEdgeInsets safeAreaInsets;
@end

@implementation UIViewController (SafeArea)
-(UIEdgeInsets)safeAreaInsets
{
#if TARGET_OS_IOS && (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_11_0)
    if (@available(iOS 11.0, *)) {
        return self.view.safeAreaInsets;
    } else {
        return UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0);
    }
#else
    return self.view.safeAreaInsets;
#endif
}
@end

@interface ChooseGameController () <UISearchResultsUpdating, UISearchBarDelegate> {
    NSArray* _gameList;         // all games
    NSDictionary* _gameData;    // filtered and separated into sections/scope
    NSArray* _gameSectionTitles;// sorted section names
    NSString* _gameFilterText;  // text string to filter games by
    NSString* _gameFilterScope; // group results by Name,Year,Manufactuer
    NSUInteger _layoutCollums;
    LayoutMode _layoutMode;
    CGFloat _layoutWidth;
    UISearchController* _searchController;
    NSUserDefaults* _userDefaults;
    NSArray* _key_commands;
    BOOL _searchCancel;
}
@end

@implementation ChooseGameController

- (instancetype)init
{
    self = [self initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    
    _userDefaults = [NSUserDefaults standardUserDefaults];

    // filter scope
    _gameFilterScope = [_userDefaults stringForKey:SCOPE_MODE_KEY];
    
    if (![ALL_SCOPES containsObject:_gameFilterScope])
        _gameFilterScope = [ALL_SCOPES firstObject];
    
    // layout mode
    _layoutMode = [_userDefaults integerForKey:LAYOUT_MODE_KEY];
    _layoutMode = MIN(MAX(_layoutMode,0), LayoutCount);
    
    return self;
}

- (void)viewDidLoad
{
    //put the title on the left
    self.title = @"MAME4iOS";
    UILabel* title = [[UILabel alloc] init];
    title.text = self.title;
#if TARGET_OS_IOS
    title.font = [UIFont boldSystemFontOfSize:32.0];
#else
    title.font = [UIFont boldSystemFontOfSize:64.0];
#endif
    title.textColor = UIColor.whiteColor;
    [title sizeToFit];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:title];
    self.title = nil;
    
    //navbar
#if TARGET_OS_IOS
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    [self.navigationController.navigationBar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTop)]];
#else
    self.navigationController.navigationBar.translucent = NO;
#endif

    // layout
    UISegmentedControl* seg;
    
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        seg = [[UISegmentedControl alloc] initWithItems:@[
            [UIImage systemImageNamed:@"rectangle.grid.2x2.fill"],
            [UIImage systemImageNamed:@"rectangle.stack.fill"],
            [UIImage systemImageNamed:@"rectangle.grid.1x2.fill"]
        ]];
    } else {
        seg = [[UISegmentedControl alloc] initWithItems:@[@"☷",@"▢",@"☰"]];
    }

    seg.selectedSegmentIndex = _layoutMode;
    [seg addTarget:self action:@selector(viewChange:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:seg];
    
    // put scope buttons in title (if iPad or tvOS)
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:ALL_SCOPES];
        seg.selectedSegmentIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
        [seg addTarget:self action:@selector(scopeChange:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = seg;
    }
    
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        [UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]].selectedSegmentTintColor = self.view.tintColor;
    }
    
    // Search
#if TARGET_OS_IOS
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;

    _searchController.searchBar.scopeButtonTitles = ALL_SCOPES;
    _searchController.searchBar.selectedScopeButtonIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
    _searchController.searchBar.placeholder = @"Filter";
    
    // make the cancel button say Done
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitle:@"Done"];
    
    self.definesPresentationContext = TRUE;

    // on iOS 11+ use search in navbar, else just add it...
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = TRUE;
    }
    else {
        _searchController.searchBar.barTintColor = [UIColor blackColor];
        
        self.navigationController.navigationBar.translucent = NO;
        _searchController.searchBar.translucent = NO;

        CGFloat h = self.navigationController.navigationBar.frame.size.height;
        _searchController.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, h);
        _searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _searchController.dimsBackgroundDuringPresentation = NO;
        
        self.automaticallyAdjustsScrollViewInsets = FALSE;
        self.collectionView.contentInset = UIEdgeInsetsMake(h, 0, 0, 0);
        [self.view addSubview:_searchController.searchBar];
    }
#else   // tvOS
    if (self.navigationController != nil) {
        // add a search button on tvOS
        UIBarButtonItem* search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearch)];
        self.navigationItem.rightBarButtonItems = [@[search] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
    }
#endif
    
    // collection view
    [self.collectionView registerClass:[GameCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER];
    [self.collectionView registerClass:[GameCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HEADER_IDENTIFIER];
    
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:1.0];
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.alwaysBounceVertical = YES;
}
-(void)scrollToTop
{
    if (@available(iOS 11.0, *))
        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.adjustedContentInset.top * -1.0) animated:TRUE];
    else
        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.contentInset.top * -1.0) animated:TRUE];
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
    _searchController.searchBar.placeholder = @"Filter";
    _searchController.searchBar.showsScopeBar = NO;
    _searchController.hidesNavigationBarDuringPresentation = YES;
    

    //self.definesPresentationContext = TRUE;
    UIViewController* search = [[UISearchContainerViewController alloc] initWithSearchController:_searchController];
    self.navigationController.navigationBarHidden = TRUE;
    //[self presentViewController:search animated:YES completion:nil];
    //[self presentViewController:[[UINavigationController alloc] initWithRootViewController:search] animated:YES completion:nil];
    
    [self.navigationController pushViewController:search animated:YES];
}
#endif

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
    _gameList = games;
    [self filterGameList];
}

-(void)viewChange:(UISegmentedControl*)sender
{
    NSLog(@"VIEW CHANGE: %d", (int)sender.selectedSegmentIndex);
    _layoutMode = sender.selectedSegmentIndex;
    [_userDefaults setInteger:_layoutMode forKey:LAYOUT_MODE_KEY];
    [self updateLayout];
}
-(void)scopeChange:(UISegmentedControl*)sender
{
    NSLog(@"SCOPE CHANGE: %@", ALL_SCOPES[sender.selectedSegmentIndex]);
    _gameFilterScope = ALL_SCOPES[sender.selectedSegmentIndex];
    [_userDefaults setValue:_gameFilterScope forKey:SCOPE_MODE_KEY];
    [self filterGameList];
}

-(NSURL*)getGameImageURL:(NSDictionary*)info
{
    NSString* name = info[kGameInfoDescription];
    
    if (name == nil)
        return nil;
    
    /// from [libretro docs](https://docs.libretro.com/guides/roms-playlists-thumbnails/)
    /// The following characters in titles must be replaced with _ in the corresponding filename: &*/:`<>?\|
    for (NSString* str in @[@"&", @"*", @"/", @":", @"`", @"<", @">", @"?", @"\\", @"|"])
        name = [name stringByReplacingOccurrencesOfString:str withString:@"_"];
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://thumbnails.libretro.com/MAME/Named_Titles/%@.png",
                                 [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]]];
}

-(NSURL*)getGameImageLocalURL:(NSDictionary*)info
{
    NSString* name = info[kGameInfoName];
    
    if (name == nil)
        return nil;
    
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%s/%@.png", get_documents_path("titles"), name]];
}

- (void)filterGameList
{
    NSArray* filteredGames = _gameList;
    
    // filter all games, multiple keywords will be treated as AND
    if ([_gameFilterText length] > 0)
    {
        for (NSString* word in [_gameFilterText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]])
        {
            if ([word length] > 0)
            {
                //filteredGames = [filteredGames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.@description CONTAINS[cd] %@", word]];
                filteredGames = [filteredGames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SUBQUERY(SELF.@allValues, $x, $x CONTAINS[cd] %@).@count > 0", word]];
            }
        }
    }
    
    // group games by category into sections
    NSMutableDictionary* gameData = [[NSMutableDictionary alloc] init];
    NSString* key = @"";
    
    if ([_gameFilterScope isEqualToString:@"Year"])
        key = kGameInfoYear;
    if ([_gameFilterScope isEqualToString:@"Manufacturer"])
        key = kGameInfoManufacturer;
    if ([_gameFilterScope isEqualToString:@"Author"])
        key = kGameInfoManufacturer;
    if ([_gameFilterScope isEqualToString:@"Category"])
        key = kGameInfoCategory;

    for (NSDictionary* game in filteredGames) {
        NSString* section = game[key] ?: @"All";
        
        // a UICollectionView will scroll like crap if we have too many sections, so try to filter/combine similar ones.
        section = [[section componentsSeparatedByString:@" ("] firstObject];
        section = [[section componentsSeparatedByString:@" / "] firstObject];
        section = [[section componentsSeparatedByString:@"/"] firstObject];
        
        section = [section stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (![_gameFilterScope isEqualToString:@"Year"])
            section = [section stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];

        if (gameData[section] == nil)
            gameData[section] = [[NSMutableArray alloc] init];
        [gameData[section] addObject:game];
    }
    
    // and sort section names
    NSArray* gameSectionTitles = [gameData.allKeys sortedArrayUsingSelector:@selector(localizedCompare:)];
    
    // a UICollectionView will scroll like crap if we have too many sections. go through and merge a few
    if ([gameSectionTitles count] > 200) {
        NSLog(@"TOO MANY SECTIONS: %d!", (int)[gameSectionTitles count]);
        
        NSMutableArray* new_titles = [[NSMutableArray alloc] init];
        
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
                
                [new_titles addObject:new_title];
                i++;
            }
            else {
                [new_titles addObject:title_0];
            }
        }
        gameSectionTitles = [new_titles copy];
        NSLog(@"SECTIONS AFTER MERGE: %d!", (int)[gameSectionTitles count]);
    }
 
    // add favorite games
    NSArray* favoriteGames = [[_userDefaults objectForKey:FAVORITE_GAMES_KEY]
        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", filteredGames]];
    
    if ([favoriteGames count] > 0) {
        //NSLog(@"FAVORITE GAMES: %@", favoriteGames);
        gameSectionTitles = [@[FAVORITE_GAMES_TITLE] arrayByAddingObjectsFromArray:gameSectionTitles];
        gameData[FAVORITE_GAMES_TITLE] = favoriteGames;
    }

    // load recent games and put them at the top
    NSArray* recentGames = [[_userDefaults objectForKey:RECENT_GAMES_KEY]
        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", filteredGames]];

    NSUInteger maxRecentGames = RECENT_GAMES_MAX;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        maxRecentGames = RECENT_GAMES_MIN;
        
    if ([recentGames count] > maxRecentGames)
        recentGames = [recentGames subarrayWithRange:NSMakeRange(0, maxRecentGames)];

    if ([recentGames count] > 0) {
        //NSLog(@"RECENT GAMES: %@", recentGames);
        gameSectionTitles = [@[RECENT_GAMES_TITLE] arrayByAddingObjectsFromArray:gameSectionTitles];
        gameData[RECENT_GAMES_TITLE] = recentGames;
    }
    
    // now put "system" items at the end
    // TODO: maybe these should be at the top (after Recents and Favorites)?
    gameSectionTitles = [gameSectionTitles arrayByAddingObjectsFromArray:@[SYSTEM_GAMES_TITLE]];
    gameData[SYSTEM_GAMES_TITLE] = @[
        @{kGameInfoDescription:@"MAME MENU", kGameInfoName:kGameInfoNameMameMenu},
        @{kGameInfoDescription:@"Settings", kGameInfoName:kGameInfoNameSettings},
    ];
    
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
        if (![searchBar.text isEqualToString:_gameFilterText])
            searchBar.text = _gameFilterText;
        return;
    }
    NSString* text = searchBar.text;
    NSString* scope = searchBar.scopeButtonTitles[searchBar.selectedScopeButtonIndex];
    
    if (![_gameFilterText isEqualToString:text] || ![_gameFilterScope isEqualToString:scope]) {
        _gameFilterText = text;
        _gameFilterScope = scope;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(filterGameList) object:nil];
        [self performSelector:@selector(filterGameList) withObject:nil afterDelay:0.500];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchBarTextDidBeginEditing");
    _searchCancel = FALSE;
    searchBar.selectedScopeButtonIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSLog(@"searchBarTextDidEndEditing");
    
    UISegmentedControl* seg = (UISegmentedControl*)self.navigationItem.titleView;
    if ([seg isKindOfClass:[UISegmentedControl class]]) {
        seg.selectedSegmentIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
    }
}
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    _gameFilterScope = searchBar.scopeButtonTitles[selectedScope];
    [_userDefaults setValue:_gameFilterScope forKey:SCOPE_MODE_KEY];
    [self filterGameList];
}

#if TARGET_OS_IOS
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarSearchButtonClicked");
    _searchCancel = TRUE;
    _searchController.active = NO;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSLog(@"searchBarCancelButtonClicked");
    _searchCancel = TRUE;
}
#endif

#pragma mark - UICollectionView

-(void)reloadData
{
    [self.collectionView reloadData];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    // HACK kick the layout in the head, so it gets the location of headers correct
    if (@available(iOS 13.0, *)) {} else {
        CGPoint offset = self.collectionView.contentOffset;
        [self.collectionView setContentOffset:CGPointMake(offset.x, offset.y + 0.5)];
        [self.collectionView layoutIfNeeded];
        [self.collectionView setContentOffset:offset];
    }
}

-(void)updateLayout
{
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat space = 8.0;
#if TARGET_OS_TV
    space *= 2.0;
#endif
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(space, space, space, space);
    layout.minimumLineSpacing = space;
    layout.minimumInteritemSpacing = space;
    layout.sectionHeadersPinToVisibleBounds = YES;
    
    CGFloat height = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize * 2.0;
#if TARGET_OS_IOS
    if (@available(iOS 11.0, *)) {
        height = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle].pointSize;
    }
#endif
    layout.headerReferenceSize = CGSizeMake(height, height);

    if (@available(iOS 11.0, *)) {
        layout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
    }
    
    CGFloat width = self.collectionView.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right);
    
    width -= (self.safeAreaInsets.left + self.safeAreaInsets.right);

    if (@available(iOS 11.0, *))
        width -= (self.collectionView.adjustedContentInset.left + self.collectionView.adjustedContentInset.right);
    else
        width -= (self.collectionView.contentInset.left + self.collectionView.contentInset.right);

    if (_layoutMode == LayoutSmall)
        _layoutCollums = MAX(2,round(width / CELL_SMALL_WIDTH));
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

#pragma mark System

- (BOOL)isSystem:(NSDictionary*)game
{
    return [@[kGameInfoNameMameMenu, kGameInfoNameSettings] containsObject:game[kGameInfoName]];
}

#pragma mark Favorites

- (BOOL)isFavorite:(NSDictionary*)game
{
    NSArray* favoriteGames = [_userDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[];
    return [favoriteGames containsObject:game];
}
- (void)setFavorite:(NSDictionary*)game isFavorite:(BOOL)flag
{
    if (game == nil || [game[kGameInfoName] length] == 0 || [self isSystem:game])
        return;

    NSMutableArray* favoriteGames = [([_userDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[]) mutableCopy];

    [favoriteGames removeObject:game];

    if (flag)
        [favoriteGames insertObject:game atIndex:0];
    
    [_userDefaults setObject:favoriteGames forKey:FAVORITE_GAMES_KEY];
    [self updateApplicationShortcutItems];
}

#pragma mark Recent Games

- (void)setRecent:(NSDictionary*)game isRecent:(BOOL)flag
{
    if (game == nil || [game[kGameInfoName] length] == 0 || [self isSystem:game])
        return;
    
    NSMutableArray* recentGames = [([_userDefaults objectForKey:RECENT_GAMES_KEY] ?: @[]) mutableCopy];

    [recentGames removeObject:game];
    if (flag)
        [recentGames insertObject:game atIndex:0];
    if ([recentGames count] > RECENT_GAMES_MAX)
        [recentGames removeObjectsInRange:NSMakeRange(RECENT_GAMES_MAX,[recentGames count] - RECENT_GAMES_MAX)];

    [_userDefaults setObject:recentGames forKey:RECENT_GAMES_KEY];
    [self updateApplicationShortcutItems];
}

#pragma mark Application Shortcut Items

#define MAX_SHORTCUT_ITEMS 4

- (void) updateApplicationShortcutItems {
#if TARGET_OS_IOS
    NSArray* recentGames = [_userDefaults objectForKey:RECENT_GAMES_KEY] ?: @[];
    NSArray* favoriteGames = [([_userDefaults objectForKey:FAVORITE_GAMES_KEY] ?: @[])
                              filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", recentGames]];
    
    NSLog(@"updateApplicationShortcutItems");
    NSLog(@"    RECENT GAMES(%d): %@", (int)[recentGames count], recentGames);
    NSLog(@"    FAVORITE GAMES(%d): %@", (int)[favoriteGames count], favoriteGames);
    
    NSUInteger maxRecent = MAX_SHORTCUT_ITEMS - MIN([favoriteGames count], MAX_SHORTCUT_ITEMS/2);
    NSUInteger numRecent = MIN([recentGames count], maxRecent);
    NSUInteger numFavorite = MIN([favoriteGames count], MAX_SHORTCUT_ITEMS - numRecent);
    
    recentGames = [recentGames subarrayWithRange:NSMakeRange(0, numRecent)];
    favoriteGames = [favoriteGames subarrayWithRange:NSMakeRange(0, numFavorite)];
    
    NSMutableArray* shortcutItems = [[NSMutableArray alloc] init];
    
    for (NSDictionary* game in [recentGames arrayByAddingObjectsFromArray:favoriteGames]) {
        NSString* type = [NSString stringWithFormat:@"%@.%@", NSBundle.mainBundle.bundleIdentifier, @"play"];
        NSString* name = game[kGameInfoDescription] ?: game[kGameInfoName];
        NSString* title = [NSString stringWithFormat:@"%@", [[name componentsSeparatedByString:@" ("] firstObject]];
        UIApplicationShortcutIcon* icon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypePlay];
        
        if (@available(iOS 13.0, *))
            icon = [UIApplicationShortcutIcon iconWithSystemImageName:[self isFavorite:game] ? @"heart" : @"gamecontroller"];
        
        UIApplicationShortcutItem* item = [[UIApplicationShortcutItem alloc] initWithType:type
                                           localizedTitle:title localizedSubtitle:nil
                                           icon:icon userInfo:game];
        [shortcutItems addObject:item];
    }

    [UIApplication sharedApplication].shortcutItems = shortcutItems;
#endif
}


#pragma mark UICollectionView data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [_gameSectionTitles count];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_gameData[_gameSectionTitles[section]] count];
}
-(NSDictionary*)getGameInfo:(NSIndexPath*)indexPath
{
    return _gameData[_gameSectionTitles[indexPath.section]][indexPath.item];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"cellForItemAtIndexPath: %d.%d", (int)indexPath.section, (int)indexPath.item);
    
    NSDictionary* info = [self getGameInfo:indexPath];
    
    GameCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    
    cell.title.text = info[kGameInfoDescription];
    
//    cell.title.text = @"Call me Ishmael. Some years ago - never mind how long precisely - having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world.";
    
    NSString* text = info[kGameInfoManufacturer];
    
    if ([info[kGameInfoYear] length] > 1)
        text = [NSString stringWithFormat:@"%@ • %@", text, info[kGameInfoYear]];
    
    if ([info[kGameInfoName] length] > 1 && ![self isSystem:info])
        text = [NSString stringWithFormat:@"%@ • %@", text, info[kGameInfoName]];

    if ([info[kGameInfoParent] length] > 1)
        text = [NSString stringWithFormat:@"%@ [%@]", text, info[kGameInfoParent]];

    if ([text hasPrefix:@" • "])
        text = [text substringFromIndex:3];
    
    cell.detail.text = text;
    cell.info.text = nil;

    [cell setHorizontal:_layoutMode == LayoutList];

    NSURL* url = [self getGameImageURL:info];
    NSURL* local = [self getGameImageLocalURL:info];
    cell.tag = url.hash;
    [[ImageCache sharedInstance] getImage:url size:CGSizeZero localURL:local completionHandler:^(UIImage *image) {
        if (cell.tag != url.hash || image == nil)
            return;
        
        BOOL async = cell.image.image != nil;
        cell.image.image = image;

        if (async && [[self.collectionView indexPathForCell:cell] isEqual:indexPath])
        {
            NSLog(@"CELL ASYNC LOAD: %@ %d:%d", info[kGameInfoName], (int)indexPath.section, (int)indexPath.item);
            BOOL selected = cell.isSelected;
            BOOL enabled = [UIView areAnimationsEnabled];

            // reload the new image without animation to prevent "jumping"
            [UIView setAnimationsEnabled:NO];
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            if (selected) {
                [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
            }
            [UIView setAnimationsEnabled:enabled];
        }
    }];
    
    // use a placeholder image if the image did not load right away.
    if (cell.image.image == nil)
        cell.image.image = [UIImage imageNamed:info[kGameInfoName]] ?: [UIImage imageNamed:@"DEFAULT"];
    
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)layout insetForSectionAtIndex:(NSInteger)section
{
    // UICollectionViewFlowLayout will center a section with a single item in it, else it will left align, WTF!
    // we want left aligned all the time, so mess with the section inset to make it do the right thing.
    
    if (section >= [_gameSectionTitles count] || [_gameData[_gameSectionTitles[section]] count] != 1)
        return layout.sectionInset;
            
    CGFloat itemWidth = (layout.estimatedItemSize.width != 0.0) ? layout.estimatedItemSize.width : layout.itemSize.width;
    CGFloat width = collectionView.bounds.size.width - (layout.sectionInset.left + layout.sectionInset.right) - (self.safeAreaInsets.left + self.safeAreaInsets.right);
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
    cell.title.text = _gameSectionTitles[indexPath.section];
    cell.title.font = [UIFont systemFontOfSize:cell.bounds.size.height * 0.8 weight:UIFontWeightHeavy];
    cell.title.textColor = [UIColor whiteColor];
    [cell setTextInsets:UIEdgeInsetsMake(2.0, self.safeAreaInsets.left + 2.0, 2.0, self.safeAreaInsets.right + 2.0)];
    cell.contentView.backgroundColor = [self.collectionView.backgroundColor colorWithAlphaComponent:0.5];
    cell.layer.cornerRadius = 0.0;
    cell.contentView.layer.cornerRadius = 0.0;
    cell.contentView.layer.borderWidth = 0.0;
    cell.layer.shadowRadius = 0.0;
    cell.layer.shadowOpacity = 0.0;

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

#pragma mark UICollectionView index (only on tvOS)

#if TARGET_OS_TV
- (NSArray*)indexTitlesForCollectionView:(UICollectionView *)collectionView
{
    if ([_gameFilterScope isEqualToString:@"All"])
        return @[];

    NSMutableSet* set = [[NSMutableSet alloc] init];
    for (NSString* section in _gameSectionTitles) {
        if ([section isEqualToString:RECENT_GAMES_TITLE] || [section isEqualToString:FAVORITE_GAMES_TITLE])
            continue;
        if ([_gameFilterScope isEqualToString:@"Year"])
            [set addObject:section];
        else
            [set addObject:[section substringToIndex:1]];
    }
    return [[set allObjects] sortedArrayUsingSelector:@selector(localizedCompare:)];
}

/// Returns the index path that corresponds to the given title / index. (e.g. "B",1)
/// Return an index path with a single index to indicate an entire section, instead of a specific item.
- (NSIndexPath *)collectionView:(UICollectionView *)collectionView indexPathForIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[NSIndexPath alloc] initWithIndex:0];
}
#endif

#pragma mark - UIContextMenu (iOS 13+ only)

#if TARGET_OS_IOS
- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    NSDictionary* game = [self getGameInfo:indexPath];
    
    if (game == nil || [game[kGameInfoName] length] == 0)
        return nil;

    NSLog(@"contextMenuConfigurationForItem: [%d.%d] %@ %@", (int)indexPath.section, (int)indexPath.row, game[kGameInfoName], game);
    
    return [UIContextMenuConfiguration configurationWithIdentifier:indexPath
            previewProvider:^UIViewController* () {
                return nil;     // use default
            }
            actionProvider:^UIMenu* (NSArray* suggestedActions) {
                BOOL is_fav = [self isFavorite:game];
        
                NSString* fav_text = is_fav ? @"Unfavorite" : @"Favorite";
                NSString* fav_icon = is_fav ? @"heart.slash" : @"heart";

                UIAction* fav = [UIAction actionWithTitle:fav_text image:[UIImage systemImageNamed:fav_icon] identifier:nil handler:^(UIAction* action) {
                    [self setFavorite:game isFavorite:!is_fav];
                    [self filterGameList];
                }];
                
                UIAction* play = [UIAction actionWithTitle:@"Play" image:[UIImage systemImageNamed:@"gamecontroller"] identifier:nil handler:^(UIAction* action) {
                    [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
                }];
                
                UIAction* share = [UIAction actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(UIAction* action) {
                    
                    NSURL* url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%s/%@.zip", get_documents_path("roms"), game[kGameInfoName]]];
                    
                    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path])
                        return;
                    
                    UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
                    [activity setCompletionWithItemsHandler:^(UIActivityType activityType, BOOL completed, NSArray* _Nullable returnedItems, NSError* activityError) {
                        NSLog(@"%@", activityType);
                    }];

                    if (activity.popoverPresentationController != nil) {
                        activity.popoverPresentationController.sourceView = self.view;
                        activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0.0f, 0.0f);;
                        activity.popoverPresentationController.permittedArrowDirections = 0;
                    }

                    [self presentViewController:activity animated:YES completion:nil];
                }];

                UIAction* remove = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(UIAction* action) {
                    NSArray* paths = @[@"roms/%@.zip", @"roms/%@", @"artwork/%@.zip", @"titles/%@.png", @"samples/%@.zip", @"cfg/%@.cfg"];
                    
                    NSString* root = [NSString stringWithUTF8String:get_documents_path("")];
                    for (NSString* path in paths) {
                        NSString* delete_path = [root stringByAppendingPathComponent:[NSString stringWithFormat:path, game[kGameInfoName]]];
                        NSLog(@"DELETE: %@", delete_path);
                        [[NSFileManager defaultManager] removeItemAtPath:delete_path error:nil];
                    }
                    
                    [self setRecent:game isRecent:FALSE];
                    [self setFavorite:game isFavorite:FALSE];

                    [self setGameList:[self->_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", game]]];
                    if ([self->_gameList count] == 0) {
                        if (self.selectGameCallback != nil)
                            self.selectGameCallback(nil);
                    }
                }];
                remove.attributes = UIMenuElementAttributesDestructive;

                return [UIMenu menuWithTitle:@"" children:@[play, fav, share, remove]];
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
-(void)handle_MENU {
    unsigned long pad_status = myosd_pad_status | myosd_joy_status[0] | myosd_joy_status[1];

    if (pad_status & MYOSD_A)
        [self onCommandSelect];
    if (pad_status & MYOSD_UP)
        [self onCommandUp];
    if (pad_status & MYOSD_DOWN)
        [self onCommandDown];
    if (pad_status & MYOSD_LEFT)
        [self onCommandLeft];
    if (pad_status & MYOSD_RIGHT)
        [self onCommandRight];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (NSArray*)keyCommands {
    
    if (_searchController.isActive)
        return @[];
    
    if (_key_commands == nil) {

        // standard keyboard
        _key_commands = @[
            [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(onCommandSelect) discoverabilityTitle:@"SELECT"],
            [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(onCommandUp) discoverabilityTitle:@"UP"],
            [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(onCommandDown) discoverabilityTitle:@"DOWN"],
            [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(onCommandLeft) discoverabilityTitle:@"LEFT"],
            [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(onCommandRight) discoverabilityTitle:@"RIGHT"]
        ];
        
        if (g_pref_ext_control_type >= EXT_CONTROL_ICADE) {
            // iCade
            _key_commands = [_key_commands arrayByAddingObjectsFromArray:@[
                [UIKeyCommand keyCommandWithInput:@"y" modifierFlags:0 action:@selector(onCommandSelect)], // SELECT
                [UIKeyCommand keyCommandWithInput:@"h" modifierFlags:0 action:@selector(onCommandSelect)], // START
                [UIKeyCommand keyCommandWithInput:@"k" modifierFlags:0 action:@selector(onCommandSelect)], // A
                [UIKeyCommand keyCommandWithInput:@"o" modifierFlags:0 action:@selector(onCommandSelect)], // B
                [UIKeyCommand keyCommandWithInput:@"i" modifierFlags:0 action:@selector(onCommandSelect)], // Y
                [UIKeyCommand keyCommandWithInput:@"l" modifierFlags:0 action:@selector(onCommandSelect)], // X
                [UIKeyCommand keyCommandWithInput:@"w" modifierFlags:0 action:@selector(onCommandUp)],
                [UIKeyCommand keyCommandWithInput:@"x" modifierFlags:0 action:@selector(onCommandDown)],
                [UIKeyCommand keyCommandWithInput:@"a" modifierFlags:0 action:@selector(onCommandLeft)],
                [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:0 action:@selector(onCommandRight)],
            ]];
        }
        else {
            // 8BitDo
            _key_commands = [_key_commands arrayByAddingObjectsFromArray:@[
                [UIKeyCommand keyCommandWithInput:@"n" modifierFlags:0 action:@selector(onCommandSelect)], // SELECT
                [UIKeyCommand keyCommandWithInput:@"o" modifierFlags:0 action:@selector(onCommandSelect)], // START
                [UIKeyCommand keyCommandWithInput:@"g" modifierFlags:0 action:@selector(onCommandSelect)], // A
                [UIKeyCommand keyCommandWithInput:@"c" modifierFlags:0 action:@selector(onCommandUp)],
                [UIKeyCommand keyCommandWithInput:@"d" modifierFlags:0 action:@selector(onCommandDown)],
                [UIKeyCommand keyCommandWithInput:@"e" modifierFlags:0 action:@selector(onCommandLeft)],
                [UIKeyCommand keyCommandWithInput:@"f" modifierFlags:0 action:@selector(onCommandRight)],
            ]];
        }
    }
    return _key_commands;
}
#endif

#pragma mark UIEvent handling for button presses

#if TARGET_OS_TV
- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event; {
    // exit the app (to the aTV home screen) when the user hits MENU at the root
    // if we dont do this tvOS will just dismiss us
    if ([self.navigationController topViewController] == self) {
        for (UIPress *press in presses) {
            if (press.type == UIPressTypeMenu) {
                exit(0);
            }
        }
    }
    // not a menu press, delegate to UIKit responder handling
    [super pressesBegan:presses withEvent:event];
}
#endif

@end

#pragma mark - Custom ImageView

@interface ImageView : UIImageView
@property (readwrite, nonatomic) CGSize contentSize;
@end

@implementation ImageView
- (CGSize)intrinsicContentSize {
    CGSize size = _contentSize;
    
    if (self.image == nil)
        return size;
    
    if (size.width == 0.0 && size.height == 0.0)
        return self.image.size;
    
    if (size.width == 0.0)
        size.width = floor(size.height * (self.image.size.width / self.image.size.height));
    if (size.height == 0.0)
        size.height = floor(size.width * (self.image.size.height / self.image.size.width));
    
    return size;
}
- (void)setContentSize:(CGSize)contentSize {
    _contentSize = contentSize;
    [self invalidateIntrinsicContentSize];
}
@end


#pragma mark - GameCell

@interface GameCell () {
    UIStackView* _stackView;
    UIStackView* _stackText;
}
@end

@implementation GameCell

// Two different cell typres, horz or vertical
//
// +-----------------+   +----------+-----------------+
// |                 |   |          | Title           |
// |                 |   |  Image   | detail          |
// |    Image        |   |          | info            |
// |                 |   +----------+-----------------+
// |                 |
// +-----------------+
// | Title           |
// | detail          |
// | info            |
// +-----------------+
//
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    _image = [[ImageView alloc] init];
    _title = [[UILabel alloc] init];
    _detail = [[UILabel alloc] init];
    _info = [[UILabel alloc] init];
    
    _stackText = [[UIStackView alloc] initWithArrangedSubviews:@[_title, _detail, _info]];
    _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_image, _stackText]];

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
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.222 alpha:1.0];

    self.layer.cornerRadius = 8.0;
    self.contentView.layer.cornerRadius = 8.0;
    self.contentView.clipsToBounds = YES;

    self.contentView.layer.borderWidth = 2.0;
    self.contentView.layer.borderColor = self.contentView.backgroundColor.CGColor;

    self.layer.shadowColor = UIColor.clearColor.CGColor; // UIColor.darkGrayColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0f);
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOpacity = 1.0;
    
    _title.text = nil;
    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _title.textColor = [UIColor whiteColor];
    _title.numberOfLines = 0;
    
    _detail.text = nil;
    _detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _detail.textColor = [UIColor lightGrayColor];
    _detail.numberOfLines = 0;
    
    _info.text = nil;
    _info.font = _detail.font;
    _info.textColor = _detail.textColor;
    _info.numberOfLines = 1;
    _info.adjustsFontSizeToFitWidth = TRUE;

    _image.image = nil;
    _image.contentMode = UIViewContentModeScaleAspectFill;
    [_image setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    _stackView.axis = UILayoutConstraintAxisVertical;
    _stackView.alignment = UIStackViewAlignmentFill;
    _stackView.distribution = UIStackViewDistributionFill;
    _stackView.preservesSuperviewLayoutMargins = NO;
    
    _stackText.axis = UILayoutConstraintAxisVertical;
    _stackText.alignment = UIStackViewAlignmentFill;
    _stackText.distribution = UIStackViewDistributionFill;
    _stackText.layoutMargins = UIEdgeInsetsMake(4.0, 8.0, 4.0, 8.0);
    _stackText.layoutMarginsRelativeArrangement = YES;

    if (@available(iOS 11.0, *)) {
        _stackText.insetsLayoutMarginsFromSafeArea = NO;
    }
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

    _title.preferredMaxLayoutWidth = width;
    _detail.preferredMaxLayoutWidth = width;
    _info.preferredMaxLayoutWidth = width;

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

- (CGSize)sizeThatFits:(CGSize)targetSize
{
    if (_stackView.axis == UILayoutConstraintAxisHorizontal)
        return targetSize;
    
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

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.25 animations:^{
        self.layer.shadowColor = highlighted ? self.tintColor.CGColor : UIColor.clearColor.CGColor;
        self.transform = highlighted ? CGAffineTransformMakeScale(0.98, 0.98) : CGAffineTransformIdentity;
    }];
}
- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [UIView animateWithDuration:0.25 animations:^{
        self.layer.shadowColor = selected ? self.tintColor.CGColor : UIColor.clearColor.CGColor;
        self.transform = selected ? CGAffineTransformMakeScale(1.02, 1.02) : CGAffineTransformIdentity;
    }];
}
#if TARGET_OS_TV
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    [coordinator addCoordinatedAnimations:^{
        self.layer.shadowColor = self.focused ? self.tintColor.CGColor : UIColor.clearColor.CGColor;
        self.transform = self.focused ? CGAffineTransformMakeScale(1.02, 1.02) : CGAffineTransformIdentity;
    } completion:nil];
}
#endif
@end



