@protocol APTokenFieldDataSource;
@protocol APTokenFieldDelegate;

#define TOKEN_HZ_PADDING 8.5
#define TOKEN_VT_PADDING 2.5

@interface APTokenField : UIControl <UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate>

@property (nonatomic) NSUInteger tokensLimit;
@property (nonatomic, strong) NSMutableArray *tokens;

@property (nonatomic, readonly) UITableView *resultsTable;
@property (nonatomic) NSUInteger numberOfResults;

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, weak, readonly) NSString *text;

@property (nonatomic, strong) UIView *rightView;

@property (nonatomic, weak) id<APTokenFieldDataSource> tokenFieldDataSource;
@property (nonatomic, weak) id<APTokenFieldDelegate> tokenFieldDelegate;

- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (NSUInteger)objectCount;
- (id)objectAtIndex:(NSUInteger)index;

@end
