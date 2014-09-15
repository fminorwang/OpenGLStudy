//
//  VertexShaderCompiler.m
//  Dimensions
//
//  Created by fminor on 9/7/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import "VertexShaderCompiler.h"
#import <GLKit/GLKit.h>

#define VERTEX_SHADER_FILE_EXTEND_NAME              @"vsh"
#define FREGMENT_SHADER_FILE_EXTEND_NAME            @"fsh"

static VertexShaderCompiler *_gVertexShaderCompiler;

@implementation VertexShaderCompiler

+ (VertexShaderCompiler *)sharedCompiler
{
    if ( _gVertexShaderCompiler == nil ) {
        _gVertexShaderCompiler = [[VertexShaderCompiler alloc] init];
    }
    return _gVertexShaderCompiler;
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShadersWithProgram:(GLuint *)program
{
    return [self loadShadersWithFileName:@"Shader" attributes:nil uniforms:nil program:program];
}

- (BOOL)loadShadersWithFileName:(NSString *)fileName
                     attributes:(NSDictionary *)attributes uniforms:(NSDictionary *)uniforms
                        program:(GLuint *)program
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    *program = glCreateProgram();
    
#pragma mark file names
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:fileName
                                                         ofType:VERTEX_SHADER_FILE_EXTEND_NAME];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fileName
                                                         ofType:FREGMENT_SHADER_FILE_EXTEND_NAME];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(*program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
#pragma warning variable names
    for ( NSString *_key in [attributes allKeys] ) {
        GLint _keyType = [_key intValue];
        const char *_attributeName = [[attributes objectForKey:_key] UTF8String];
        glBindAttribLocation(*program, _keyType, _attributeName);
    }

    // Link program.
    if (![self linkProgram:*program]) {
        NSLog(@"Failed to link program: %d", *program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(*program);
            program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    // 设置全局变量
#pragma warning how to set variables?
    // uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewMatrix");
    // uniforms[UNIFORM_PROJECTION_MATRIX] = glGetUniformLocation(program, "projectionMatrix");
    
    for ( NSString *_key in uniforms.allKeys ) {
        GLuint *_ptr = [[uniforms objectForKey:_key] pointerValue];
        *_ptr = glGetUniformLocation(*program, [_key UTF8String]);
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(*program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(*program, fragShader);
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
