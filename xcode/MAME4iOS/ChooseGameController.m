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
#import "SystemImage.h"
#import "Globals.h"
#import "myosd.h"

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
#else
#define CELL_TINY_WIDTH    200.0
#define CELL_SMALL_WIDTH   400.0
#define CELL_LARGE_WIDTH   600.0
#endif

#define USE_TITLE_IMAGE         TRUE
#define BACKGROUND_COLOR        [UIColor blackColor]
#define TITLE_COLOR             [UIColor whiteColor]
#define HEADER_TEXT_COLOR       [UIColor whiteColor]
#define CELL_BACKGROUND_COLOR   [UIColor colorWithWhite:0.222 alpha:1.0]
#define CELL_TITLE_COLOR        [UIColor whiteColor]
#define CELL_DETAIL_COLOR       [UIColor lightGrayColor]
#define CELL_INFO_COLOR         [UIColor lightGrayColor]
#define CELL_SELECTED_COLOR     self.tintColor

#define HEADER_IDENTIFIER   @"GameInfoHeader"

#define LAYOUT_MODE_KEY     @"LayoutMode"
#define SCOPE_MODE_KEY      @"ScopeMode"
#define RECENT_GAMES_MAX    8
#define ALL_SCOPES          @[@"All", @"Manufacturer", @"Year", @"Genre"]

#define CLAMP(x, num) MIN(MAX(x,0), (num)-1)

typedef NS_ENUM(NSInteger, LayoutMode) {
    LayoutTiny,
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

UIView* find_view(UIView* view, Class class) {
    if ([view isKindOfClass:class])
        return view;
    for (UIView* subview in view.subviews) {
        if ((view = find_view(subview, class)))
            return view;
    }
    return nil;
}

#pragma mark ChooseGameController

@interface ChooseGameController () <UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate> {
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
    NSIndexPath* currentlyFocusedIndexPath;
    UIImage* _defaultImage;
    UIImage* _loadingImage;
    NSMutableSet* _updated_urls;
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
    
    _defaultImage = [UIImage imageNamed:@"default_game_icon"];
    _loadingImage = [UIImage imageNamed:@"loading_game_icon"];

    return self;
}

- (void)viewDidLoad
{
#if USE_TITLE_IMAGE
    UIImage* image = [[UIImage imageNamed:@"mame_logo"] scaledToSize:CGSizeMake(0.0, 44.0)];
    UIImageView* title = [[UIImageView alloc] initWithImage:image];
#else
    UILabel* title = [[UILabel alloc] init];
    #if TARGET_OS_IOS
    title.text = @"MAME4iOS";
    title.font = [UIFont boldSystemFontOfSize:44.0 * 0.6];
    #else
    title.text = @"MAME4tvOS";
    title.font = [UIFont boldSystemFontOfSize:44.0];
    #endif
    title.textColor = TITLE_COLOR;
    [title sizeToFit];
#endif

    // put the title on the left, and set center title to nil
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:title];
    self.title = nil;
    
    //navbar
#if TARGET_OS_IOS
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = BACKGROUND_COLOR;
    [self.navigationController.navigationBar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToTop)]];
#else
    self.navigationController.navigationBar.translucent = NO;
