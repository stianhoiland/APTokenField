#import "APTokenFieldController.h"

#import "APTokenField.h"
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

@end
