//
//  WSLHomeViewController.h
//  Dimensions
//
//  Created by fminor on 8/25/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface WSLHomeViewController : GLKViewController

@property (nonatomic, readonly) EAGLContext             *context;
@property (nonatomic, strong) GLKBaseEffect             *effect;

@end
