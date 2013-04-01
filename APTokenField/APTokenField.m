#import "APTokenField.h"
#import <QuartzCore/QuartzCore.h>

#import "APTokenView.h"
#import "APShadowView.h"

#import "APTokenFieldDataSource.h"
#import "APTokenFieldDelegate.h"

static NSString *const kHiddenCharacter = @"\u200B";

@implementation UITextField (PreventCopy)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([self.text isEqualToString:kHiddenCharacter]) {
        return (action == @selector(paste:)) ? YES : NO;
    } else {
        return [super canPerformAction:action withSender:sender];
    }
}

@end

NSString *const APTokenFieldFrameDidChangeNotification = @"APTokenFieldFrameDidChangeNotification";
NSString *const APTokenFieldNewFrameUserInfoKey        = @"APTokenFieldNewFrameUserInfoKey";
NSString *const APTokenFieldOldFrameUserInfoKey        = @"APTokenFieldOldFrameUserInfoKey";

@interface APTokenField ()

@property (nonatomic, strong) APShadowView *shadowView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *tokenContainer;
@property (nonatomic, strong) UIView *solidLine;
@property (nonatomic, strong) NSDictionary *tokenColors;

@property (nonatomic, readwrite) UITableView *resultsTable;

typedef BOOL (^TokenTestBlock)(APTokenView *token);

@end

@implementation APTokenField

- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame])
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor whiteColor];
        
        self.numberOfResults = 0;
        self.allowDuplicates = YES;
        self.tokensLimit = NSUIntegerMax;
        self.font = [UIFont systemFontOfSize:14];
        self.tokens = [[NSMutableArray alloc] init];
        
        [self addSubview:self.tokenContainer];
        [self.tokenContainer addSubview:self.textField];
        [self addSubview:self.solidLine];
        [self addSubview:self.resultsTable];
        [self addSubview:self.shadowView];
        
        [self registerForKeyboardNotifications];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame populateWithObjects:(NSArray *)initialObjects forKey:(NSString *)key {
    
    if (self = [super initWithFrame:frame])
    {
        [initialObjects enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            [self addTokenSilently:[APTokenView tokenWithTitle:[object valueForKey:key] object:object colors:nil]];
        }];
    }
    
    return self;
}

#pragma mark - View Hierarchy

- (UILabel *)label
{
    if (!_label)
    {
        _label = [[UILabel alloc] init];
        
        // the label's font is 15% bigger than the token font
        _label.font = [UIFont systemFontOfSize:_font.pointSize*1.15];
        _label.textColor = [UIColor grayColor];
        _label.backgroundColor = [UIColor clearColor];
    }
    
    return _label;
}
- (UITextField *)textField
{
    if (!_textField)
    {
        _textField = [[UITextField alloc] init];
        
        _textField.text = kHiddenCharacter;
        _textField.delegate = self;
        _textField.font = _font;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.returnKeyType = UIReturnKeyDone;
        
        if ([UITextField respondsToSelector:@selector(setSpellCheckingType:)])
            _textField.spellCheckingType = UITextSpellCheckingTypeNo;
    }
    
    return _textField;
}
- (UIView *)tokenContainer
{
    if (!_tokenContainer)
    {
        _tokenContainer = [[UIView alloc] init];
        
        _tokenContainer.backgroundColor = [UIColor clearColor];
        [_tokenContainer addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedTokenContainer)]];
    }
    
    return _tokenContainer;
}
- (UIView *)solidLine
{
    if (!_solidLine)
    {
        _solidLine = [[UIView alloc] initWithFrame:CGRectZero];
        _solidLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    }
    
    return _solidLine;
}
- (APShadowView *)shadowView
{
    if (!_shadowView)
    {
        _shadowView = [[APShadowView alloc] init];
    }
    
    return _shadowView;
}
- (UITableView *)resultsTable
{
    if (!_resultsTable)
    {
        _resultsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _resultsTable.dataSource = self;
        _resultsTable.delegate = self;
        _resultsTable.backgroundColor = [UIColor colorWithWhite:0.93f alpha:1.0f];
    }
    
    return _resultsTable;
}

