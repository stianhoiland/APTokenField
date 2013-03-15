@protocol APTokenFieldDataSource;
@protocol APTokenFieldDelegate;
@class APShadowView;
#import <UIKit/UIKit.h>

@interface APSolidLine : UIView

@property (nonatomic) UIColor *color;

@end

@interface APTokenView : UIView

@end

@interface APTokenField : UIControl <UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate>
{
  UILabel *label;
  NSUInteger numberOfResults;
}

@property (nonatomic, strong) NSDictionary *tokenColors;
@property (nonatomic) NSUInteger tokensLimit;
@property (nonatomic, strong) NSMutableArray *tokens;
@property (nonatomic, strong) UIView *backingView;
@property (nonatomic) APSolidLine *solidLine;
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


@protocol APTokenFieldDelegate <NSObject>

@optional
/* Called when the user adds an object from the results list. */
- (void)tokenField:(APTokenField *)tokenField didAddObject:(id)object;
/* Called when the user deletes an object from the token field. */
- (void)tokenField:(APTokenField *)tokenField didRemoveObject:(id)object;
- (void)tokenFieldDidBeginEditing:(APTokenField *)tokenField;
- (void)tokenFieldDidEndEditing:(APTokenField *)tokenField;
/* Called when the user taps the 'enter'. */
- (void)tokenFieldDidReturn:(APTokenField *)tokenField;
- (BOOL)tokenField:(APTokenField *)tokenField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end