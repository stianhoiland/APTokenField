@protocol APTokenFieldDataSource;
@protocol APTokenFieldDelegate;
#import <UIKit/UIKit.h>

#define TOKEN_HZ_PADDING 8.5
#define TOKEN_VT_PADDING 2.5

@interface APTokenField : UIControl <UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate>
{
    NSUInteger numberOfResults;
}

@property (nonatomic, strong) NSDictionary *tokenColors;
@property (nonatomic) NSUInteger tokensLimit;
@property (nonatomic, strong) NSMutableArray *tokens;
@property (nonatomic, strong) UIView *backingView;
@property (nonatomic, strong) UIView *solidLine;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, readonly) UITableView *resultsTable;
@property (nonatomic, strong) UIView *rightView;
@property (weak, nonatomic, readonly) NSString *text;
@property (nonatomic, weak) id<APTokenFieldDataSource> tokenFieldDataSource;
@property (nonatomic, weak) id<APTokenFieldDelegate> tokenFieldDelegate;

- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (NSUInteger)objectCount;
- (id)objectAtIndex:(NSUInteger)index;

@end
