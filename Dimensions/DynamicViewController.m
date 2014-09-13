//
//  DynamicViewController.m
//  Dimensions
//
//  Created by fminor on 9/5/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "DynamicViewController.h"

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
    GLuint                  _vertexBuffer2;
    GLuint                  _indexBuffer;
    
    GLuint                  _program;
    
    CGFloat                 _factor;
    BOOL                    _increase;
    
    // Vertex                  *_vertexPtr;
    Vertex                  _movePoint;
    Vertex                  _movePoint2;
    int                     _numberOfPoints;
    Vertex                  *_historyPoints;
    Vertex                  *_historyPoints2;
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
    
    /*
    _vertexPtr = malloc(sizeof(Vertex) * NUM_OF_ALL_INDICES);
    for ( int i = 0 ; i < NUM_OF_ALL_INDICES ; i++ ) {
        _vertexPtr[i] = (Vertex){
            { -1.0 + i * 0.0002 , 0.0, 0.0 },
            { 0.0, 0.0, 0.0, 1.0}
        };
    }
     */
     
    _movePoint = (Vertex) {
        { 25.0, 25.0, 0.0 },
        { 0.0, 0.0, 0.0, 1.0 }
    };
    
    _movePoint2 = (Vertex) {
        { -0.8, -1.2, 0 },
        { 0.0, 0.0, 0.0, 1.0}
    };
    
    _numberOfPoints = 2;
    _historyPoints = malloc(sizeof(Vertex) * MAX_COUNT);
    _historyPoints[_numberOfPoints - 2] = _movePoint;
    _historyPoints[_numberOfPoints - 1] = _movePoint2;
    
    [self _setupGL];
}

- (void)dealloc
{
    [self _tearDownGL];
}

- (void)_setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    GLKMatrix4 _modelViewMatrix = GLKMatrix4Identity;
    _factor = 0.3f;
    _modelViewMatrix = GLKMatrix4Scale(_modelViewMatrix, 0.3f, 0.3f, 1.0f);
    _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0.0f, 0.0f, -15.f);
    self.effect.transform.modelviewMatrix = _modelViewMatrix;
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    // glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * NUM_OF_ALL_INDICES, _vertexPtr, GL_STATIC_DRAW);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * NUM_OF_ALL_INDICES, _vertexPtr, GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, &_historyPoints, GL_STATIC_DRAW);
    
//    glGenBuffers(1, &_vertexBuffer2);
//    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints2, GL_STATIC_DRAW);
}

- (void)_tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    self.effect = nil;
}

#pragma mark - action handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.paused = !self.paused;
}

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
    
    _factor += ( self.timeSinceLastUpdate * 0.5 ) * ( _increase ? 1 : -1 );
    if ( _factor >= 2 ) {
        _increase = NO;
    }
    if ( _factor <= 0.5 ) {
        _increase = YES;
    }
    NSLog(@"_factor = %f", -_factor);
    
    GLKMatrix4 _modelViewMatrix = GLKMatrix4Identity;
    _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, 0.0f, 0.0f, -15.f);
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
    
    float dt = self.timeSinceLastUpdate * 0.02 ;
    float x = _movePoint.Position[0];
    float y = _movePoint.Position[1];
    float z = _movePoint.Position[2];
    
    /*
    _movePoint.Position[0] += dt * ( a * x + b * y );
    _movePoint.Position[1] += dt * ( c * x + d * y );
    _movePoint.Position[2] = 0.0;
     */
    _movePoint.Position[0] += dt * ( 10 * ( y - x ) );
    _movePoint.Position[1] += dt * ( 3 * x - y - x * z );
    _movePoint.Position[2] += dt * ( x * y - 8.0 * z / 3.0 );
    
    _numberOfPoints++;
    _numberOfPoints++;
    _historyPoints[_numberOfPoints - 2] = _movePoint;
    NSLog(@"%f, %f, %f", _movePoint.Position[0], _movePoint.Position[1], _movePoint.Position[2]);
    
    x = _movePoint2.Position[0];
    y = _movePoint2.Position[1];
    
    /*
    _movePoint2.Position[0] += dt * ( a * x + b * y );
    _movePoint2.Position[1] += dt * ( c * x + d * y );
    _movePoint2.Position[2] = 0.0;
     */
    
    _historyPoints[_numberOfPoints - 1] = _movePoint2;
    
    // glGenBuffers(1, &_vertexBuffer);
    // glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    // glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * NUM_OF_ALL_INDICES, _vertexPtr, GL_STATIC_DRAW);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
    // glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints2, GL_STATIC_DRAW);
    
    // glGenBuffers(1, &_indexBuffer);
    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * NUM_OF_ALL_INDICES, _vertexPtr, GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Vertex) * _numberOfPoints, _historyPoints, GL_STATIC_DRAW);
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
    
    glDrawArrays(GL_POINTS, 0 , _numberOfPoints/* NUM_OF_ALL_INDICES */ );
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
