//
//  DynamicViewController.m
//  Dimensions
//
//  Created by fminor on 9/5/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "DynamicViewController.h"
#import "VertexShaderCompiler.h"
#import <OpenGLES/ES2/glext.h>

#define NUM_OF_ALL_INDICES              10000
#define MAX_COUNT                       100000

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_PROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

enum
{
    S_UNIFORM_MODELVIEWPROJECTION_MATRIX,
    S_UNIFORM_PROJECTION_MATRIX,
    S_RADIUS,
    S_CENTER_POINT,
    S_LATITUDE_COUNTS,
    S_NUM_UNIFORMS
};
GLint sphereUniforms[S_NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

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
    
    Vertex                  *_spherePoints;
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
    
    _increase = YES;
    
    _movePoint = (Vertex) {
        { 2.0, 2.0, 0.0 },
        { 0.0, 0.0, 0.0, 1.0 }
    };
    
    _movePoint2 = (Vertex) {
        { -1.5, -3.0, 0 },
        { 0.0, 0.0, 0.0, 1.0}
    };
    
    _numberOfPoints = 2;
    _historyPoints = malloc(sizeof(Vertex) * MAX_COUNT);
    _historyPoints[_numberOfPoints - 2] = _movePoint;
    _historyPoints[_numberOfPoints - 1] = _movePoint2;
    
    _spherePoints = malloc(10 * sizeof(Vertex));
    _spherePoints[0] = (Vertex) {
        {0.0, 0.0, 1.0},
        {0.0, 0.0, 0.0, 1.0}
    };
    _spherePoints[1] = (Vertex) {
        {1.0, 0.0, 4.0},
        {0.0, 0.0, 0.0, 1.0}
    };
    _spherePoints[2] = (Vertex) {
        {1.0, 1.0, 4.0},
        {0.0, 0.0, 0.0, 1.0}
    };
    _spherePoints[3] = (Vertex) {
        {1.0, 2.0, 4.0},
        {0.0, 0.0, 0.0, 1.0}
    };
    _spherePoints[4] = (Vertex) {
        {1.0, 3.0, 4.0},
        {0.0, 0.0, 0.0, 1.0}
    };
    _spherePoints[5] = (Vertex) {
        {2.0, 0.0, 4.0},
        {0.0, 0.0, 0.0, 1.0}
    };

    [self _setupGL];
}

- (void)dealloc
{
    [self _tearDownGL];
}

