//
//  FComplexNumber.m
//  Dimensions
//
//  Created by fminor on 8/25/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "FComplexNumber.h"
// #import <math.h>

@implementation FComplexNumber

@synthesize x = _x;
- (void)setX:(CGFloat)x
{
    _x = x;
    _raduis = sqrtf( _x * _x + _y * _y );
}

- (CGFloat)_angleWithX:(CGFloat)x Y:(CGFloat)y
{
    if ( x == 0 ) {
        return ( y >= 0 ) ? 0 : M_PI_2;
    }
    
    if ( x > 0 && y >= 0 ) {
        return atan2f(y, x);
    }
    
    if ( x < 0 ) {
        return M_PI + atan2f(y, x);
    }
    
    if ( x > 0 && y < 0 ) {
        return 2 * M_PI + atan2f(y, x);
    }
    
    return 0;
}

@end
