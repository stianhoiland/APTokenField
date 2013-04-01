@class APTokenView;
@protocol APTokenFieldDataSource;
@protocol APTokenFieldDelegate;

#define TOKEN_HZ_PADDING 8.5
#define TOKEN_VT_PADDING 2.5

extern NSString *const APTokenFieldFrameDidChangeNotification;
extern NSString *const APTokenFieldNewFrameUserInfoKey;
extern NSString *const APTokenFieldOldFrameUserInfoKey;

@interface APTokenField : UIControl <UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate>

- (id)initWithFrame:(CGRect)frame populateWithObjects:(NSArray *)initialObjects forKey:(NSString *)key;

@property (nonatomic) NSUInteger tokensLimit;
@property (nonatomic) BOOL allowDuplicates; // dis/allow tokens with identical title string. Default is YES
@property (nonatomic, strong) NSMutableArray *tokens;

- (APTokenView *)tokenWithObject:(id)object;       // returns first token with given object
- (APTokenView *)tokenWithTitle:(NSString *)title; // returns first token with given title
- (APTokenView *)selectedToken;

@property (nonatomic, readonly) UITableView *resultsTable;
@property (nonatomic) NSUInteger numberOfResults;

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, weak) NSString *text;

@property (nonatomic, strong) UIView *rightView;

@property (nonatomic, weak) id<APTokenFieldDataSource> tokenFieldDataSource;
@property (nonatomic, weak) id<APTokenFieldDelegate> tokenFieldDelegate;

- (void)addToken:(APTokenView *)token;
- (void)removeToken:(APTokenView *)token;
- (void)flashToken:(APTokenView *)token;

- (void)mapToArray:(NSArray *)array withKey:(NSString *)key;
- (void)clear;

@end

@interface APTokenField (KeyboardAvoiding)
- (void)registerForKeyboardNotifications;
@end
