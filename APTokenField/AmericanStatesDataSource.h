#import "APTokenFieldDataSource.h"

@interface AmericanStatesDataSource : NSObject <APTokenFieldDataSource>

@property (strong, nonatomic) NSMutableArray *states;
@property (strong, nonatomic) NSMutableArray *results;

@end
