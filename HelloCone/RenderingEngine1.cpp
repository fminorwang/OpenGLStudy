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
#include "Quaternion.hpp"
#include <vector>

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

class RenderingEngine1 : public IRenderingEngine
{
public:
    RenderingEngine1();
    
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
};

IRenderingEngine* createRenderer1()
{
    return new RenderingEngine1();
}

RenderingEngine1::RenderingEngine1()
{
    glGenRenderbuffersOES(1, &m_colorRenderBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, m_colorRenderBuffer);
}

void RenderingEngine1::initialize(int width, int height)
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
    
    glGenRenderbuffersOES(1, &m_depthRenderBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, m_depthRenderBuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, width, height);
    
    glGenFramebuffersOES(1, &m_frameBuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, m_frameBuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, m_colorRenderBuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, m_depthRenderBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, m_colorRenderBuffer);
    
    glViewport(0, 0, width, height);
    glEnable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);
    glOrthof(-1.6f, 1.6, -2.4, 2.4, 5, 10);
    glMatrixMode(GL_MODELVIEW);
    glTranslatef(0, 0, -7);
}

void RenderingEngine1::render() const
{
    glClearColor(0.5f, 0.5f, 0.5f, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glPushMatrix();

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    
    mat4 _rotation(m_animation.current.toMatrix());
    glMultMatrixf(_rotation.pointer());
    
    glVertexPointer(3, GL_FLOAT, sizeof(Vertex), &m_cone[0].position.x);
    glColorPointer(4, GL_FLOAT, sizeof(Vertex), &m_cone[0].color.x);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (int)(m_cone.size()));
    
    glVertexPointer(3, GL_FLOAT, sizeof(Vertex), &m_disk[0].position.x);
    glColorPointer(4, GL_FLOAT, sizeof(Vertex), &m_disk[0].color.x);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (int)(m_disk.size()));
    
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glPopMatrix();
}

void RenderingEngine1::onRotate(DeviceOrientation newOrietation)
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

void RenderingEngine1::updateAnimation(float timeStep)
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










