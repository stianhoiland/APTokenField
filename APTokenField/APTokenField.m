#import "APTokenField.h"
#import <QuartzCore/QuartzCore.h>

#import "APTokenView.h"
#import "APShadowView.h"

#import "APTokenFieldDataSource.h"
#import "APTokenFieldDelegate.h"

static NSString *const kHiddenCharacter = @"\u200B";

@interface APTextField : UITextField {}
@end

@implementation APTextField

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ([self.text isEqualToString:kHiddenCharacter]) {
        return (action == @selector(paste:)) ? YES : NO;
    } else {
        return [super canPerformAction:action withSender:sender];
    }
}

@end

@implementation APSolidLine

- (void)drawRect:(CGRect)rect
{
    CGFloat red = 204.0/255.0, green = 204.0/255.0, blue = 204.0/255.0, alpha = 1.0;
    
    if (_color != nil) {
        [_color getRed:&red green:&green blue:&blue alpha:&alpha];
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat lineColor[4] = {red, green, blue, alpha};
    CGContextSetFillColor(ctx, lineColor);
    CGContextFillRect(ctx, rect);
}

@end


@interface APTokenField ()

@property (nonatomic, strong) APShadowView *shadowView;
@property (nonatomic, strong) APTextField *textField;
@property (nonatomic, strong) UIView *tokenContainer;

@end

@implementation APTokenField

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _backingView = [[UIView alloc] initWithFrame:CGRectZero];
        _backingView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_backingView];
        
        numberOfResults = 0;
        self.font = [UIFont systemFontOfSize:14];
        
        _tokenContainer = [[UIView alloc] initWithFrame:CGRectZero];
        _tokenContainer.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedTokenContainer)];
        [_tokenContainer addGestureRecognizer:tapGesture];
        [self addSubview:_tokenContainer];
        
        _resultsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _resultsTable.dataSource = self;
        _resultsTable.delegate = self;
        [self addSubview:_resultsTable];
        
        self.shadowView = [[APShadowView alloc] initWithFrame:CGRectZero];
        [self addSubview:_shadowView];
        
        self.textField = [[APTextField alloc] initWithFrame:CGRectZero];
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
        
        _solidLine = [[APSolidLine alloc] initWithFrame:CGRectZero];
        [self addSubview:_solidLine];
    }
    
    return self;
}

- (void)addObject:(id)object {
    if (object == nil)
        [NSException raise:@"IllegalArgumentException" format:@"You can't add a nil object to an APTokenField"];
    
    NSString *title = nil;
    if (_tokenFieldDataSource != nil)
        title = [_tokenFieldDataSource tokenField:self titleForObject:object];
    
    // if we still don't have a title for it, we'll use the Obj-c name
    if (title == nil)
        title = [NSString stringWithFormat:@"%@", object];
    
    APTokenView *token = [APTokenView tokenWithTitle:title object:object colors:_tokenColors];
    token.tokenField = self;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedToken:)];
    [token addGestureRecognizer:tapGesture];
    [_tokens addObject:token];
    [_tokenContainer addSubview:token];
    
    [_tokenFieldDataSource tokenField:self searchQuery:@""];
    _textField.text = kHiddenCharacter;
    
    [self setNeedsLayout];
}

- (void)removeObject:(id)object {
    if (object == nil)
        return;
    
    for (int i=0; i<[_tokens count]; i++)
    {
        APTokenView *t = _tokens[i];
        if ([t.object  isEqual:object])
        {
            [t removeFromSuperview];
            [_tokens removeObjectAtIndex:i];
            [self setNeedsLayout];
            
            if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:didRemoveObject:)])
                [_tokenFieldDelegate tokenField:self didRemoveObject:object];
            
            return;
        }
    }
}

- (NSUInteger)objectCount {
    return [_tokens count];
}

