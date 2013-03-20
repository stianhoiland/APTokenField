@class APTokenField;
@class APTokenView;

@protocol APTokenFieldDelegate <NSObject>

@optional

- (void)tokenField:(APTokenField *)tokenField didAddToken:(APTokenView *)token;
- (void)tokenField:(APTokenField *)tokenField didRemoveToken:(APTokenView *)token;

- (void)tokenFieldDidBeginEditing:(APTokenField *)tokenField;
- (void)tokenFieldDidEndEditing:(APTokenField *)tokenField;

- (void)tokenFieldDidReturn:(APTokenField *)tokenField;
- (void)tokenFieldDidClear:(APTokenField *)tokenField;
- (BOOL)tokenField:(APTokenField *)tokenField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

- (void)tokenField:(APTokenField *)tokenField didTapToken:(APTokenView *)token;
@end
