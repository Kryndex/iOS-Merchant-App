//
//  AppDelegate.m
//  Merchant
//
//  Created by User on 10/21/14.
//  Copyright (c) 2014 com. All rights reserved.
//

#import "AppDelegate.h"

#import "BCMDrawerViewController.h"

#import "BCMSettingsViewController.h"
#import "BCMSetupViewController.h"

#import "BCMMerchantManager.h"

#import "BCMNetworking.h"

#import "UIColor+Utilities.h"

@interface AppDelegate ()

@property (strong, nonatomic) BCMNetworking *networking;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.drawerController = [[BCMDrawerViewController alloc] init];
    self.drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
    
    // Core Data Setup
    [self setupDB];
    
    // Styling
    [self styleNavigationBar];
    
    NSString *merchantAddress = [[NSUserDefaults standardUserDefaults] objectForKey:kBCMWalletSettingsKey];
    if ([merchantAddress length] == 0) {
        [[NSUserDefaults standardUserDefaults] setObject:MERCHANT_TEST_ADDRESS forKey:kBCMWalletSettingsKey];
        [[NSUserDefaults standardUserDefaults] setObject:@"USD" forKey:kBCMCurrencySettingsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:self.drawerController];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    Merchant *merchant = [BCMMerchantManager sharedInstance].activeMerchant;
    if (!merchant) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Setup" bundle:nil];
        UINavigationController *navSetupVC = [mainStoryboard instantiateViewControllerWithIdentifier:kNavStoryboardSetupVCId];
        [self.drawerController presentViewController:navSetupVC animated:NO completion:nil];
    }
    
    if ([[BCMMerchantManager sharedInstance] requirePIN]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinEntrySuccessful:) name:kBCMPinEntryCompletedSuccessfulNotification object:nil];
        PEPinEntryController *pinEntryController = [PEPinEntryController pinVerifyController];
        pinEntryController.navigationBarHidden = YES;
        pinEntryController.pinDelegate = [BCMMerchantManager sharedInstance];
        [self.drawerController presentViewController:pinEntryController animated:NO completion:nil];
    }
    
    [self updateCurrencies];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// Global Styling
- (void)styleNavigationBar
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithHexValue:BCM_BLUE]];
}

#pragma mark - Magical Record

// Magical Record

- (void)setupDB
{
    // Magical Record setup
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:[self dbStore]];
}

- (NSString *)dbStore
{
    NSString *bundleID = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
    return [NSString stringWithFormat:@"%@.sqlite", bundleID];
}

#pragma mark - Configuration

- (void)updateCurrencies
{
    if (!self.networking) {
        self.networking = [[BCMNetworking alloc] init];
    }
    
    [self.networking retrieveBitcoinCurrenciesSuccess:^(NSURLRequest *request, NSDictionary *dict) {
        for (NSString *currency in [dict allKeys]) {
            NSDictionary *currencyDict = [dict objectForKey:currency];
            NSString *currencySymbol = [currencyDict objectForKey:@"symbol"];
            [[NSUserDefaults standardUserDefaults] setObject:currencySymbol forKey:[NSString stringWithFormat:@"%@_symbol", currency]];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    } error:^(NSURLRequest *request, NSError *error) {
        NSLog(@"ERROR");
    }];
}

#pragma mark - PinEntry

- (void)pinEntrySuccessful:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kBCMPinEntryCompletedSuccessfulNotification object:nil];
    [self.drawerController dismissViewControllerAnimated:YES completion:nil];
}

@end
