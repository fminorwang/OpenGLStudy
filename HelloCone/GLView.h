//
//  GLView.h
//  Dimensions
//
//  Created by fminor on 2/27/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRenderingEngine.hpp"
#import <OpenGLES/EAGL.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES1/glext.h>

@interface GLView : UIView
{
    @private
    EAGLContext             *m_context;
    IRenderingEngine        *m_renderingEngine;
    float                   m_timestamp;
}

- (void)drawView:(CADisplayLink *)displayLink;
- (void)didRotate:(NSNotification *)notification;

@end
