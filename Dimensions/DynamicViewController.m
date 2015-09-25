//
//  DynamicViewController.m
//  Dimensions
//
//  Created by fminor on 9/5/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "DynamicViewController.h"
#import "VertexShaderCompiler.h"

//#include "Interfaces.hpp"
//#include "Matrix.hpp"

#include <OpenGLES/ES2/glext.h>
#include <OpenGLES/ES2/gl.h>

#define NUM_OF_ALL_INDICES              10000
#define MAX_COUNT                       1000000
#define PIPE_CIRCLE_POINT_COUNT         10
#define PIPE_RADIUS                     0.5

#define NUM_OF_SPHERE_LATITUEDS         24
#define NUM_OF_SPHERE_LONGLITUDES       24

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

typedef struct {
    float Position[3];
    float Normal[3];
    float Color[4];
} NormedVertx;

@interface DynamicViewController()
{
    GLuint                  _vertexBuffer;
    GLuint                  _indexBuffer;

    GLuint                  _sphereBuffer;
    GLuint                  _sphereIndexBuffer;
    
    GLuint                  _program;
    GLuint                  _sphereProgram;
    
    CGFloat                 _factor;
    BOOL                    _increase;
    
    // Vertex                  *_vertexPtr;
    Vertex                  _movePoint;
    Vertex                  _movePoint2;
    int                     _numberOfPoints;
    Vertex                  *_historyPoints;
    Vertex                  *_historyPoints2;
    
    NormedVertx             *_pipeLinePoints;
    NormedVertx             *_pipeLinePoints2;
    GLuint                  _pipeLineBuffer;
    GLuint                  _pipeLineBuffer2;
    GLuint                  _pipeLineIndexBuffer;
    float                   _radius;
    unsigned short          _pipeIndices[100000000];
    
    GLuint                  _pipeIndicesBuffer;
    
    int                     _sphereIndexes[ 2 * 3 * NUM_OF_SPHERE_LONGLITUDES
                                           + 2 * 3 * ( NUM_OF_SPHERE_LATITUEDS - 1 ) * NUM_OF_SPHERE_LONGLITUDES ];
    
    NormedVertx             *_spherePoints;
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
    
    _movePoint = (Vertex) {
        { 2.0, 2.0, 0.0 },
        { 0.0, 0.0, 0.0, 1.0 }
    };
    
    _movePoint2 = (Vertex) {
        { -1.5, -3.0, 0 },
        { 0.0, 0.0, 0.0, 1.0}
    };
    
    _numberOfPoints = 2;
//    _historyPoints = new Vertex[MAX_COUNT];
    _historyPoints = malloc(sizeof(Vertex) * MAX_COUNT);
    _historyPoints[_numberOfPoints - 2] = _movePoint;
    _historyPoints[_numberOfPoints - 1] = _movePoint2;
    
    _pipeLinePoints = malloc(sizeof(NormedVertx) * MAX_COUNT * PIPE_CIRCLE_POINT_COUNT);
    _pipeLinePoints2 = malloc(sizeof(NormedVertx) * MAX_COUNT * PIPE_CIRCLE_POINT_COUNT);
    
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

    _factor = 0.1f;
    
