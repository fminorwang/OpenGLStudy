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
#include "IRenderingEngine.hpp"
#include "Quaternion.hpp"
#include "Matrix.hpp"
#include <vector>

#include <iostream>

#define STRINGIFY(A)    #A
#include "Simple.vert"
#include "Simple.frag"

using namespace std;

struct Vertex {
    vec3 position;
    vec4 color;
};

struct Animation {
    Quaternion start;
    Quaternion end;
    Quaternion current;
    float elapsed;
    float duration;
};

static const float AnimationDuration = 3;

class RenderingEngine2 : public IRenderingEngine
{
public:
    RenderingEngine2();
    
    void initialize(int width, int height);
    void render() const;
    void updateAnimation(float timestamp);
    void onRotate(DeviceOrientation newOrietation);
    
private:
    vector<Vertex> m_cone;
    vector<Vertex> m_disk;
    Animation m_animation;
    
    GLuint m_frameBuffer;
    GLuint m_colorRenderBuffer;
    GLuint m_depthRenderBuffer;
    GLuint m_program;
    
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

RenderingEngine2::RenderingEngine2()
{
    glGenRenderbuffers(1, &m_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_colorRenderBuffer);
}

void RenderingEngine2::initialize(int width, int height)
{
    const float _coneRadius = 0.5f;
    const float _coneHeight = 1.866f;
    const int _coneSlices = 200;
    {
        m_cone.resize(( _coneSlices + 1 ) * 2);
        vector<Vertex>::iterator _vertex = m_cone.begin();
        const float _dtheta = m_2_pi / _coneSlices;
        for ( float _theta = 0 ; _vertex != m_cone.end(); _theta += _dtheta ) {
            float _brightness = abs(sin(_theta));
            vec4 color(_brightness, _brightness, _brightness, 1);
            
            _vertex->position = vec3(0, 1, 0);
            _vertex->color = color;
            _vertex++;
            
            _vertex->position.x = _coneRadius * cos(_theta);
            _vertex->position.y = 1 - _coneHeight;
            _vertex->position.z = _coneRadius * sin(_theta);
            _vertex->color = color;
            _vertex++;
        }
    }
    
    {
        m_disk.resize(_coneSlices + 2);
        vector<Vertex>::iterator _vertex = m_disk.begin();
        _vertex->color = vec4(0.75, 0.75, 0.75, 1);
        _vertex->position.x = 0;
        _vertex->position.y = 1 - _coneHeight;
        _vertex->position.z = 0;
        _vertex++;
        
        const float _dtheta = m_2_pi;
        for ( float _theta = 0 ; _vertex != m_disk.end() ; _theta += _dtheta ) {
            _vertex->color = vec4(0.75, 0.75, 0.75, 1);
            _vertex->position.x = _coneRadius * cos(_theta);
            _vertex->position.y = 1 - _coneHeight;
            _vertex->position.z = _coneRadius * sin(_theta);
            _vertex++;
        }
    }
    
    glGenRenderbuffers(1, &m_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
    glGenFramebuffers(1, &m_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, m_frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, m_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, m_colorRenderBuffer);
    
    glViewport(0, 0, width, height);
    glEnable(GL_DEPTH_TEST);
    
    m_program = _buildProgram(simpleVertexShader, simpleFragmentShader);
    GLint _projectionUniform = glGetUniformLocation(m_program, "projection");
    mat4 _projectionMatrix = mat4::frustum(-1.6f, 1.6f, -2.4, 2.4, 5, 10);
    glUniformMatrix4fv(_projectionUniform, 1, 0, _projectionMatrix.pointer());
}

void RenderingEngine2::render() const
{
    GLuint _positionSlot = glGetAttribLocation(m_program, "position");
    GLuint _colorSlot = glGetAttribLocation(m_program, "sourceColor");
    glClearColor(0.5f, 0.5f, 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    mat4 _rotation(m_animation.current.toMatrix());
    mat4 _translation = mat4::translate(0.0f, 0.0, -7.0f);
    
    GLuint _modelViewUniform = glGetUniformLocation(m_program, "modelView");
    mat4 _modelViewMatrix = _rotation * _translation;
    glUniformMatrix4fv(_modelViewUniform, 1, 0, _modelViewMatrix.pointer());
    
    {
        GLsizei _stride = sizeof(Vertex);
        const GLvoid *pCoords = &m_cone[0].position.x;
        const GLvoid *pColors = &m_cone[0].color.x;
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, _stride, pCoords);
        glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, _stride, pColors);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)m_cone.size());
    }
    
    {
        GLsizei _stride = sizeof(Vertex);
        const GLvoid *pCoords = &m_disk[0].position.x;
        const GLvoid *pColors = &m_disk[0].color.x;
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, _stride, pCoords);
        glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, _stride, pColors);
        glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)m_disk.size());
    }
    
    glDisableVertexAttribArray(_positionSlot);
    glDisableVertexAttribArray(_colorSlot);
}

void RenderingEngine2::onRotate(DeviceOrientation newOrietation)
{
    vec3 _direction;
    switch ( newOrietation ) {
        case DeviceOrientationUnknown:
        case DeviceOrientationPortrait:
            _direction = vec3(0, 1, 0);
            break;
        case DeviceOrientationPortraitUpsideDown:
            _direction = vec3(0, -1, 0);
            break;
        case DeviceOrientationFaceDown:
            _direction = vec3(0, 0, -1);
            break;
        case DeviceOrientationFaceUp:
            _direction = vec3(0, 0, 1);
            break;
        case DeviceOrientationLandscapeLeft:
            _direction = vec3(1, 0, 0);
            break;
        case DeviceOrientationLandscapeRight:
            _direction = vec3(-1, 0, 0);
            break;
            
        default:
            break;
    }
    m_animation.elapsed = 0;
    m_animation.start = m_animation.current = m_animation.end;
    m_animation.end = Quaternion::createFromVectors(vec3(0, 1, 0), _direction);
}

void RenderingEngine2::updateAnimation(float timeStep)
{
    if ( m_animation.current == m_animation.end ) {
        return;
    }
    
    m_animation.elapsed += timeStep;
    if ( m_animation.elapsed >= AnimationDuration ) {
        m_animation.current = m_animation.end;
    } else {
        float mu = m_animation.elapsed / AnimationDuration;
        m_animation.current  = m_animation.start.slerp(mu, m_animation.end);
    }
}