#pragma mark - Adding & removing tokens

- (void)addToken:(APTokenView *)token {
    
    NSString *trimmedTokenTitle = [token.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Clear text field and return if token title is whitespace only
    if (!trimmedTokenTitle.length)
    {
        NSLog(@"WARNING: Token title was empty!");
        [self clearTextField];
        return;
    }
    
    // Flash duplicate and return if duplicates are not allowed and token is duplicate
    if (!self.allowDuplicates)
    {
        APTokenView *tokenWithSameTitle = [self tokenWithTitle:trimmedTokenTitle];
        
        if (tokenWithSameTitle)
        {
            NSLog(@"WARNING: Token was duplicate!");
            [self flashToken:tokenWithSameTitle];
            return;
        }
    }
    
    // Configure the token
    token.title = trimmedTokenTitle;
    token.tokenField = self;
    [token addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedToken:)]];
    
    // Return if delegate does not want to add this token
    if ([self.tokenFieldDelegate respondsToSelector:@selector(tokenField:shouldAddToken:)])
        if (![self.tokenFieldDelegate tokenField:self shouldAddToken:token])
            return;
    
    [self.tokens addObject:token];
    [self.tokenContainer addSubview:token];
    
    [self clearTextField];
    
    if ([self.tokenFieldDelegate respondsToSelector:@selector(tokenField:didAddToken:)])
        [self.tokenFieldDelegate tokenField:self didAddToken:token];
}

- (void)removeToken:(APTokenView *)token {
    
    // Return if delegate does not want to remove this token
    if ([self.tokenFieldDelegate respondsToSelector:@selector(tokenField:shouldRemoveToken:)])
        if (![self.tokenFieldDelegate tokenField:self shouldRemoveToken:token])
            return;
    
    [token removeFromSuperview];
    [self.tokens removeObject:token];;
    
    [self clearTextField];
    
    if ([self.tokenFieldDelegate respondsToSelector:@selector(tokenField:didRemoveToken:)])
        [self.tokenFieldDelegate tokenField:self didRemoveToken:token];
}


- (void)addTokenWithObject:(id)object {
    if (object == nil)
        [NSException raise:NSInvalidArgumentException format:@"You can't add a nil object to an APTokenField."];
    
    NSString *title = [_tokenFieldDataSource tokenField:self titleForObject:object];;
    if (title == nil) // if we don't have a title for it, we'll use the Obj-c name
        title = [NSString stringWithFormat:@"%@", object];
    
    APTokenView *token = [APTokenView tokenWithTitle:title object:object colors:_tokenColors];
    
    [self addToken:token];
}

- (void)addTokenSilently:(APTokenView *)token {
    
    NSString *trimmedTokenTitle = [token.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Return if token title is whitespace only
    if (!trimmedTokenTitle.length)
    {
        NSLog(@"WARNING: Token title was empty!");
        return;
    }
    
    // Return if duplicates are not allowed and token is duplicate
    if (!self.allowDuplicates)
    {
        APTokenView *tokenWithSameTitle = [self tokenWithTitle:trimmedTokenTitle];
        
        if (tokenWithSameTitle)
        {
            NSLog(@"WARNING: Token was duplicate!");
            return;
        }
    }
    
    // Configure the token
    token.title = trimmedTokenTitle;
    token.tokenField = self;
    [token addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedToken:)]];
    
    [self.tokens addObject:token];
    [self.tokenContainer addSubview:token];
}

- (void)mapToArray:(NSArray *)array withKey:(NSString *)key {
    [self.tokens makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.tokens removeAllObjects];
    
    [array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        [self addTokenSilently:[APTokenView tokenWithTitle:[object valueForKey:key] object:object colors:nil]];
    }];
    
    [self clearTextField];
}

- (void)clear {
    [self.tokens makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.tokens removeAllObjects];
    
    [self clearTextField];
    
    if ([self.tokenFieldDelegate respondsToSelector:@selector(tokenFieldDidClear:)])
        [self.tokenFieldDelegate tokenFieldDidClear:self];
}

#pragma mark - Finding tokens

