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
    for ( int i = 0 ; i < 10 ; i++ ) {
        _spherePoints[i] = (Vertex) {
            {0.1 * i, 0.0, 0.0 },
            {0.0, 0.0, 0.0, 1.0}
        };
    }
    
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
    NSDictionary *_uniforms = @{ @(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX]) : @"modelViewMatrix",
                                 @(uniforms[UNIFORM_PROJECTION_MATRIX]) : @"projectionMatrix"  };
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * 10, &_spherePoints , GL_STATIC_DRAW);
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
    NSLog(@"%f, %f, %f", _movePoint.Position[0], _movePoint.Position[1], _movePoint.Position[2]);
    
    x = _movePoint2.Position[0];
    y = _movePoint2.Position[1];
    
    _movePoint2.Position[0] += dt * ( a * x + b * y );
    _movePoint2.Position[1] += dt * ( c * x + d * y );
    _movePoint2.Position[2] = 0.0;
    
    _historyPoints[_numberOfPoints - 1] = _movePoint2;

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, _sphereBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * 10, _spherePoints, GL_STATIC_DRAW);
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
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.effect.transform.modelviewMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, 0, self.effect.transform.projectionMatrix.m);
    
    glDrawArrays(GL_POINTS, 0 , 10 );
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"DynamicSystemShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"DynamicSystemShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    // 设置全局变量
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
    uniforms[UNIFORM_PROJECTION_MATRIX] = glGetUniformLocation(_program, "projectionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
