//
//  AppDelegate.m
//  Travelling Waves
//
//  Created by Govinda Ram Pingali on 10/27/18.
//  Copyright © 2018 Govinda Ram Pingali. All rights reserved.
//

#import "AppDelegate.h"
#import "TWHomeViewController.h"
#import "TWMasterController.h"
#import "TWTestViewController.h"

#define RUN_TEST                0

@interface AppDelegate ()
{
    UINavigationController*             _navController;
    TWHomeViewController*               _homeViewController;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Create and setup MasterController, which creates the AudioController
    [TWMasterController sharedController];
    
    // Setup View Controller
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    
    // Initialize Home View Controller and Setup Navigation Controller
#if RUN_TEST
    TWTestViewController* vc = [[TWTestViewController alloc] init];
    _navController = [[UINavigationController alloc] initWithRootViewController:vc];
#else
    _homeViewController = [[TWHomeViewController alloc] init];
    _navController = [[UINavigationController alloc] initWithRootViewController:_homeViewController];
#endif

    [self.window setRootViewController:_navController];
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
#if !RUN_TEST
    [_homeViewController willEnterBackground];
#endif
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
#if !RUN_TEST
    [_homeViewController willEnterForeground];
#endif
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end