    // 轨迹
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_pipeLineBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(NormedVertx) * ( _numberOfPoints / 2 - 1 ) * PIPE_CIRCLE_POINT_COUNT , _pipeLinePoints, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_pipeLineBuffer2);
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(NormedVertx) * ( _numberOfPoints / 2 - 1 ) * PIPE_CIRCLE_POINT_COUNT , _pipeLinePoints, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_pipeIndicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned short) * MAX(0, ( _numberOfPoints / 2 - 3 ) * 2 * 3 * PIPE_CIRCLE_POINT_COUNT), _pipeIndices, GL_STATIC_DRAW);
    
    //glGenBuffers(1, &_indexBuffer);
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    //glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, &_historyPoints, GL_STATIC_DRAW);
    
    // sphere
    glGenBuffers(1, &_sphereBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(NormedVertx) * (NUM_OF_SPHERE_LATITUEDS * NUM_OF_SPHERE_LONGLITUDES + 2),
                 _spherePoints , GL_STATIC_DRAW);
    
    /*
    glGenBuffers(1, &_sphereIndexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _sphereIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int) * 12 , _sphereIndexes, GL_STATIC_DRAW);
     */
    
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
    glDeleteBuffers(1, &_vertexBuffer);
    //glDeleteBuffers(1, &_indexBuffer);
    
    glDeleteBuffers(1, &_sphereBuffer);
    
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

    _factor += self.timeSinceLastUpdate * 0.03;
    _radius = 0.1 * ( 0.2 / _factor ) ;
    
    /*
     dx/dt = ax + by;
     dy/dt = cx + dy;
     */
    float a = 0.1;
    float b = 0.2;
    float c = -0.3;
    float d = -0.2;

    // 前一个点
    float x = _movePoint.Position[0];
    float y = _movePoint.Position[1];
    float z = _movePoint.Position[2];
    
    // 当前的点
    _movePoint.Position[0] += dt * ( a * x + b * y );
    _movePoint.Position[1] += dt * ( c * x + d * y );
    _movePoint.Position[2] = 0.0;
    
    // 管道上的点
    float x1 = _movePoint.Position[0];
    float y1 = _movePoint.Position[1];
    float x0 = x;
    float y0 = y;
    float _sqrt = sqrtf( ( x1 - x0 ) * ( x1 - x0) + ( y1 - y0 ) * ( y1 - y0 ) );
    for ( int i = 0 ; i < PIPE_CIRCLE_POINT_COUNT ; i++ ) {
        
        NormedVertx _pipePoint = { {0, 0, 0}, {0, 0, 0}, {0.5, 0.5, 0, 0.5} };
        _pipePoint.Position[0] = x1 - _radius * sin( 2 * M_PI * i / PIPE_CIRCLE_POINT_COUNT ) * ( y1 - y0 ) / _sqrt;
        _pipePoint.Position[1] = y1 + _radius * sin( 2 * M_PI * i / PIPE_CIRCLE_POINT_COUNT ) * ( x1 - x0 ) / _sqrt;
        _pipePoint.Position[2] = _radius * cos( 2 * M_PI * i / PIPE_CIRCLE_POINT_COUNT );
        
        _pipePoint.Normal[0] = _pipePoint.Position[0] - x1;
        _pipePoint.Normal[1] = _pipePoint.Position[1] - y1;
        _pipePoint.Normal[2] = _pipePoint.Position[2] - 0;
        
        float _length = sqrtf( _pipePoint.Normal[0] * _pipePoint.Normal[0]
                              + _pipePoint.Normal[1] * _pipePoint.Normal[1]
                              + _pipePoint.Normal[2] * _pipePoint.Normal[2] );
        _pipePoint.Normal[0] = _pipePoint.Normal[0] / _length;
        _pipePoint.Normal[1] = _pipePoint.Normal[1] / _length;
        _pipePoint.Normal[2] = _pipePoint.Normal[2] / _length;
        
        _pipeLinePoints[(_numberOfPoints / 2 - 1) * PIPE_CIRCLE_POINT_COUNT + i] = _pipePoint;
    }
    
    _numberOfPoints++;
    _numberOfPoints++;
    _historyPoints[_numberOfPoints - 2] = _movePoint;
    
    if ( _numberOfPoints / 2 >= 3 ) {
        int _index = ( _numberOfPoints / 2 - 3 ) * PIPE_CIRCLE_POINT_COUNT * 3 * 2;
        int _point = ( _numberOfPoints / 2 - 3 ) * PIPE_CIRCLE_POINT_COUNT;
        for ( int i = 0 ; i < PIPE_CIRCLE_POINT_COUNT ; i++ ) {
            
            _pipeIndices[_index++] = _point + i;
            _pipeIndices[_index++] = _point + ( i + 1 ) % PIPE_CIRCLE_POINT_COUNT;
            _pipeIndices[_index++] = _point + i + PIPE_CIRCLE_POINT_COUNT;
            
            _pipeIndices[_index++] = _point + ( i + 1 ) % PIPE_CIRCLE_POINT_COUNT;
            _pipeIndices[_index++] = _point + i + PIPE_CIRCLE_POINT_COUNT;
            _pipeIndices[_index++] = _point + PIPE_CIRCLE_POINT_COUNT + ( i + 1 ) % PIPE_CIRCLE_POINT_COUNT;
        }
    }
    
    x = _movePoint2.Position[0];
    y = _movePoint2.Position[1];
    
    _movePoint2.Position[0] += dt * ( a * x + b * y );
    _movePoint2.Position[1] += dt * ( c * x + d * y );
    _movePoint2.Position[2] = 0.0;
    
    x1 = _movePoint2.Position[0];
    y1 = _movePoint2.Position[1];
    x0 = x;
    y0 = y;
    _sqrt = sqrtf( ( x1 - x0 ) * ( x1 - x0) + ( y1 - y0 ) * ( y1 - y0 ) );
    for ( int i = 0 ; i < PIPE_CIRCLE_POINT_COUNT ; i++ ) {
        
        NormedVertx _pipePoint = { {0, 0, 0}, {0, 0, 0}, {0.5, 0.5, 0, 0.5} };
        _pipePoint.Position[0] = x1 - _radius * sin( 2 * M_PI * i / PIPE_CIRCLE_POINT_COUNT ) * ( y1 - y0 ) / _sqrt;
        _pipePoint.Position[1] = y1 + _radius * sin( 2 * M_PI * i / PIPE_CIRCLE_POINT_COUNT ) * ( x1 - x0 ) / _sqrt;
        _pipePoint.Position[2] = _radius * cos( 2 * M_PI * i / PIPE_CIRCLE_POINT_COUNT );
        
        _pipePoint.Normal[0] = _pipePoint.Position[0] - x1;
        _pipePoint.Normal[1] = _pipePoint.Position[1] - y1;
        _pipePoint.Normal[2] = _pipePoint.Position[2] - 0;
        
        float _length = sqrtf( _pipePoint.Normal[0] * _pipePoint.Normal[0]
                              + _pipePoint.Normal[1] * _pipePoint.Normal[1]
                              + _pipePoint.Normal[2] * _pipePoint.Normal[2] );
        _pipePoint.Normal[0] = _pipePoint.Normal[0] / _length;
        _pipePoint.Normal[1] = _pipePoint.Normal[1] / _length;
        _pipePoint.Normal[2] = _pipePoint.Normal[2] / _length;
        
        _pipeLinePoints2[(_numberOfPoints / 2 - 2) * PIPE_CIRCLE_POINT_COUNT + i] = _pipePoint;
    }
    
    _historyPoints[_numberOfPoints - 1] = _movePoint2;

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(NormedVertx) * (2 + NUM_OF_SPHERE_LATITUEDS * NUM_OF_SPHERE_LONGLITUDES), _spherePoints, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(NormedVertx) * ( _numberOfPoints / 2 - 1 ) * PIPE_CIRCLE_POINT_COUNT , _pipeLinePoints, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(NormedVertx) * ( _numberOfPoints / 2 - 1 ) * PIPE_CIRCLE_POINT_COUNT , _pipeLinePoints2, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 sizeof(unsigned short) * MAX(0, ( _numberOfPoints / 2 - 2 ) * 2 * 3 * PIPE_CIRCLE_POINT_COUNT),
                 _pipeIndices,
                 GL_STATIC_DRAW);
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
    
    // ambient
    glUniform3f(_ambientSlot, 0.5, 0.2, 0.2);
    
    // specular
    glUniform3f(_specularSlot, 0.8, 0.8, 0.8);
    
    glUniform1f(_shininessSlot, 40.f);
    
    // 画图
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(NormedVertx), offsetof(NormedVertx, Position));
    glEnableVertexAttribArray(_normalSlot);
    glVertexAttribPointer(_normalSlot, 3, GL_FLOAT, GL_FALSE, sizeof(NormedVertx), (const GLvoid *)offsetof(NormedVertx, Normal));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glDrawElements(GL_TRIANGLES, MAX(0, ( _numberOfPoints / 2 - 2 ) * PIPE_CIRCLE_POINT_COUNT * 2 * 3), GL_UNSIGNED_SHORT, 0);
    glDrawArrays(GL_POINTS, 0, ( _numberOfPoints / 2 - 1 ) * PIPE_CIRCLE_POINT_COUNT);
    
    glUniform3f(_ambientSlot, 0.2, 0.5, 0.2);
    
    glBindBuffer(GL_ARRAY_BUFFER, _pipeLineBuffer2);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(NormedVertx), offsetof(NormedVertx, Position));
    glEnableVertexAttribArray(_normalSlot);
    glVertexAttribPointer(_normalSlot, 3, GL_FLOAT, GL_FALSE, sizeof(NormedVertx), (const GLvoid *)offsetof(NormedVertx, Normal));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _pipeIndicesBuffer);
    glDrawElements(GL_TRIANGLES, MAX(0, ( _numberOfPoints / 2 - 2 ) * PIPE_CIRCLE_POINT_COUNT * 2 * 3), GL_UNSIGNED_SHORT, 0);
    glDrawArrays(GL_POINTS, 0, ( _numberOfPoints / 2 - 1 ) * PIPE_CIRCLE_POINT_COUNT);

    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    // glBindVertexArrayOES(_vertexBuffer);
    
    // Render the object again with ES2
