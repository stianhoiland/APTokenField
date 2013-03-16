@class APTokenField;

@protocol APTokenFieldDataSource <NSObject>

@required
- (NSString *)tokenField:(APTokenField *)tokenField titleForObject:(id)anObject;
- (NSUInteger)numberOfResultsInTokenField:(APTokenField *)tokenField;
- (id)tokenField:(APTokenField *)tokenField objectAtResultsIndex:(NSUInteger)index;
- (void)tokenField:(APTokenField *)tokenField searchQuery:(NSString *)query;

@optional

/* If you don't implement this method, the cells in the results table
   will use UITableViewCellStyleDefault and the value provided by
   tokenField:titleForObject: for the textLabel. */

- (UITableViewCell *)tokenField:(APTokenField *)tokenField tableView:(UITableView *)tableView cellForIndex:(NSUInteger)index;
- (CGFloat)resultRowsHeightForTokenField:(APTokenField *)tokenField;

@end
