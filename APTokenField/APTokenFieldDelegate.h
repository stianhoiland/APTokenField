@class APTokenField;

@protocol APTokenFieldDelegate <NSObject>

@optional

- (void)tokenField:(APTokenField *)tokenField didAddObject:(id)object;
- (void)tokenField:(APTokenField *)tokenField didRemoveObject:(id)object;

- (void)tokenFieldDidBeginEditing:(APTokenField *)tokenField;
- (void)tokenFieldDidEndEditing:(APTokenField *)tokenField;

- (void)tokenFieldDidReturn:(APTokenField *)tokenField;
- (BOOL)tokenField:(APTokenField *)tokenField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end