#endif

    // layout
    UISegmentedControl* seg;
    
    seg = [[UISegmentedControl alloc] initWithItems:@[
        [UIImage systemImageNamed:@"square.grid.4x3.fill"]    ?: @"⚏",
        [UIImage systemImageNamed:@"rectangle.grid.2x2.fill"] ?: @"☷",
        [UIImage systemImageNamed:@"rectangle.stack.fill"]    ?: @"▢",
        [UIImage systemImageNamed:@"rectangle.grid.1x2.fill"] ?: @"☰"
    ]];

    seg.selectedSegmentIndex = _layoutMode;
    [seg addTarget:self action:@selector(viewChange:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:seg];
    
    // put scope buttons in title (if iPad or tvOS)
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        UISegmentedControl* seg = [[UISegmentedControl alloc] initWithItems:ALL_SCOPES];
        seg.selectedSegmentIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
        //seg.apportionsSegmentWidthsByContent = YES;
        [seg addTarget:self action:@selector(scopeChange:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = seg;
    }
    
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
    _searchController.searchBar.scopeButtonTitles = ALL_SCOPES;

    if ([UIScreen mainScreen].bounds.size.width <= 375) {
        UISegmentedControl* seg = (UISegmentedControl*)find_view(_searchController.searchBar, [UISegmentedControl class]);
        [seg setApportionsSegmentWidthsByContent:YES];
    }

    _searchController.searchBar.selectedScopeButtonIndex = [ALL_SCOPES indexOfObject:_gameFilterScope];
    _searchController.searchBar.placeholder = @"Filter";
    
    // make the cancel button say Done
    //[[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitle:@"Done"];
    _searchController.searchBar.showsCancelButton = YES;
    [self updateSearchCancelButton];

    self.definesPresentationContext = TRUE;

    // put search in navbar...
    self.navigationItem.searchController = _searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = TRUE;
#else   // tvOS
    if (self.navigationController != nil) {
        // add a search button on tvOS
        UIBarButtonItem* search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearch)];
        self.navigationItem.rightBarButtonItems = [@[search] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
        
        // add a settings button on tvOS
        if (@available(tvOS 13.0, *)) {
            UIImage* image = [UIImage systemImageNamed:@"gear" withPointSize:title.bounds.size.height weight:UIFontWeightHeavy];
            UIBarButtonItem* settings = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
            self.navigationItem.rightBarButtonItems = [@[settings] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
        } else {
            UIBarButtonItem* settings = [[UIBarButtonItem alloc] initWithTitle:@"⚙️" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
            self.navigationItem.rightBarButtonItems = [@[settings] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
        }
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
}
-(void)scrollToTop
{
    if (@available(iOS 11.0, *))
        [self.collectionView setContentOffset:CGPointMake(0, (self.collectionView.adjustedContentInset.top - _searchController.searchBar.bounds.size.height) * -1.0) animated:TRUE];
    else
        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.contentInset.top * -1.0) animated:TRUE];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    // add a *special* system game that will run the DOS MAME menu.

    games = [games arrayByAddingObject:@{
        kGameInfoName:kGameInfoNameMameMenu,
        kGameInfoDescription:@"MAME Menu",
        kGameInfoYear:@"2010",
        kGameInfoManufacturer:@"MAME4iOS",
        kGameInfoCategory:@"MAME4iOS"
    }];
    
    // then (re)sort the list by description
    games = [games sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kGameInfoDescription ascending:TRUE]]];
    
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
    
    if ([self isSystem:info])
        return [[NSBundle mainBundle] URLForResource:name withExtension:@"png"];
    
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%s/%@.png", get_documents_path("titles"), name] isDirectory:NO];
}

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
    NSString* key = @"";
    
    if ([_gameFilterScope isEqualToString:@"Year"])
        key = kGameInfoYear;
    if ([_gameFilterScope isEqualToString:@"Manufacturer"])
        key = kGameInfoManufacturer;
    if ([_gameFilterScope isEqualToString:@"Category"])
        key = kGameInfoCategory;
    if ([_gameFilterScope isEqualToString:@"Genre"])
        key = kGameInfoCategory;

    for (NSDictionary* game in filteredGames) {
        NSString* section = game[key] ?: @"All";
        
        // a UICollectionView will scroll like crap if we have too many sections, so try to filter/combine similar ones.
        section = [[section componentsSeparatedByString:@" ("] firstObject];
        //section = [[section componentsSeparatedByString:@" / "] firstObject];
        //section = [[section componentsSeparatedByString:@"/"] firstObject];
        
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
    
    if ([recentGames count] > maxRecentGames)
        recentGames = [recentGames subarrayWithRange:NSMakeRange(0, maxRecentGames)];

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
    NSString* scope = ALL_SCOPES[searchBar.selectedScopeButtonIndex];
    
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
    _gameFilterScope = ALL_SCOPES[selectedScope];
    [_userDefaults setValue:_gameFilterScope forKey:SCOPE_MODE_KEY];
    [self filterGameList];
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

- (void)willPresentSearchController:(UISearchController *)searchController
{
    NSLog(@"willPresentSearchController: active=%d", searchController.active);
}
- (void)didPresentSearchController:(UISearchController *)searchController
{
    NSLog(@"didPresentSearchController: active=%d", searchController.active);
    [self updateSearchCancelButton];
}
- (void)willDismissSearchController:(UISearchController *)searchController
{
    NSLog(@"willDismissSearchController: active=%d", searchController.active);
}
- (void)didDismissSearchController:(UISearchController *)searchController
{
    NSLog(@"didDismissSearchController: active=%d", searchController.active);
    [self updateSearchCancelButton];
}

#pragma mark - SearchBar cancel button

//
// we have hijacked the meaning of the search cancel button.
//
//    * it is allways shown, even when we are not searching.
//    * when we are searching the text says "Done" and it will end search mode
//    * when we are not searching the text says "Settings" and it will go to Settings
//
// if we cant find the button, seartch still works, just no Settings button, user can get to it via in-game-menu
//
-(void)updateSearchCancelButton
{
#if TARGET_OS_IOS
    UISearchBar* searchBar = _searchController.searchBar;
    UIButton* button = (UIButton*)find_view(searchBar, NSClassFromString(@"UINavigationButton"));

    if (button == nil) {
        NSLog(@"CANT FIND CANCEL BUTTON!");
        searchBar.showsCancelButton = NO;
        return;
    }

    if (_searchController.active) {
        [button setTitle:@"Done" forState:UIControlStateNormal];
        [button setImage:nil forState:UIControlStateNormal];
    }
    else {
        if (@available(iOS 13.0, *)) {
            UIImage* image = [UIImage systemImageNamed:@"gear" withPointSize:searchBar.searchTextField.font.pointSize weight:UIFontWeightHeavy];
            [button setTitle:@"" forState:UIControlStateNormal];
            [button setImage:image forState:UIControlStateNormal];
        }
        else {
            [button setTitle:@"Settings" forState:UIControlStateNormal];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(-4.0, 0, 0, 0)];
        }
    }
    searchBar.showsCancelButton = YES;
    [button invalidateIntrinsicContentSize];
    [button.superview setNeedsLayout];
#endif
}

