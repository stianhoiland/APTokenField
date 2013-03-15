#import "APTokenFieldDataSource.h"
#import <Foundation/Foundation.h>

@interface AmericanStatesDataSource : NSObject <APTokenFieldDataSource> {
    NSMutableArray *states;
    NSMutableArray *results;
}

@end