- (NSArray *)tokensPassingTest:(TokenTestBlock)test stopAfterFirstMatch:(BOOL)stopAfterFirstMatch {
    __block NSMutableArray *tokensPassingTest = [NSMutableArray arrayWithCapacity:_tokens.count];
    
	[_tokens enumerateObjectsUsingBlock:^(APTokenView *token, NSUInteger idx, BOOL *stop)
     {
         if (test(token))
         {
             [tokensPassingTest addObject:token];
             
             if (stopAfterFirstMatch)
                 *stop = YES;
         }
     }];
    
    return [tokensPassingTest copy];
}

- (APTokenView *)firstTokenPassingTest:(TokenTestBlock)test {
    NSArray *tokensPassingTest = [self tokensPassingTest:test stopAfterFirstMatch:YES];
    return tokensPassingTest.count ? tokensPassingTest[0] : nil;
}

- (APTokenView *)tokenWithObject:(id)object {
    return [self firstTokenPassingTest:^BOOL(APTokenView *token) {
        return [token.object isEqual:object];
    }];
}

- (APTokenView *)tokenWithTitle:(NSString *)title {
    return [self firstTokenPassingTest:^BOOL(APTokenView *token) {
        return [token.title isEqualToString:title];
    }];
}

- (APTokenView *)selectedToken {
    return [self firstTokenPassingTest:^BOOL(APTokenView *token) {
        return token.highlighted;
    }];
}

- (NSArray *)selectedTokens {
    return [self tokensPassingTest:^BOOL(APTokenView *token) {
        return token.highlighted;
    } stopAfterFirstMatch:NO];
}

#pragma mark - Manipulating tokens

- (void)flashToken:(APTokenView *)token {
    [UIView transitionWithView:token
                      duration:0.20
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        
                        token.highlighted = YES;
                    }
                    completion:^(BOOL finished){
                        
                        [UIView transitionWithView:token
                                          duration:0.20
                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                        animations:^{
                                            
                                            token.highlighted = NO;
                                        }
                                        completion:nil];
                    }];
}

- (void)selectToken:(APTokenView *)token {
    [self unselectAllTokens];
    
    if (!_textField.hidden)
        _textField.hidden = YES; // Hide the caret of textField
    
    if (!self.isFirstResponder)
        [self becomeFirstResponder];
    
    token.highlighted = YES;
}

- (void)unselectAllTokens {
    [[self selectedTokens] enumerateObjectsUsingBlock:^(APTokenView *token, NSUInteger index, BOOL *stop) {
        token.highlighted = NO;
    }];
}

- (void)activateTextField {
    [self unselectAllTokens];
    
    if (_textField.hidden)
        _textField.hidden = NO;
    
    if (!self.isFirstResponder)
        [self becomeFirstResponder];
}

- (void)clearTextField {
    self.text = @"";
    [self.tokenFieldDataSource tokenField:self searchQuery:@""];
    [self.resultsTable reloadData];
    [self setNeedsLayout];
}

#define CONTAINER_PADDING      8
#define MINIMUM_TEXTFIELD_WIDTH   40
#define CONTAINER_ELEMENT_VT_MARGIN 8
#define CONTAINER_ELEMENT_HZ_MARGIN 8

