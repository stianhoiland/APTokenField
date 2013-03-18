@class APTokenField;
@class APTokenView;

@protocol APTokenFieldDelegate <NSObject>

@optional

- (void)tokenField:(APTokenField *)tokenField didAddToken:(APTokenView *)token;
- (void)tokenField:(APTokenField *)tokenField didRemoveToken:(APTokenView *)token;

- (void)tokenFieldDidBeginEditing:(APTokenField *)tokenField;
- (void)tokenFieldDidEndEditing:(APTokenField *)tokenField;

- (void)tokenFieldDidReturn:(APTokenField *)tokenField;
- (BOOL)tokenField:(APTokenField *)tokenField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end