#pragma mark - UICollectionView

-(void)invalidateLayout
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    // HACK kick the layout in the head, so it gets the location of headers correct
    CGPoint offset = self.collectionView.contentOffset;
    [self.collectionView setContentOffset:CGPointMake(offset.x, offset.y + 0.5)];
    [self.collectionView layoutIfNeeded];
    [self.collectionView setContentOffset:offset];
}

-(void)reloadData
{
    [self.collectionView reloadData];
    [self invalidateLayout];
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

    if (_layoutMode == LayoutTiny)
        _layoutCollums = MAX(2,round(width / CELL_TINY_WIDTH));
    else if (_layoutMode == LayoutSmall)
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
    if (game == nil || [game[kGameInfoName] length] == 0)
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
    if (game == nil || [game[kGameInfoName] length] == 0)
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

#pragma mark Update Images

-(void)updateImages
{
    if (self.collectionView.isDragging || self.collectionView.isTracking || self.collectionView.isDecelerating) {
        NSLog(@"updateImages: SCROLLING (will try again)");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateImages) object:nil];
        [self performSelector:@selector(updateImages) withObject:nil afterDelay:1.0];
        return;
    }

    NSMutableArray* update_items = [[NSMutableArray alloc] init];

    // ok get all the *visible* indexPaths and see if any need a refresh/reload
    NSArray* vis_items = [self.collectionView indexPathsForVisibleItems];
    
    for (NSIndexPath* indexPath in vis_items) {
        NSDictionary* game = [self getGameInfo:indexPath];
        NSURL* url = [self getGameImageURL:game];
        if ([_updated_urls containsObject:url])
            [update_items addObject:indexPath];
    }
    
    NSLog(@"updateImages: %d visible items, %d dirty images, %d cells need updated", (int)vis_items.count, (int)_updated_urls.count, (int)update_items.count);
    [_updated_urls removeAllObjects];

    if (update_items.count > 0) {
        NSIndexPath* selectedIndexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
        
        if (selectedIndexPath != nil && ![update_items containsObject:selectedIndexPath])
            selectedIndexPath = nil;
        
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:update_items];
        } completion:^(BOOL finished) {
            if (selectedIndexPath != nil) {
                [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
            }
        }];
    }

    NSLog(@"updateImages DONE!");
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
    NSString* title = _gameSectionTitles[section];
    NSInteger num = [_gameData[title] count];
    if ([title isEqualToString:RECENT_GAMES_TITLE] && _layoutMode <= LayoutSmall)
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
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"cellForItemAtIndexPath: %d.%d", (int)indexPath.section, (int)indexPath.item);
    
    NSDictionary* info = [self getGameInfo:indexPath];
    
    GameCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    
    //  set the text based on the LayoutMode
    //
    //  TINY        SMALL                       LARGE or LIST
    //  ----        -----                       -------------
    //  romname     short Description           full Description
    //              short Manufacturer • Year   full Manufacturer • Year  • romname [parent-rom]
    //
    if (_layoutMode == LayoutTiny) {
        cell.title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        cell.title.text = info[kGameInfoName];
        cell.title.numberOfLines = 1;
        cell.title.adjustsFontSizeToFitWidth = TRUE;
    }
    else if (_layoutMode == LayoutSmall) {
        cell.title.text = [[info[kGameInfoDescription] componentsSeparatedByString:@" ("] firstObject];
        cell.detail.text = [NSString stringWithFormat:@"%@ • %@",
                            [[info[kGameInfoManufacturer] componentsSeparatedByString:@" ("] firstObject],
                            info[kGameInfoYear]];
    }
    else { // LayoutLarge and LayoutList
        cell.title.text = info[kGameInfoDescription];

        NSString* text = info[kGameInfoManufacturer];

        if ([info[kGameInfoYear] length] > 1)
            text = [NSString stringWithFormat:@"%@ • %@", text, info[kGameInfoYear]];
        
        if ([info[kGameInfoName] length] > 1)
            text = [NSString stringWithFormat:@"%@ • %@", text, info[kGameInfoName]];

        if ([info[kGameInfoParent] length] > 1)
            text = [NSString stringWithFormat:@"%@ [%@]", text, info[kGameInfoParent]];

        if ([text hasPrefix:@" • "])
            text = [text substringFromIndex:3];

        cell.detail.text = text;
    }
    
    [cell setHorizontal:_layoutMode == LayoutList];

    NSURL* url = [self getGameImageURL:info];
    NSURL* local = [self getGameImageLocalURL:info];
    cell.tag = url.hash;
    [[ImageCache sharedInstance] getImage:url size:CGSizeZero localURL:local completionHandler:^(UIImage *image) {
        
        // cell has been re-used bail
        if (cell.tag != url.hash)
            return;
        
        // if this is syncronous set image and be done
        if (cell.image.image == nil) {
            cell.image.image = image ?: self->_defaultImage;
            return;
        }
        
        NSLog(@"CELL ASYNC LOAD: %@ %d:%d", info[kGameInfoName], (int)indexPath.section, (int)indexPath.item);
        [self updateImage:url];
        
    }];
    
    // use a placeholder image if the image did not load right away.
    if (cell.image.image == nil)
        cell.image.image = _loadingImage;
    
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
    cell.title.textColor = HEADER_TEXT_COLOR;
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

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"willDisplayCell: %d.%d %@", (int)indexPath.section, (int)indexPath.row, [self getGameInfo:indexPath][kGameInfoName]);

    // if this cell still have the loading image, it went offscreen, got canceled, came back on screen ==> reload just to be safe.
    if ([cell isKindOfClass:[GameCell class]] && ((GameCell*)cell).image.image == _loadingImage)
    {
        NSDictionary* game = [self getGameInfo:indexPath];
        NSURL* url = [self getGameImageURL:game];

        if (url != nil)
            [self updateImage:url];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"endDisplayCell: %d.%d %@", (int)indexPath.section, (int)indexPath.row, [self getGameInfo:indexPath][kGameInfoName]);
    
    if ([cell isKindOfClass:[GameCell class]] && ((GameCell*)cell).image.image == _loadingImage)
    {
        NSDictionary* game = [self getGameInfo:indexPath];
        NSURL* url = [self getGameImageURL:game];
    
        if (url != nil)
            [[ImageCache sharedInstance] cancelImage:url];
    }
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
    
    if (game == nil || [game[kGameInfoName] length] == 0)
        return nil;

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
        }]
    ];

    if (![self isSystem:game]) {
        actions = [actions arrayByAddingObjectsFromArray:@[
#if TARGET_OS_IOS
            [self actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] destructive:NO handler:^(id action) {
                
                NSURL* url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%s/%@.zip", get_documents_path("roms"), game[kGameInfoName]]];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:url.path])
                    return;
                
                UIActivityViewController* activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
                [activity setCompletionWithItemsHandler:^(UIActivityType activityType, BOOL completed, NSArray* _Nullable returnedItems, NSError* activityError) {
                    NSLog(@"%@", activityType);
                }];

                if (activity.popoverPresentationController != nil) {
                    UIView* view = [self.collectionView cellForItemAtIndexPath:indexPath] ?: self.view;
                    activity.popoverPresentationController.sourceView = view;
                    activity.popoverPresentationController.sourceRect = view.bounds;
                    activity.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                }

                [self presentViewController:activity animated:YES completion:nil];
            }],
#endif
            [self actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] destructive:YES handler:^(id action) {
                NSArray* paths = @[@"roms/%@.zip", @"artwork/%@.zip", @"titles/%@.png", @"samples/%@.zip", @"cfg/%@.cfg", @"ini/%@.ini", @"sta/%@", @"hi/%@.hi"];
                
                NSString* root = [NSString stringWithUTF8String:get_documents_path("")];
                for (NSString* path in paths) {
                    NSString* delete_path = [root stringByAppendingPathComponent:[NSString stringWithFormat:path, game[kGameInfoName]]];
                    NSLog(@"DELETE: %@", delete_path);
                    [[NSFileManager defaultManager] removeItemAtPath:delete_path error:nil];
                }
                
                [self setRecent:game isRecent:FALSE];
                [self setFavorite:game isFavorite:FALSE];

                self->_gameList = [self->_gameList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", game]];
                [self filterGameList];

                // if we have deleted the last game, excpet for the MAMEMENU, then exit with no game selected and let a re-scan happen.
                if ([self->_gameList count] <= 1) {
                    if (self.selectGameCallback != nil)
                        self.selectGameCallback(nil);
                }
            }]
        ]];
    }
    return actions;
}

