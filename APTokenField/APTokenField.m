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


@interface APTokenField ()

@property (nonatomic, strong) APShadowView *shadowView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *tokenContainer;
@property (nonatomic, strong) UIView *backingView;
@property (nonatomic, strong) UIView *solidLine;
@property (nonatomic, strong) NSDictionary *tokenColors;

typedef BOOL (^TokenTestBlock)(APTokenView *token);

@end

@implementation APTokenField

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _backingView = [[UIView alloc] initWithFrame:CGRectZero];
        _backingView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_backingView];
        
        _numberOfResults = 0;
        _allowDuplicates = YES;
        self.font = [UIFont systemFontOfSize:14];
        
        _tokenContainer = [[UIView alloc] initWithFrame:CGRectZero];
        _tokenContainer.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedTokenContainer)];
        [_tokenContainer addGestureRecognizer:tapGesture];
        [self addSubview:_tokenContainer];
        
        _resultsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _resultsTable.dataSource = self;
        _resultsTable.delegate = self;
        _resultsTable.backgroundColor = [UIColor colorWithWhite:0.93f alpha:1.0f];
        [self addSubview:_resultsTable];
        
        self.shadowView = [[APShadowView alloc] initWithFrame:CGRectZero];
        [self addSubview:_shadowView];
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.text = kHiddenCharacter;
        _textField.delegate = self;
        _textField.font = _font;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.returnKeyType = UIReturnKeyDone;
        if ([UITextField respondsToSelector:@selector(setSpellCheckingType:)])
            _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        [_tokenContainer addSubview:_textField];
        
        self.tokens = [[NSMutableArray alloc] init];
        
        _solidLine = [[UIView alloc] initWithFrame:CGRectZero];
        _solidLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
        [self addSubview:_solidLine];
    }
    
    return self;
}

#pragma mark - Adding & removing tokens

- (void)addToken:(APTokenView *)token {
    if (!self.allowDuplicates)
    {
        APTokenView *tokenWithSameTitle = [self tokenWithTitle:token.title];
        if (tokenWithSameTitle)
        {
            [self flashToken:tokenWithSameTitle];
            return;
        }
    }

    token.tokenField = self;
    
    [token addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedToken:)]];

    [_tokens addObject:token];
    [_tokenContainer addSubview:token];
    
    [_tokenFieldDataSource tokenField:self searchQuery:@""];
    _textField.text = kHiddenCharacter;
    
    [self setNeedsLayout];
    
    [_resultsTable reloadData];
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:didAddToken:)])
        [_tokenFieldDelegate tokenField:self didAddToken:token];
}

- (void)removeToken:(APTokenView *)token {
    [token removeFromSuperview];
    [_tokens removeObject:token];;
    [self setNeedsLayout];
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:didRemoveToken:)])
        [_tokenFieldDelegate tokenField:self didRemoveToken:token];
}


- (void)addTokenWithObject:(id)object {
    if (object == nil)
        [NSException raise:@"IllegalArgumentException" format:@"You can't add a nil object to an APTokenField"];
    
    NSString *title = [_tokenFieldDataSource tokenField:self titleForObject:object];;
    if (title == nil) // if we don't have a title for it, we'll use the Obj-c name
        title = [NSString stringWithFormat:@"%@", object];
    
    APTokenView *token = [APTokenView tokenWithTitle:title object:object colors:_tokenColors];
    
    [self addToken:token];
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
    token.highlighted = YES;
    
    if (!_textField.isFirstResponder)
        [_textField becomeFirstResponder];
    
    _textField.hidden = YES;
}

- (void)unselectAllTokens {
    [[self selectedTokens] enumerateObjectsUsingBlock:^(APTokenView *token, NSUInteger index, BOOL *stop) {
        token.highlighted = NO;
    }];
}

#pragma mark - UIResponder

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
    float tokenContainerWidth = 0;
    if (_rightView)
        tokenContainerWidth = bounds.size.width-5-_rightView.bounds.size.width-5;
    else
        tokenContainerWidth = bounds.size.width;
    if (_numberOfResults == 0)
        _tokenContainer.frame = CGRectMake(0, 0, tokenContainerWidth, MAX(minContainerHeight, containerHeight+lastToken.bounds.size.height+CONTAINER_ELEMENT_VT_MARGIN));
    else
        _tokenContainer.frame = CGRectMake(0, -containerHeight+CONTAINER_ELEMENT_VT_MARGIN, tokenContainerWidth, MAX(minContainerHeight, containerHeight+lastToken.bounds.size.height+CONTAINER_ELEMENT_VT_MARGIN));
    
    // layout the backing view
    _backingView.frame = CGRectMake(_tokenContainer.frame.origin.x,
                                    _tokenContainer.frame.origin.y,
                                    bounds.size.width,
                                    _tokenContainer.frame.size.height);
    
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
                                     CGRectGetMaxY(bounds)-CGRectGetMaxY(_tokenContainer.frame));
}

#pragma mark - Interaction

- (void)userTappedBackspaceOnEmptyField {
    if (!self.enabled)
        return;

    // check if there are any highlighted tokens. If so, delete it and reveal the textfield again
    if ([self selectedToken])
    {
        [self removeToken:[self selectedToken]];
        _textField.hidden = NO;
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
    
    if (![self isFirstResponder])
        [self becomeFirstResponder];
    
    if (_textField.hidden)
        _textField.hidden = NO;
    
    [self unselectAllTokens];
}

- (void)userTappedToken:(UITapGestureRecognizer*)gestureRecognizer {
    if (!self.enabled)
        return;
    
    _textField.enabled = YES;
    APTokenView *token = (APTokenView*)gestureRecognizer.view;
    
    [self unselectAllTokens];
    [self selectToken:token];
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:didTapToken:)])
        [_tokenFieldDelegate tokenField:self didTapToken:token];
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
    
    if ([aTextField.text isEqualToString:kHiddenCharacter] && [string length] == 0) {
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
            _textField.hidden = NO;
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
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        // the label's font is 15% bigger than the token font
        _label.font = [UIFont systemFontOfSize:_font.pointSize*1.15];
        _label.text = _labelText;
        _label.textColor = [UIColor grayColor];
        _label.backgroundColor = [UIColor clearColor];
        [_tokenContainer addSubview:_label];
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

@end
