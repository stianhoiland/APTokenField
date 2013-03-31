#import "APTokenFieldController.h"

#import "APTokenField.h"
#import "APTokenView.h"
#import "AmericanStatesDataSource.h"

@implementation APTokenFieldController

- (void)loadView
{
    self.view = self.tokenField;
    self.tokenField.backgroundColor = [UIColor whiteColor];
}

- (NSString *)title
{
    return @"APTokenField";
}

- (APTokenField *)tokenField
{
    if (!_tokenField)
    {
        _tokenField = [[APTokenField alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
        _tokenField.tokenFieldDataSource = self.statesDataSource;
        _tokenField.tokenFieldDelegate = self;
        _tokenField.allowDuplicates = NO;
        _tokenField.labelText = @"States:";
        _tokenField.rightView = [UIButton buttonWithType:UIButtonTypeContactAdd];
    }
    
    return _tokenField;
}

- (AmericanStatesDataSource *)statesDataSource
{
    if (!_statesDataSource)
    {
        _statesDataSource = [[AmericanStatesDataSource alloc] init];
    }
    
    return _statesDataSource;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - APTokenFieldDelegate

- (void)tokenField:(APTokenField *)tokenField didAddToken:(APTokenView *)token
{
    NSLog(@"%@", self.statesDataSource.states);
    NSLog(@"didAddToken %@", token);
}
- (void)tokenField:(APTokenField *)tokenField didRemoveToken:(APTokenView *)token
{
    NSLog(@"%@", self.statesDataSource.states);
    NSLog(@"didRemoveToken %@", token);
}
- (void)tokenField:(APTokenField *)tokenField didTapToken:(APTokenView *)token;
{
    NSLog(@"didTapToken %@", token);
}
- (void)tokenFieldDidBeginEditing:(APTokenField *)tokenField
{
    NSLog(@"tokenFieldDidBeginEditing %@", tokenField);
}
- (void)tokenFieldDidEndEditing:(APTokenField *)tokenField
{
    NSLog(@"tokenFieldDidEndEditing %@", tokenField);
    [self createNewObjectWithTitle:tokenField.text];
}
- (void)tokenFieldDidReturn:(APTokenField *)tokenField
{
    NSLog(@"tokenFieldDidReturn %@", tokenField);
    [self createNewObjectWithTitle:tokenField.text];
}
- (void)tokenFieldDidClear:(APTokenField *)tokenField
{
    NSLog(@"tokenFieldDidClear %@", tokenField);
}

- (void)createNewObjectWithTitle:(NSString *)title
{
    if ([[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length])
    {
        id newObject = title;
        [self.statesDataSource.states addObject:newObject];
        
        APTokenView *newToken = [APTokenView tokenWithTitle:title object:newObject colors:nil];
        [self.tokenField addToken:newToken];
    }
}

@end


@implementation APTokenFieldController (EditingExtenstion)

- (id)init
{
    if (self = [super init])
	{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
	
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)] animated:YES];
}
- (void)keyboardWillHide:(NSNotification *)notification
{
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

- (void)endEditing
{
    [self.view endEditing:YES];
}

@end
