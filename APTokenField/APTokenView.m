#import "APTokenView.h"
#import "APTokenField.h"

@implementation APTokenView

+ (APTokenView*)tokenWithTitle:(NSString*)aTitle object:(id)anObject colors:(NSDictionary *)colors
{
    return [[APTokenView alloc] initWithTitle:aTitle object:anObject colors:colors];
}

- (id)initWithTitle:(NSString*)aTitle object:(id)anObject colors:(NSDictionary *)colors
{
    if (self = [super initWithFrame:CGRectZero]) {
        _highlighted = NO;
        self.title = aTitle;
        self.backgroundColor = [UIColor clearColor];
        self.object = anObject;
        self.colors = colors;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGSize titleSize = [_title sizeWithFont:_tokenField.font];
    
    CGRect bounds = CGRectMake(0, 0, titleSize.width + TOKEN_HZ_PADDING*2.0, titleSize.height + TOKEN_VT_PADDING*2.0);
    CGRect textBounds = bounds;
    textBounds.origin.x = (bounds.size.width - titleSize.width) / 2;
    textBounds.origin.y += 4;
    
    CGFloat arcValue = (bounds.size.height / 2) + 1;
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGPoint endPoint = CGPointMake(1, self.bounds.size.height + 10);
    
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextAddArc(context, arcValue, arcValue, arcValue, (M_PI / 2), (3 * M_PI / 2), NO);
    CGContextAddArc(context, bounds.size.width - arcValue, arcValue, arcValue, 3 * M_PI / 2, M_PI / 2, NO);
    CGContextClosePath(context);
    
    if (_highlighted) {
        CGFloat red = 0.207, green = 0.369, blue = 1.0, alpha = 1.0;
        if ([_colors valueForKey:@"highlightedBorderColor"] != nil) {
            [[_colors valueForKey:@"highlightedBorderColor"] getRed:&red green:&green blue:&blue alpha:&alpha];
        }
        CGContextSetFillColor(context, (CGFloat[8]){red, green, blue, alpha});
        CGContextFillPath(context);
        CGContextRestoreGState(context);
    } else {
        CGContextClip(context);
        CGFloat locations[2] = {0, 0.95};
        CGFloat red = 0.631, green = 0.733, blue = 1.0, alpha = 1.0, aRed = 0.463, aGreen = 0.510, aBlue = 0.839, aAlpha = 1.0;
        if ([_colors valueForKey:@"normalBorderTopColor"] != nil) {
            [[_colors valueForKey:@"normalBorderTopColor"] getRed:&red green:&green blue:&blue alpha:&alpha];
        }
        if ([_colors valueForKey:@"normalBorderBottomColor"] != nil) {
            [[_colors valueForKey:@"normalBorderBottomColor"] getRed:&aRed green:&aGreen blue:&aBlue alpha:&aAlpha];
        }
        CGFloat components[8] = {red, green, blue, alpha, aRed, aGreen, aBlue, aAlpha};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 2);
        CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
        CGGradientRelease(gradient);
        CGContextRestoreGState(context);
    }
    
    // Draw the inner gradient.
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextAddArc(context, arcValue, arcValue, (bounds.size.height / 2), (M_PI / 2) , (3 * M_PI / 2), NO);
    CGContextAddArc(context, bounds.size.width - arcValue, arcValue, arcValue - 1, (3 * M_PI / 2), (M_PI / 2), NO);
    CGContextClosePath(context);
    
    CGContextClip(context);
    
    CGFloat locations[2] = {0, _highlighted ? 0.8 : 0.4};
    
    CGFloat red = 0.365, green = 0.557, blue = 1.0, alpha = 1.0, aRed = 0.251, aGreen = 0.345, aBlue = 1.0, aAlpha = 1.0;
    if ([_colors valueForKey:@"highlightedTopColor"] != nil) {
        [[_colors valueForKey:@"highlightedTopColor"] getRed:&red green:&green blue:&blue alpha:&alpha];
    }
    if ([_colors valueForKey:@"highlightedBottomColor"] != nil) {
        [[_colors valueForKey:@"highlightedBottomColor"] getRed:&aRed green:&aGreen blue:&aBlue alpha:&aAlpha];
    }
    CGFloat highlightedComp[8] = {red, green, blue, alpha, aRed, aGreen, aBlue, aAlpha};
    
    CGFloat hRed = 0.867, hGreen = 0.906, hBlue = 0.973, hAlpha = 1.0, ahRed = 0.737, ahGreen = 0.808, ahBlue = 0.945, ahAlpha = 1.0;
    if ([_colors valueForKey:@"normalTopColor"] != nil) {
        [[_colors valueForKey:@"normalColor"] getRed:&hRed green:&hGreen blue:&hBlue alpha:&hAlpha];
    }
    if ([_colors valueForKey:@"normalBottomColor"] != nil) {
        [[_colors valueForKey:@"normalBottomColor"] getRed:&ahRed green:&ahGreen blue:&ahBlue alpha:&ahAlpha];
    }
    CGFloat nonHighlightedComp[8] = {hRed, hGreen, hBlue, hAlpha, ahRed, ahGreen, ahBlue, ahAlpha};
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, _highlighted ? highlightedComp : nonHighlightedComp, locations, 2);
    CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    CGContextRestoreGState(context);
    
    UIColor *normalFontColor = [UIColor blackColor], *highlightedFontColor = [UIColor whiteColor];
    if ([_colors valueForKey:@"normalFontColor"] != nil) {
        normalFontColor = [_colors valueForKey:@"normalFontColor"];
    }
    if ([_colors valueForKey:@"highlightedFontColor"] != nil) {
        highlightedFontColor = [_colors valueForKey:@"highlightedFontColor"];
    }
    [(_highlighted ? highlightedFontColor : normalFontColor) set];
    [_title drawInRect:textBounds withFont:_tokenField.font];
}

- (CGSize)desiredSize
{
    CGSize titleSize = [_title sizeWithFont:_tokenField.font];
    titleSize.width += TOKEN_HZ_PADDING*2.0;
    titleSize.height += TOKEN_VT_PADDING*2.0 + 2;
    return titleSize;
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    [self setNeedsDisplay];
}

@end
