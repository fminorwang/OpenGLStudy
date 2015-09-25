//
//  RenderingEngine2.cpp
//  Dimensions
//
//  Created by fminor on 2/28/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#include <stdio.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <cmath>
#include <iostream>
#include "IRenderingEngine.hpp"

#define STRINGIFY(A)    #A
#include "Simple.vert"
#include "Simple.frag"

static const float gRevolutionsPerSecond = 0.1;

class RenderingEngine2 : public IRenderingEngine
{
public:
    RenderingEngine2();
    
    void initialize(int width, int height);
    void render() const;
    void updateAnimation(float timestamp);
    void onRotate(DeviceOrientation newOrietation);
    
    float _rotationDirection()
    {
        float _delta = m_desireAngle - m_currentAngle;
        if ( _delta == 0 ) {
            return 0;
        }
        bool _counterclockwise = ( _delta > 0 && _delta <= 180 ) || ( _delta < - 180 );
        return _counterclockwise ? 1 : -1;
    }
    
private:
    float _rotationDirection() const;
    float m_desireAngle;
    
    float m_currentAngle;
    GLuint m_frameBuffer;
    GLuint m_renderBuffer;
    
    GLuint m_simpleProgram;

    void _applyOrtho(float maxX, float maxY) const
    {
        float a = 1.0f / maxX;
        float b = 1.0f / maxY;
        float _ortho[16] = {
            a, 0, 0, 0,
            0, b, 0, 0,
            0, 0, -1, 0,
            0, 0, 0, 1
        };
        GLint _projectionUniform = glGetUniformLocation(m_simpleProgram, "Projection");
        glUniformMatrix4fv(_projectionUniform, 1, 0, &_ortho[0]);
    }
    
    void _applyRotation(float degrees) const
    {
        float _radians = degrees * 3.14159f / 180.f;
        float s = std::sin(_radians);
        float c = std::cos(_radians);
        float _zRotation[16] = {
            c, s, 0, 0,
            -s, c, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        };
        GLint _modelViewUniform = glGetUniformLocation(m_simpleProgram, "Modelview");
        glUniformMatrix4fv(_modelViewUniform, 1, 0, &_zRotation[0]);
    }
    
    GLuint _buildShader(const char* source, GLenum shaderType) const
    {
        GLuint _shaderHandle = glCreateShader(shaderType);
        glShaderSource(_shaderHandle, 1, &source, 0);
        glCompileShader(_shaderHandle);
        GLint _compileSuccess;
        glGetShaderiv(_shaderHandle, GL_COMPILE_STATUS, &_compileSuccess);
        if ( _compileSuccess == GL_FALSE ) {
            GLchar _messages[256];
            glGetShaderInfoLog(_shaderHandle, sizeof(_messages), 0, &_messages[0]);
            std::cout << _messages;
            exit(1);
        }
        return _shaderHandle;
    }
    
    GLuint _buildProgram(const char* vShader, const char* fShader) const
    {
        GLuint _vertexShader = _buildShader(vShader, GL_VERTEX_SHADER);
        GLuint _fragmentShader = _buildShader(fShader, GL_FRAGMENT_SHADER);
        GLuint _programHandle = glCreateProgram();
        glAttachShader(_programHandle, _vertexShader);
        glAttachShader(_programHandle, _fragmentShader);
        glLinkProgram(_programHandle);
        GLint _linkSuccess;
        glGetProgramiv(_programHandle, GL_LINK_STATUS, &_linkSuccess);
        if ( _linkSuccess == GL_FALSE ) {
            GLchar _messages[256];
            glGetProgramInfoLog(_programHandle, sizeof(_messages), 0, &_messages[0]);
            std::cout << _messages;
            exit(1);
        }
        return _programHandle;
    }
};

IRenderingEngine* createRenderer2()
{
    return new RenderingEngine2();
}

struct Vertex {
    float position[2];
    float color[4];
};

const Vertex vertices[] = {
    { { -0.5, -0.866 }, { 1, 1, 0.5f, 1 } },
    { { 0.5, -0.866 },  { 1, 1, 0.5f, 1 } },
    { { 0, 1 },         { 1, 1, 0.5f, 1 } },
    { { -0.5, -0.866 }, { 0.5f, 0.5f, 0.5f } },
    { { 0.5, -0.866 },  { 0.5f, 0.5f, 0.5f } },
    { { 0, -0.4f },     { 0.5f, 0.5f, 0.5f } },
};

RenderingEngine2::RenderingEngine2()
{
    glGenRenderbuffers(1, &m_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_renderBuffer);
}

void RenderingEngine2::initialize(int width, int height)
{
    glGenFramebuffers(1, &m_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_renderBuffer);
    glViewport(0, 0, width, height);
    m_simpleProgram = _buildProgram(simpleVertexShader, simpleFragmentShader);
    glUseProgram(m_simpleProgram);
    _applyOrtho(2, 3);
    
    onRotate(DeviceOrientationPortrait);
    m_currentAngle = m_desireAngle;
}

void RenderingEngine2::render() const
{
    glClearColor(0.5f, 0.5f, 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    _applyRotation(m_currentAngle);
    GLuint _positionSlot = glGetAttribLocation(m_simpleProgram, "position");
    GLuint _colorSlot = glGetAttribLocation(m_simpleProgram, "sourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    GLsizei _stride = sizeof(Vertex);
    const GLvoid* _pCoords = &vertices[0].position[0];
    const GLvoid* _pColors = &vertices[0].color[0];
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, _stride, _pCoords);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, _stride, _pColors);
    GLsizei _vertexCount = sizeof(vertices) / sizeof(Vertex);
    glDrawArrays(GL_TRIANGLES, 0, _vertexCount);
    glDisableVertexAttribArray(_positionSlot);
    glDisableVertexAttribArray(_colorSlot);
}

void RenderingEngine2::onRotate(DeviceOrientation newOrietation)
{
    float _angle = 0;
    switch ( newOrietation ) {
        case DeviceOrientationLandscapeLeft:
            _angle = 270;
            break;
            
        case DeviceOrientationPortraitUpsideDown:
            _angle = 180;
            break;
            
        case DeviceOrientationLandscapeRight:
            _angle = 90;
            
        default:
            break;
    }
    m_desireAngle = _angle;
}

void RenderingEngine2::updateAnimation(float timestamp)
{
    float _direction = _rotationDirection();
    if ( _direction == 0 ) {
        return;
    }
    
    float _degrees = timestamp * 360 * gRevolutionsPerSecond;
    m_currentAngle += _degrees * _direction;
    
    if ( m_currentAngle >= 360 ) {
        m_currentAngle -= 360;
    } else if ( m_currentAngle < 0 ) {
        m_currentAngle += 360;
    }
    
    if ( _rotationDirection() != _direction ) {
        m_currentAngle = m_desireAngle;
    }
}
