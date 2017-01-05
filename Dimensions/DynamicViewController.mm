//
//  DynamicViewController.m
//  Dimensions
//
//  Created by fminor on 9/5/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "DynamicViewController.h"
#import "VertexShaderCompiler.h"

#include "DynamicSphere.hpp"
#include "DynamicPath.hpp"

//#include "Interfaces.hpp"
#include "Matrix.hpp"
#include "ParametricEquations.hpp"

#include <OpenGLES/ES2/glext.h>
#include <OpenGLES/ES2/gl.h>

#define NUM_OF_ALL_INDICES              10000
#define MAX_COUNT                       1000000
#define PIPE_CIRCLE_POINT_COUNT         10
#define PIPE_RADIUS                     0.5

#define NUM_OF_SPHERE_LATITUEDS         24
#define NUM_OF_SPHERE_LONGLITUDES       24

@interface DynamicViewController()
{
    GLuint                  _program;
    GLuint                  _sphereProgram;
    
    CGFloat                 _originFactor;
    CGFloat                 _factor;
    BOOL                    _increase;
    
    float                   _originDistance;
    float                   _currentDistance;
    
    GLuint                  _pipeLineBuffer;
    GLuint                  _pipeLineBuffer2;
    GLuint                  _pipeLineIndexBuffer;
    float                   _radius;
    
    GLuint                  _pipeIndicesBuffer;
    
    OrderTwoDynamicPath     *_path1;
    OrderTwoDynamicPath     *_path2;
    
    DynamicSphere           _startSphere;
    DynamicSphere           _startSphere2;
}

@end

@implementation DynamicViewController

@synthesize effect = _effect;
@synthesize context = _context;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if ( !_context ) {
        return;
    }
    
    GLKView *__view = (GLKView *)self.view;
    __view.context = _context;
    __view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    _increase = YES;
    _radius = 0.2;
    
    _startSphere = DynamicSphere(vec3(2.0, 2.0, 0.0), _radius);
    _startSphere2 = DynamicSphere(vec3(-1.5, -3.0, 0.0), _radius);
    
//    float a = 0.1;
//    float b = 0.2;
//    float c = -0.3;
//    float d = -0.2;
    _path1 = new OrderTwoDynamicPath(0.1, 0.2, -0.3, -0.2, _radius, vec3(2.0, 2.0, 0.0));
    _path2 = new OrderTwoDynamicPath(0.1, 0.2, -0.3, -0.2, _radius, vec3(-1.5, -3.0, 0.0));
    
    [self _setupGL];
}

- (void)dealloc
{
    [self _tearDownGL];
}

- (void)_setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [[VertexShaderCompiler sharedCompiler] loadShadersWithFileName:@"DynamicSystemShader"
                                                        attributes:nil
                                                          uniforms:nil
                                                           program:&_program];
    
    glEnable(GL_DEPTH_TEST);

    _originFactor = 0.1f;
    _factor = 0.1f;
    
    // 轨迹
    glGenBuffers(1, &_pipeLineBuffer);
    glGenBuffers(1, &_pipeLineBuffer2);
    glGenBuffers(1, &_pipeIndicesBuffer);
    
    _startSphere.generateBuffer();
    _startSphere2.generateBuffer();
    
    GLuint _colorRenderBuffer;
    GLuint _depthRenderBuffer;
    
    int _width, _height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
    
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _width, _height);
    
    GLuint _frameBuffer;
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (void)_tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    //glDeleteBuffers(1, &_indexBuffer);
    
    glDeleteBuffers(1, &_pipeLineBuffer);
    glDeleteBuffers(1, &_pipeLineBuffer2);
    glDeleteBuffers(1, &_pipeIndicesBuffer);
    
    self.effect = nil;
}

#pragma mark - action handler

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - update & draw

