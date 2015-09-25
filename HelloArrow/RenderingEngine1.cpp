//
//  RenderingEngine1.cpp
//  Dimensions
//
//  Created by fminor on 2/27/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#include <stdio.h>

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include "IRenderingEngine.hpp"

static const float gRevolutionsPerSecond = 0.1;

class RenderingEngine1 : public IRenderingEngine
{
public:
    RenderingEngine1();
    
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
};

IRenderingEngine* createRenderer1()
{
    return new RenderingEngine1();
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

RenderingEngine1::RenderingEngine1()
{
    glGenRenderbuffersOES(1, &m_renderBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, m_renderBuffer);
}

void RenderingEngine1::initialize(int width, int height)
{
    glGenFramebuffersOES(1, &m_frameBuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, m_frameBuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, m_renderBuffer);
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    
    const float _max_x = 2;
    const float _max_y = 3;
    glOrthof(-_max_x, _max_x, -_max_y, _max_y, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    
    onRotate(DeviceOrientationPortrait);
    m_currentAngle = m_desireAngle;
}

void RenderingEngine1::render() const
{
    glClearColor(0.5f, 0.5f, 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glPushMatrix();
    glRotatef(m_currentAngle, 0, 0, 1);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, sizeof(Vertex), &vertices[0].position[0]);
    glColorPointer(4, GL_FLOAT, sizeof(Vertex), &vertices[0].color[0]);
    GLsizei _vertexCount = sizeof(vertices) / sizeof(Vertex);
    glDrawArrays(GL_TRIANGLES, 0, _vertexCount);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glPopMatrix();
}

void RenderingEngine1::onRotate(DeviceOrientation newOrietation)
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

void RenderingEngine1::updateAnimation(float timestamp)
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