- (void)layoutSubviews {
    CGRect bounds = self.bounds;
    
    // calculate the starting x (containerWidth) and y (containerHeight) for our layout
    float containerWidth = 0;
    if (_label != nil)   // we adjust the starting y in case the user specified labelText
    {
        [_label sizeToFit];
        CGRect labelBounds = _label.bounds;
        // we want the base of the label text to be the same as the token label base
        _label.frame = CGRectMake(CONTAINER_PADDING,
                                  /* the +2 is because [label sizeToFit] isn't a tight fit (2 pixels of gap) */
                                  CONTAINER_ELEMENT_VT_MARGIN+TOKEN_VT_PADDING+_font.lineHeight-_label.font.lineHeight+2,
                                  labelBounds.size.width,
                                  labelBounds.size.height);
        containerWidth = CGRectGetMaxX(_label.frame)+CONTAINER_PADDING;
    }
    else
        containerWidth = CONTAINER_PADDING;
    float containerHeight = CONTAINER_ELEMENT_VT_MARGIN;
    APTokenView *lastToken = nil;
    float rightViewWidth = 0;
    if (_rightView)
        rightViewWidth = _rightView.bounds.size.width+CONTAINER_ELEMENT_HZ_MARGIN;
    // layout each of the tokens
    for (APTokenView *token in _tokens)
    {
        CGSize desiredTokenSize = [token desiredSize];
        if (containerWidth + desiredTokenSize.width > bounds.size.width-CONTAINER_PADDING-rightViewWidth)
        {
            containerHeight += desiredTokenSize.height + CONTAINER_ELEMENT_VT_MARGIN;
            containerWidth = CONTAINER_PADDING;
        }
        
        token.frame = CGRectMake(containerWidth, containerHeight, desiredTokenSize.width, desiredTokenSize.height);
        containerWidth += desiredTokenSize.width + CONTAINER_ELEMENT_HZ_MARGIN;
        
        lastToken = token;
    }
    
    // let's place the textfield now
    if (containerWidth + MINIMUM_TEXTFIELD_WIDTH > bounds.size.width-CONTAINER_PADDING-rightViewWidth)
    {
        containerHeight += lastToken.bounds.size.height+CONTAINER_ELEMENT_VT_MARGIN;
        containerWidth = CONTAINER_PADDING;
    }
    _textField.frame = CGRectMake(containerWidth, containerHeight+TOKEN_VT_PADDING, CGRectGetMaxX(bounds)-CONTAINER_PADDING-containerWidth, _font.lineHeight);
    
    // now that we know the size of all the tokens, we can set the frame for our container
    // if there are some results, then we'll only show the last row of the container, otherwise, we'll show all of it
    float minContainerHeight = _font.lineHeight+TOKEN_VT_PADDING*2.0+2+CONTAINER_ELEMENT_VT_MARGIN*2.0;
    float tokenContainerWidth = bounds.size.width;
    
    if (_rightView)
        tokenContainerWidth -= 5 + _rightView.bounds.size.width + 5;
    
    _tokenContainer.frame = CGRectMake(0,
                                       (_numberOfResults == 0) ? 0 : -containerHeight+CONTAINER_ELEMENT_VT_MARGIN,
                                       tokenContainerWidth,
                                       MAX(minContainerHeight, containerHeight+lastToken.bounds.size.height+CONTAINER_ELEMENT_VT_MARGIN));
    
    /* If there's a rightView, place it at the bottom right of the tokenContainer.
     We made sure to provide enough space for it in the logic above, so it should fit just right. */
    _rightView.center = CGPointMake(bounds.size.width - CONTAINER_PADDING/2.0 - _rightView.bounds.size.width/2.0,
                                    CGRectGetMaxY(_tokenContainer.frame)-5-_rightView.bounds.size.height/2.0);
    
    // the solid line should be 1 pt at the bottom of the token container
    _solidLine.frame = CGRectMake(0,
                                  CGRectGetMaxY(_tokenContainer.frame)-1,
                                  bounds.size.width,
                                  1);
    
    // the shadow view always goes below the token container
    _shadowView.frame = CGRectMake(0,
                                   CGRectGetMaxY(_tokenContainer.frame),
                                   bounds.size.width,
                                   10);
    
    // the table view always goes below the token container and fills up the rest of the view
    _resultsTable.frame = CGRectMake(0,
                                     CGRectGetMaxY(_tokenContainer.frame),
                                     bounds.size.width,
                                     CGRectGetMaxY(self.superview.bounds)-CGRectGetMaxY(_tokenContainer.frame));
    
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            bounds.size.width,
                            CGRectGetMaxY(_tokenContainer.frame));
}

#pragma mark - Interaction

- (void)userTappedBackspaceOnEmptyField {
    if (!self.enabled)
        return;
    
    // check if there are any highlighted tokens. If so, delete it and reveal the textfield again
    if ([self selectedToken])
    {
        [self removeToken:[self selectedToken]];
        [self activateTextField];
    }
    // there was no highlighted token, so highlight the last token in the list
    else if ([_tokens count] > 0) // if there are any tokens in the list
    {
        [self selectToken:[_tokens lastObject]];
    }
}

