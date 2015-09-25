//
//  GLView.m
//  Dimensions
//
//  Created by fminor on 2/27/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#import "GLView.h"

const BOOL cForceES1 = YES;

@implementation GLView

- (id)initWithFrame:(CGRect)frame
{
    if ( self = [super initWithFrame:frame] ) {
        CAEAGLLayer *_eaglLayer = (CAEAGLLayer *)super.layer;
        _eaglLayer.opaque = YES;
        EAGLRenderingAPI _api = kEAGLRenderingAPIOpenGLES2;
        m_context = [[EAGLContext alloc] initWithAPI:_api];
        if ( !m_context || cForceES1 ) {
            _api = kEAGLRenderingAPIOpenGLES1;
            m_context = [[EAGLContext alloc] initWithAPI:_api];
        }
        if ( !m_context || ![EAGLContext setCurrentContext:m_context] ) {
            return nil;
        }
        
        if ( _api == kEAGLRenderingAPIOpenGLES1 ) {
            NSLog(@"Using OpenGL ES 1.1");
            m_renderingEngine = createRenderer1();
        } else {
            NSLog(@"Using OpenGL ES 2.0");
            m_renderingEngine = createRenderer2();
        }
        [m_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:_eaglLayer];
        m_renderingEngine->initialize(CGRectGetWidth(frame), CGRectGetHeight(frame));
        [self drawView:nil];
        
        m_timestamp = CACurrentMediaTime();
        CADisplayLink *_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)drawView:(CADisplayLink *)displayLink
{
    if ( displayLink != nil ) {
        float _elapsedSeconds = displayLink.timestamp - m_timestamp;
        m_timestamp = displayLink.timestamp;
        m_renderingEngine->updateAnimation(_elapsedSeconds);
    }
    m_renderingEngine->render();
    [m_context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void)dealloc
{
    if ( [EAGLContext currentContext] == m_context ) {
        [EAGLContext setCurrentContext:nil];
    }
    m_context =  nil;
}

- (void)didRotate:(NSNotification *)notification
{
    UIDeviceOrientation _orientation = [[UIDevice currentDevice] orientation];
    m_renderingEngine->onRotate((DeviceOrientation)_orientation);
    [self drawView:nil];
}

@end