- (void)update
{
    float dt = self.timeSinceLastUpdate * 2;

    _factor = _factor * powf(2, dt / 15.f);
    _radius = 0.02 / _factor ;
    
    if ( dt > 0 ) {
        _path1->m_pipeRadius = _radius;
        _path1->appendNext(dt);
        
        _path2->m_pipeRadius = _radius;
        _path2->appendNext(dt);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer);
    glBufferData(GL_ARRAY_BUFFER, _path1->m_vertices.size() * sizeof(_path1->m_vertices[0]),
                 &(_path1->m_vertices[0]),
                 GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer2);
    glBufferData(GL_ARRAY_BUFFER, _path2->m_vertices.size() * sizeof(_path2->m_vertices[0]),
                 &(_path2->m_vertices[0]),
                 GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned short) * _path1->m_indices.size(),
                 &(_path1->m_indices[0]), GL_STATIC_DRAW);
    
    _startSphere.bindBuffer();
    _startSphere2.bindBuffer();
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_program);
    GLuint _positionSlot = glGetAttribLocation(_program, "position");
    GLuint _diffuseSlot = glGetAttribLocation(_program, "diffuse");
    GLuint _normalSlot = glGetAttribLocation(_program, "normal");
    
    GLuint _modelViewSlot = glGetUniformLocation(_program, "modelViewMatrix");
    GLuint _normalMatrixSlot = glGetUniformLocation(_program, "normalMatrix");
    GLuint _projectionSlot = glGetUniformLocation(_program, "projectionMatrix");
    
    GLuint _lightPositionSlot = glGetUniformLocation(_program, "lightPosition");
    GLuint _ambientSlot = glGetUniformLocation(_program, "ambientMaterial");
    GLuint _specularSlot = glGetUniformLocation(_program, "specularMaterial");
    GLuint _shininessSlot = glGetUniformLocation(_program, "shininess");
    
    float _aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    GLKMatrix4 _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f),
                                                             _aspect, 1.0f, 21.f);
    
    GLKMatrix4 _modelViewMatrix = GLKMatrix4Identity;
    _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0.0f, 0.0f, -2.1f);
    _modelViewMatrix = GLKMatrix4Scale(_modelViewMatrix, _factor, _factor, _factor);
    
    // model view project 矩阵
    glUniformMatrix4fv(_modelViewSlot, 1, 0, _modelViewMatrix.m);
    glUniformMatrix4fv(_projectionSlot, 1, 0, _projectionMatrix.m);
    
    // normal 矩阵
    GLKMatrix3 _normalMatrix = GLKMatrix4GetMatrix3(_modelViewMatrix);
    glUniformMatrix3fv(_normalMatrixSlot, 1, 0, _normalMatrix.m);
    
    // light position
    glUniform3f(_lightPositionSlot, 0.5, 1.0, 0.5);
    
    // diffuse
    glUniform3f(_diffuseSlot, 0.0, 0.8, 0.0);
    
    // specular
    glUniform3f(_specularSlot, 0.8, 0.8, 0.8);
    
    glUniform1f(_shininessSlot, 40.f);
    
    void (^_drawSphere)(DynamicSphere &sphere) = ^(DynamicSphere &sphere){
        glBindBuffer(GL_ARRAY_BUFFER, sphere.vertexSlot);
        glEnableVertexAttribArray(_positionSlot);
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 6, 0);
        glEnableVertexAttribArray(_normalSlot);
        glVertexAttribPointer(_normalSlot, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 6, (const GLvoid *)sizeof(vec3));
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, sphere.indexSlot);
        glDrawElements(GL_TRIANGLES, (GLsizei)(sphere.sphere->getTriangleIndexCount()), GL_UNSIGNED_SHORT, 0);
    };
    
    // 画图
    
    // ambient
    glUniform3f(_ambientSlot, 0.5, 0.2, 0.2);

    // start sphere
    _drawSphere(_startSphere);
    
    // path 1
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer);
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(DynamicVertex), (const GLvoid *)offsetof(DynamicVertex, position));
    
    glEnableVertexAttribArray(_normalSlot);
    glVertexAttribPointer(_normalSlot, 3, GL_FLOAT, GL_FALSE, sizeof(DynamicVertex), (const GLvoid *)offsetof(DynamicVertex, normal));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glDrawElements(GL_TRIANGLES, (GLsizei)_path1->m_indices.size(), GL_UNSIGNED_SHORT, 0);
    
    // path 2
    glUniform3f(_ambientSlot, 0.2, 0.5, 0.2);
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer2);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(DynamicVertex), (const GLvoid *)offsetof(DynamicVertex, position));
    glEnableVertexAttribArray(_normalSlot);
    glVertexAttribPointer(_normalSlot, 3, GL_FLOAT, GL_FALSE, sizeof(DynamicVertex), (const GLvoid *)offsetof(DynamicVertex, normal));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glDrawElements(GL_TRIANGLES, (GLsizei)_path2->m_indices.size(), GL_UNSIGNED_SHORT, 0);
    
    // start sphere 2
    _drawSphere(_startSphere2);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