- (void)userTappedTokenContainer {
    if (!self.enabled)
        return;
    
    [self activateTextField];
}

- (void)userTappedToken:(UITapGestureRecognizer*)gestureRecognizer {
    if (!self.enabled)
        return;
    
    _textField.enabled = YES;
    APTokenView *token = (APTokenView*)gestureRecognizer.view;
    
    [self selectToken:token];
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:didTapToken:)])
        [_tokenFieldDelegate tokenField:self didTapToken:token];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    /*
     self.frame corresponds to tokenContainer. Touches outside of tokenContainer will not be forwarded to APTokenField. The resultsTable extends beyond/outside self.frame, to cover the part of the screen which is below tokenContainer. Without this method, resultsTable would not recieve touches which are intended for it.
     */
    
    BOOL pointInside = NO;
    
    if ((CGRectContainsPoint(_resultsTable.frame, point) && !_resultsTable.hidden) ||
        CGRectContainsPoint(self.frame, point))
        pointInside = YES;
    
    return pointInside;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([_tokenFieldDataSource respondsToSelector:@selector(tokenField:tableView:cellForIndex:)])
    {
        return [_tokenFieldDataSource tokenField:self
                                       tableView:aTableView
                                    cellForIndex:indexPath.row];
    }
    else
    {
        static NSString *CellIdentifier = @"CellIdentifier";
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        id object = [_tokenFieldDataSource tokenField:self objectAtResultsIndex:indexPath.row];
        cell.textLabel.text = [_tokenFieldDataSource tokenField:self titleForObject:object];
        return cell;
    }
}

- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section {
    _numberOfResults = 0;
    
    _numberOfResults = [_tokenFieldDataSource numberOfResultsInTokenField:self];
    
    _resultsTable.hidden = (_numberOfResults == 0);
    _shadowView.hidden = (_numberOfResults == 0);
    _solidLine.hidden = (_numberOfResults != 0);
    
    return _numberOfResults;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)aTableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // get the object for that result row
    id object = [_tokenFieldDataSource tokenField:self objectAtResultsIndex:indexPath.row];
    [self addTokenWithObject:object];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_tokenFieldDataSource respondsToSelector:@selector(resultRowsHeightForTokenField:)])
        return [_tokenFieldDataSource resultRowsHeightForTokenField:self];
    
    return 44;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField*)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if (!self.enabled)
        return NO;
    
    BOOL changeIsBackspace = ([string isEqualToString:@""] || string.length == 0);
    BOOL textFieldIsEmpty = ([aTextField.text isEqualToString:kHiddenCharacter] ||
                             [[aTextField.text substringWithRange:range] isEqualToString:kHiddenCharacter] ||
                             NSEqualRanges(range, NSMakeRange(0, 0)));
    
    if (textFieldIsEmpty && changeIsBackspace)
    {
        [self userTappedBackspaceOnEmptyField];
        return NO;
    }
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:shouldChangeCharactersInRange:replacementString:)])
    {
        BOOL shouldChange = [_tokenFieldDelegate tokenField:self
                              shouldChangeCharactersInRange:range
                                          replacementString:string];
        if (!shouldChange)
            return NO;
    }
    
    /* If the textfield is hidden, it means that a token is highlighted. And if the user
     entered a character, then we need to delete that token and begin a new search. */
    if (_textField.hidden)
    {
        if ([self selectedToken])
        {
            // find the highlighted token, remove it, then make the textfield visible again
            [self removeToken:[self selectedToken]];
            [self activateTextField];
        }
    }
    
    NSString *newString = nil;
    BOOL newQuery = NO;
    if ([_textField.text isEqualToString:kHiddenCharacter]) {
        newString = string;
        _textField.text = newString;
        newQuery = YES;
    }
    else
        newString = [_textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [_tokenFieldDataSource tokenField:self searchQuery:newString];
    [_resultsTable reloadData];
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutSubviews];
    }];
    
    if ([newString length] == 0) {
        aTextField.text = kHiddenCharacter;
        return NO;
    }
    
    if (newQuery)
        return NO;
    else
        return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)aTextField {
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenFieldDidBeginEditing:)]) {
        [_tokenFieldDelegate tokenFieldDidBeginEditing:self];
    }
    
    if ([_textField.text length] == 0)
        _textField.text = kHiddenCharacter;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([_tokens count] >= _tokensLimit) {
        _textField.enabled = NO;
    }
    
    [self unselectAllTokens];
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenFieldDidEndEditing:)])
        [_tokenFieldDelegate tokenFieldDidEndEditing:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (!self.enabled)
        return NO;
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenFieldDidReturn:)])
        [_tokenFieldDelegate tokenFieldDidReturn:self];
    
    return YES;
}