// get the title for the ContextMenu
- (NSString*)menuTitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* game = [self getGameInfo:indexPath];
    
    if (game == nil || [game[kGameInfoName] length] == 0)
        return nil;
    
    return [NSString stringWithFormat:@"%@\n%@ • %@\n%@",
            game[kGameInfoDescription],
            game[kGameInfoManufacturer],
            game[kGameInfoYear],
            ([game[kGameInfoParent] length] > 1) ?
                [NSString stringWithFormat:@"%@ [%@]", game[kGameInfoName], game[kGameInfoParent]] :
                game[kGameInfoName]
            ];
}

#pragma mark - UIContextMenu (iOS 13+ only)

#if TARGET_OS_IOS

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
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

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    NSLog(@"didUpdateFocusInContext: %@ => %@", context.previouslyFocusedIndexPath, context.nextFocusedIndexPath);
    currentlyFocusedIndexPath = context.nextFocusedIndexPath;
}

#pragma mark - LongPress menu (pre iOS 13 and tvOS only)

-(void)handleLongPress:(UIGestureRecognizer*)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
        return;

#if TARGET_OS_TV
    NSIndexPath *indexPath = currentlyFocusedIndexPath;
#else
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[sender locationInView:self.collectionView]];
#endif
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
    // if we dont do this tvOS will just dismiss us (with no game to play)
    // [yuck](https://stackoverflow.com/questions/34522004/allow-menu-button-to-exit-tvos-app-when-pressed-on-presented-modal-view-controll)
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
    self.contentView.backgroundColor = CELL_BACKGROUND_COLOR;

    self.layer.cornerRadius = 8.0;
    self.contentView.layer.cornerRadius = 8.0;
    self.contentView.clipsToBounds = YES;

    self.contentView.layer.borderWidth = 2.0;
    self.contentView.layer.borderColor = self.contentView.backgroundColor.CGColor;

    self.layer.shadowColor = UIColor.clearColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0f);
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOpacity = 1.0;
    
    _title.text = nil;
    _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _title.textColor = CELL_TITLE_COLOR;
    _title.numberOfLines = 0;
    _title.adjustsFontSizeToFitWidth = FALSE;
    
    _detail.text = nil;
    _detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _detail.textColor = CELL_DETAIL_COLOR;
    _detail.numberOfLines = 0;
    _title.adjustsFontSizeToFitWidth = FALSE;

    _info.text = nil;
    _info.font = _detail.font;
    _info.textColor = CELL_INFO_COLOR;
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

- (void)updateSelected
{
    BOOL selected = self.selected || self.focused;
    self.transform = selected ? CGAffineTransformMakeScale(1.02, 1.02) : (self.highlighted ? CGAffineTransformMakeScale(0.98, 0.98) : CGAffineTransformIdentity);
    UIColor* color = selected ? CELL_SELECTED_COLOR : CELL_BACKGROUND_COLOR;
    self.layer.shadowColor = selected ? color.CGColor : UIColor.clearColor.CGColor;
    self.contentView.backgroundColor = color;
    self.contentView.layer.borderColor = color.CGColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    NSLog(@"setHighlighted(%@): %@", self.title.text, highlighted ? @"YES" : @"NO");
    [super setHighlighted:highlighted];
    [self updateSelected];
}
- (void)setSelected:(BOOL)selected
{
    NSLog(@"setSelected(%@): %@", self.title.text, selected ? @"YES" : @"NO");
    [super setSelected:selected];
    [self updateSelected];
}
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



