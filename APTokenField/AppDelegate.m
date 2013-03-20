#import "AppDelegate.h"
#import "APTokenFieldController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[APTokenFieldController alloc] init]];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