#pragma mark - Accessors

- (void)setTokenFieldDataSource:(id<APTokenFieldDataSource>)aTokenFieldDataSource {
    if (_tokenFieldDataSource == aTokenFieldDataSource)
        return;
    
    _tokenFieldDataSource = aTokenFieldDataSource;
    [_resultsTable reloadData];
}

- (void)setFrame:(CGRect)frame {
    CGRect oldFrame = self.frame;
    
    [super setFrame:frame];
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    
    userInfo[APTokenFieldNewFrameUserInfoKey] = [NSValue valueWithCGRect:frame];
    userInfo[APTokenFieldOldFrameUserInfoKey] = [NSValue valueWithCGRect:oldFrame];
	
	if (CGRectEqualToRect(oldFrame, frame) == NO)
		[[NSNotificationCenter defaultCenter] postNotificationName:APTokenFieldFrameDidChangeNotification object:self userInfo:userInfo.copy];
}

- (void)setFont:(UIFont*)aFont {
    if (_font == aFont)
        return;
    
    _font = aFont;
    
    _textField.font = _font;
}

- (void)setLabelText:(NSString *)someText {
    if ([_labelText isEqualToString:someText])
        return;
    
    _labelText = someText;
    
    // remove the current label
    [_label removeFromSuperview];
    _label = nil;
    
    // if there is some new text, then create and add a new label
    if ([_labelText length] != 0)
    {
        self.label.text = _labelText;
        [self.tokenContainer addSubview:self.label];
    }
    
    [self setNeedsLayout];
}

- (void)setRightView:(UIView *)aView {
    if (aView == _rightView)
        return;
    
    [_rightView removeFromSuperview];
    _rightView = nil;
    
    if (aView)
    {
        _rightView = aView;
        [self addSubview:_rightView];
    }
    
    [self setNeedsLayout];
}

- (NSString*)text {
    if ([_textField.text isEqualToString:kHiddenCharacter])
        return @"";
    
    return _textField.text;
}

- (void)setText:(NSString *)text
{
    // Ensure the kHiddenCharacter is always at the beginning
    
	if (![text hasPrefix:kHiddenCharacter])
	{
        NSMutableString *prefixedText = text.mutableCopy;
		[prefixedText insertString:kHiddenCharacter atIndex:0];
		_textField.text = prefixedText;
	}
    else
    {
        _textField.text = text;
    }
}

@end


@implementation APTokenField (KeyboardAvoiding)

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardDidShow:(NSNotification *)aNotification {
    CGSize keyboardSize = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSNumber *animationDuration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    
    [UIView animateWithDuration:animationDuration.doubleValue animations:^{
        _resultsTable.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
        _resultsTable.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
    }];
}

- (void)keyboardDidHide:(NSNotification *)aNotification {
    NSNumber *animationDuration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    [UIView animateWithDuration:animationDuration.doubleValue animations:^{
        _resultsTable.contentInset = UIEdgeInsetsZero;
        _resultsTable.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

@end


@implementation APTokenField (UIResponderOverrides)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return [_textField becomeFirstResponder];
}

- (BOOL)isFirstResponder {
    return [_textField isFirstResponder];
}

- (BOOL)canResignFirstResponder {
    return [_textField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [_textField resignFirstResponder];
}

@end
