@class APTokenField;

@interface APTokenView : UIView

@property (nonatomic, strong) NSDictionary *colors;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, weak) APTokenField *tokenField;

+ (APTokenView*)tokenWithTitle:(NSString*)aTitle object:(id)anObject colors:(NSDictionary *)colors;
- (id)initWithTitle:(NSString*)aTitle object:(id)anObject colors:(NSDictionary *)colors;

- (CGSize)desiredSize;

@end
