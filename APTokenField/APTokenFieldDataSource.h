#import <Foundation/Foundation.h>

@class APTokenField;

@protocol APTokenFieldDataSource <NSObject>

@required
- (NSString *)tokenField:(APTokenField *)tokenField titleForObject:(id)anObject;
- (NSUInteger)numberOfResultsInTokenField:(APTokenField *)tokenField;
- (id)tokenField:(APTokenField *)tokenField objectAtResultsIndex:(NSUInteger)index;
- (void)tokenField:(APTokenField *)tokenField searchQuery:(NSString*)query;

@optional
/* If you don't implement this method, then the results table will use
 UITableViewCellStyleDefault with the value provided by
 tokenField:titleForObject: as the textLabel of the UITableViewCell. */
- (UITableViewCell *)tokenField:(APTokenField *)tokenField tableView:(UITableView *)tableView cellForIndex:(NSUInteger)index;
- (CGFloat)resultRowsHeightForTokenField:(APTokenField *)tokenField;

@end