- (void)_setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    NSDictionary *_attributes = @{ @(GLKVertexAttribPosition) : @"position" };
    
    NSDictionary *_sphereUniforms = @
    {   @"modelViewMatrix"  : [NSValue valueWithPointer:&(sphereUniforms[S_UNIFORM_MODELVIEWPROJECTION_MATRIX])] ,
        @"projectionMatrix" : [NSValue valueWithPointer:&(sphereUniforms[S_UNIFORM_PROJECTION_MATRIX])],
        @"centerPoint"      : [NSValue valueWithPointer:&(sphereUniforms[S_CENTER_POINT])],
        @"radius"           : [NSValue valueWithPointer:&(sphereUniforms[S_RADIUS])],
        @"latitudeCounts"   : [NSValue valueWithPointer:&(sphereUniforms[S_LATITUDE_COUNTS])]
    };
    [[VertexShaderCompiler sharedCompiler] loadShadersWithFileName:@"SphereShader"
                                                        attributes:_attributes
                                                          uniforms:_sphereUniforms
                                                           program:&_sphereProgram];
    
    NSDictionary *_uniforms = @{
                                @"modelViewMatrix"  : [NSValue valueWithPointer:&(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX])] ,
                                @"projectionMatrix" : [NSValue valueWithPointer:&(uniforms[UNIFORM_PROJECTION_MATRIX])],  };
    [[VertexShaderCompiler sharedCompiler] loadShadersWithFileName:@"DynamicSystemShader"
                                                        attributes:_attributes
                                                          uniforms:_uniforms
                                                           program:&_program];
    

    
    
    self.effect = [[GLKBaseEffect alloc] init];
    _factor = 0.2f;
    
    // 轨迹
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    
    //glGenBuffers(1, &_indexBuffer);
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    //glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, &_historyPoints, GL_STATIC_DRAW);
    
    // sphere
    glGenBuffers(1, &_sphereBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * 6, _spherePoints , GL_STATIC_DRAW);
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
    float _aspect = self.view.bounds.size.width / self.view.bounds.size.height;
    GLKMatrix4 _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f),
                                                             _aspect, 1.0f, 21.f);
    self.effect.transform.projectionMatrix = _projectionMatrix;
    
    float dt = self.timeSinceLastUpdate * 2;

    _factor += self.timeSinceLastUpdate * 0.01;
    
    GLKMatrix4 _modelViewMatrix = GLKMatrix4Identity;
    _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0.0f, 0.0f, -2.1f);
    _modelViewMatrix = GLKMatrix4Scale(_modelViewMatrix, _factor, _factor, _factor);
    self.effect.transform.modelviewMatrix = _modelViewMatrix;

    /*
     dx/dt = ax + by;
     dy/dt = cx + dy;
     */
    float a = 0.1;
    float b = 0.2;
    float c = -0.3;
    float d = -0.2;

    float x = _movePoint.Position[0];
    float y = _movePoint.Position[1];
    float z = _movePoint.Position[2];
    
    _movePoint.Position[0] += dt * ( a * x + b * y );
    _movePoint.Position[1] += dt * ( c * x + d * y );
    _movePoint.Position[2] = 0.0;
    
    _numberOfPoints++;
    _numberOfPoints++;
    _historyPoints[_numberOfPoints - 2] = _movePoint;
    // NSLog(@"%f, %f, %f", _movePoint.Position[0], _movePoint.Position[1], _movePoint.Position[2]);
    
    x = _movePoint2.Position[0];
    y = _movePoint2.Position[1];
    
    _movePoint2.Position[0] += dt * ( a * x + b * y );
    _movePoint2.Position[1] += dt * ( c * x + d * y );
    _movePoint2.Position[2] = 0.0;
    
    _historyPoints[_numberOfPoints - 1] = _movePoint2;

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * 6, _spherePoints, GL_STATIC_DRAW);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition,          // 设置属性：顶点位置
                          3,                                // 每个顶点需要多少个值来描述
                          GL_FLOAT,                         // 每个值的类型
                          GL_FALSE,                         // always set to false
                          sizeof(Vertex),                   // 数据结构大小
                          offsetof(Vertex, Position));      // 数据结构中的偏位置
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid*)offsetof(Vertex, Color));
    // glBindVertexArrayOES(_vertexBuffer);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.effect.transform.modelviewMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, 0, self.effect.transform.projectionMatrix.m);
    
    glDrawArrays(GL_POINTS, 0 , _numberOfPoints );
    
    // ----------------------------------------
    
    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition,          // 设置属性：顶点位置
                          3,                                // 每个顶点需要多少个值来描述
                          GL_FLOAT,                         // 每个值的类型
                          GL_FALSE,                         // always set to false
                          sizeof(Vertex),                   // 数据结构大小
                          offsetof(Vertex, Position));      // 数据结构中的偏位置
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex),
                          (const GLvoid*)offsetof(Vertex, Color));
    // glBindVertexArrayOES(_vertexBuffer);
    
    // Render the object again with ES2
    glUseProgram(_sphereProgram);
    
    glUniformMatrix4fv(sphereUniforms[S_UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.effect.transform.modelviewMatrix.m);
    glUniformMatrix4fv(sphereUniforms[S_UNIFORM_PROJECTION_MATRIX], 1, 0, self.effect.transform.projectionMatrix.m);
    glUniform1f(sphereUniforms[S_RADIUS], 0.5f);
    glUniform1i(sphereUniforms[S_LATITUDE_COUNTS], 3.0);
    glUniform4f(sphereUniforms[S_CENTER_POINT], _movePoint.Position[0], _movePoint.Position[1], _movePoint.Position[2], 1.0f);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0 , 6 );
}

@end
