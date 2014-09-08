//
//  WSLHomeViewController.m
//  Dimensions
//
//  Created by fminor on 8/25/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "WSLHomeViewController.h"
#import "DynamicViewController.h"
#import <QuartzCore/QuartzCore.h>

#define NUM_OF_POINTS_LINE_X        10001
#define NUM_OF_POINTS_LINE_Y        9
#define NUM_OF_POINTS_ALL           ( NUM_OF_POINTS_LINE_X * NUM_OF_POINTS_LINE_Y )

#define MIN_X                       -1.0
#define MIN_Y                       -1.2
#define MAX_X                       1.0
#define MAX_Y                       1.2

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

const Vertex vertices[] = {
    {{0.5, -0.5, 0}, {1, 0, 0, 1}},
    {{0.5, 0.5, 0}, {0, 1, 0, 1}},
    {{-0.5, 0.5, 0}, {0, 0, 1, 1}},
    {{-0.5, -0.5, 0}, {0, 0, 0, 1}},
};

const GLubyte indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface WSLHomeViewController ()
{
    EAGLContext                 *_context;
    CGFloat                     _colorRed;
    BOOL                        _increase;
    CGFloat                     _rotation;
    CGFloat                     _distance;
    
    GLuint                      _vertexBuffer;
    GLuint                      _indexBuffer;
    
    GLuint                      _program;
    GLuint                      _factor;
    CGFloat                     _inc;
    
    Vertex                      *_vertices;
}

@end

@implementation WSLHomeViewController

@synthesize context = _context;
@synthesize effect = _effect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if ( !_context ) {
        return;
    }
    
    GLKView *__view = (GLKView *)self.view;
    __view.context = _context;
    __view.enableSetNeedsDisplay = NO;
    
    self.preferredFramesPerSecond = 60;
    
    _colorRed = 0.0;
    _increase = YES;
    _rotation = 0;
    _distance = 0;
    _inc = 0;
    
    _vertices = malloc(sizeof(Vertex) * NUM_OF_POINTS_ALL);
    for ( int i = 0 ; i < NUM_OF_POINTS_LINE_Y ; i++ ) {
        for ( int j = 0 ; j < NUM_OF_POINTS_LINE_X ; j++ ) {
            _vertices[NUM_OF_POINTS_LINE_X * i + j] = (Vertex){ {MIN_X + ( ( MAX_X - MIN_X ) / (NUM_OF_POINTS_LINE_X - 1) * j),
                                                                 MIN_Y + ( ( MAX_Y - MIN_Y ) / (NUM_OF_POINTS_LINE_Y - 1) * i),
                                                                 0 },
                                                                {0.0, 0.0, 0.0, 1.0}};
        }
    }
    
    [self _setupGL];
    
    UITapGestureRecognizer *_tap = [[UITapGestureRecognizer alloc]
                                    initWithTarget:self
                                    action:@selector(_eventTap:)];
    [self.view addGestureRecognizer:_tap];
}

- (void)dealloc
{
    [self _tearDownGL];
    if ( [EAGLContext currentContext] == self.context ) {
        [EAGLContext setCurrentContext:nil];
    }
    free(_vertices);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
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

    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, self.effect.transform.modelviewMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, 0, self.effect.transform.projectionMatrix.m);
    glUniform1f(_factor, _inc);
    
    // glDrawArrays(GL_TRIANGLES, 0, 36);
    // glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDrawArrays(GL_POINTS, 0 , NUM_OF_POINTS_ALL);
}

- (void)update
{
    if ( _colorRed >= 1.0 ) {
        _increase = NO;
    }
    if ( _colorRed <= 0.0 ) {
        _increase = YES;
    }
    
    _rotation += 0.1 * self.timeSinceLastUpdate;
    
    _colorRed += 0.5 * self.timeSinceLastUpdate * ( _increase ? 1 : -1 );
    _inc += 0.25 * self.timeSinceLastUpdate * ( _increase ? 1 : 1);

    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 4.0f, 10.f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 _modelViewMatrix = GLKMatrix4MakeZRotation(1.0);
    _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0.0f, 0.0f, -6.0);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, _rotation, 1.0, 1.0, 1.0);
    // _rotation += 90 * self.timeSinceLastUpdate;
    self.effect.transform.modelviewMatrix = _modelViewMatrix;
    
    //_distance -= self.timeSinceLastUpdate * 0.5;
}

- (void)_setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * NUM_OF_POINTS_ALL, _vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * NUM_OF_POINTS_ALL, _vertices, GL_STATIC_DRAW);
}

- (void)_tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    self.effect = nil;
}

#pragma mark - action tap handler

- (void)_eventTap:(id)sender
{
    DynamicViewController *_dvc = [[DynamicViewController alloc] init];
    [self.navigationController pushViewController:_dvc animated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.paused = !self.paused;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
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
    _factor = glGetUniformLocation(_program, "factor");
    
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