- (id)objectAtIndex:(NSUInteger)index {
    APTokenView *t = _tokens[index];
    return t.object;
}

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
    if (label != nil)   // we adjust the starting y in case the user specified labelText
    {
        [label sizeToFit];
        CGRect labelBounds = label.bounds;
        // we want the base of the label text to be the same as the token label base
        label.frame = CGRectMake(CONTAINER_PADDING,
                                 /* the +2 is because [label sizeToFit] isn't a tight fit (2 pixels of gap) */
                                 CONTAINER_ELEMENT_VT_MARGIN+TOKEN_VT_PADDING+_font.lineHeight-label.font.lineHeight+2,
                                 labelBounds.size.width,
                                 labelBounds.size.height);
        containerWidth = CGRectGetMaxX(label.frame)+CONTAINER_PADDING;
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
    if (numberOfResults == 0)
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

- (void)userTappedBackspaceOnEmptyField {
    if (!self.enabled)
        return;
    
    // check if there are any highlighted tokens. If so, delete it and reveal the textfield again
    for (int i=0; i<[_tokens count]; i++)
    {
        APTokenView *t = _tokens[i];
        if (t.highlighted)
        {
            [self removeObject:t.object];
            _textField.hidden = NO;
            return;
        }
    }
    
    // there was no highlighted token, so highlight the last token in the list
    if ([_tokens count] > 0) // if there are any tokens in the list
    {
        APTokenView *t = [_tokens lastObject];
        t.highlighted = YES;
        _textField.hidden = YES;
        [t setNeedsDisplay];
    }
}

- (void)userTappedTokenContainer {
    if (!self.enabled)
        return;
    
    if (![self isFirstResponder])
        [self becomeFirstResponder];
    
    if (_textField.hidden)
        _textField.hidden = NO;
    
    // if there is a highlighted token, turn it off
    for (APTokenView *t in _tokens)
    {
        if (t.highlighted)
        {
            t.highlighted = NO;
            [t setNeedsDisplay];
            break;
        }
    }
}

- (void)userTappedToken:(UITapGestureRecognizer*)gestureRecognizer
{
    if (!self.enabled)
        return;
    
    _textField.enabled = YES;
    APTokenView *token = (APTokenView*)gestureRecognizer.view;
    
    // if any other token is highlighted, remove the highlight
    for (APTokenView *t in _tokens)
    {
        if (t.highlighted)
        {
            t.highlighted = NO;
            [t setNeedsDisplay];
            break;
        }
    }
    
    // now highlight the tapped token
    token.highlighted = YES;
    [token setNeedsDisplay];
    
    // make sure the textfield is hidden
    [_textField becomeFirstResponder];
    _textField.hidden = YES;
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
    numberOfResults = 0;
    if (_tokenFieldDataSource != nil)
        numberOfResults = [_tokenFieldDataSource numberOfResultsInTokenField:self];
    
    _resultsTable.hidden = (numberOfResults == 0);
    _shadowView.hidden = (numberOfResults == 0);
    _solidLine.hidden = (numberOfResults != 0);
    
    return numberOfResults;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)aTableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // get the object for that result row
    id object = [_tokenFieldDataSource tokenField:self objectAtResultsIndex:indexPath.row];
    [self addObject:object];
    
    [_resultsTable reloadData];
    
    if ([_tokenFieldDelegate respondsToSelector:@selector(tokenField:didAddObject:)])
        [_tokenFieldDelegate tokenField:self didAddObject:object];
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
        // find the highlighted token, remove it, then make the textfield visible again
        for (int i=0; i<[_tokens count]; i++)
        {
            APTokenView *t = _tokens[i];
            if (t.highlighted)
            {
                [self removeObject:t.object];
                break;
            }
        }
        _textField.hidden = NO;
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
    
    if (_tokenFieldDataSource != nil)
    {
        [_tokenFieldDataSource tokenField:self searchQuery:newString];
        [_resultsTable reloadData];
        [UIView animateWithDuration:0.3 animations:^{
            [self layoutSubviews];
        }];
    }
    
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
    if ([_tokens count] > 0) {
        for (APTokenView *t in _tokens) {
            t.highlighted = NO;
            [t setNeedsDisplay];
        }
    }
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
    [label removeFromSuperview];
    label = nil;
    
    // if there is some new text, then create and add a new label
    if ([_labelText length] != 0)
    {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        // the label's font is 15% bigger than the token font
        label.font = [UIFont systemFontOfSize:_font.pointSize*1.15];
        label.text = _labelText;
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        [_tokenContainer addSubview:label];
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
