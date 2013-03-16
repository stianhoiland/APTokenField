#import "APTokenFieldDelegate.h"

@class APTokenField;
@class AmericanStatesDataSource;

@interface APTokenFieldController : UIViewController <APTokenFieldDelegate>

@property (strong, nonatomic) APTokenField *tokenField;
@property (strong, nonatomic) UIView *containerView;
@property (strong, nonatomic) AmericanStatesDataSource *statesDataSource;

@end
