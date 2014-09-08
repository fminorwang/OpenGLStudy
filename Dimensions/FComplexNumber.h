//
//  FComplexNumber.h
//  Dimensions
//
//  Created by fminor on 8/25/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FComplexNumber : NSObject
{
    CGFloat                     _x;
    CGFloat                     _y;
    CGFloat                     _radius;
    CGFloat                     _angle;
}

@property (nonatomic, assign) CGFloat           x;
@property (nonatomic, assign) CGFloat           y;
@property (nonatomic, assign) CGFloat           raduis;
@property (nonatomic, assign) CGFloat           angle;

@end