//    glUseProgram(_program);
//    
//    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.effect.transform.modelviewMatrix.m);
//    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, 0, self.effect.transform.projectionMatrix.m);
//    
//    // ----------------------------------------
//    
//    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
//    
//    glEnableVertexAttribArray(GLKVertexAttribPosition);
//    glVertexAttribPointer(GLKVertexAttribPosition,          // 设置属性：顶点位置
//                          3,                                // 每个顶点需要多少个值来描述
//                          GL_FLOAT,                         // 每个值的类型
//                          GL_FALSE,                         // always set to false
//                          sizeof(NormedVertx),                   // 数据结构大小
//                          offsetof(NormedVertx, Position));      // 数据结构中的偏位置
    
//    glEnableVertexAttribArray(GLKVertexAttribNormal);
//    glVertexAttribPointer(GLKVertexAttribNormal,
//                          3,
//                          GL_FLOAT,
//                          GL_FALSE,
//                          sizeof(NormedVertx),
//                          offsetof(NormedVertx, Normal));
    // glBindVertexArrayOES(_vertexBuffer);
    
    // Render the object again with ES2
//    glUseProgram(_sphereProgram);
//    
//    glUniformMatrix4fv(sphereUniforms[S_UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.effect.transform.modelviewMatrix.m);
//    glUniformMatrix4fv(sphereUniforms[S_UNIFORM_PROJECTION_MATRIX], 1, 0, self.effect.transform.projectionMatrix.m);
//    glUniform1f(sphereUniforms[S_RADIUS], 0.5 * ( 0.2 / _factor ));
//    glUniform1f(sphereUniforms[S_LATITUDE_COUNTS], NUM_OF_SPHERE_LATITUEDS + 2.0);
//    glUniform3fv(sphereUniforms[S_CENTER_POINT], 1, _movePoint.Position );
//    
//    glDrawElements(GL_TRIANGLES, 3 * NUM_OF_SPHERE_LONGLITUDES, GL_UNSIGNED_INT, _sphereIndexes);

    // glDrawArrays(GL_TRIANGLES, 0 , 6 /*NUM_OF_SPHERE_LATITUEDS * NUM_OF_SPHERE_LONGLITUDES + 2*/ );
}

@end
