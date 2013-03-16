#import "APShadowView.h"
#import <QuartzCore/QuartzCore.h>

@implementation APShadowView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.userInteractionEnabled = NO;
        
        shadowLayer = [[CAGradientLayer alloc] init];
        shadowLayer.colors = @[(id)[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5].CGColor,
                               (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
        
        [self.layer addSublayer:shadowLayer];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    shadowLayer.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
}

@end
