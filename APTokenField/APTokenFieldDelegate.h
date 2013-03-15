#import <Foundation/Foundation.h>

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
