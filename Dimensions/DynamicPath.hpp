//
//  DynamicPath.hpp
//  Dimensions
//
//  Created by fminor on 04/01/2017.
//  Copyright © 2017 fminor. All rights reserved.
//

#ifndef DynamicPath_hpp
#define DynamicPath_hpp

#include "ParametricEquations.hpp"
#include <OpenGLES/gltypes.h>
#include <stdio.h>

struct DynamicVertex {
    vec3 position;
    vec3 normal;
};

class DynamicPath
{
public:
    vec3 m_origin;
    vec3 m_current;
    
    float m_pipeRadius;
    int m_pipeCount;
    
    vector<DynamicVertex> m_vertices;
    vector<unsigned short> m_indices;
    
    // initializer
    DynamicPath(float radius, vec3 origin, int pipeCount = 10): m_pipeRadius(radius), m_pipeCount(pipeCount), m_origin(origin) {
        m_vertices = vector<DynamicVertex>();
        m_indices = vector<unsigned short>();
        m_current = origin;
    }
    
    // util: create next point
    virtual vec3 nextPoint(float dt) = 0;
    
    // util: create next vertices
    virtual vector<DynamicVertex> createPathVertices(vec3 lastPoint, vec3 currentPoint, float radius) {
        vector<DynamicVertex> _arr = vector<DynamicVertex>();
        return _arr;
    }
    
    // util: create next indices
    virtual vector<unsigned short> createPathIndices() {
        vector<unsigned short> _arr = vector<unsigned short>();
        size_t _pointCount = m_vertices.size() / m_pipeCount;
        if ( _pointCount < 2 ) {
            return _arr;
        }
        
        unsigned short _point = ( _pointCount - 2 ) * m_pipeCount;
        for ( int i = 0 ; i < m_pipeCount ; i++ ) {
            _arr.push_back(_point + i);
            _arr.push_back(_point + ( i + 1 ) % m_pipeCount);
            _arr.push_back(_point + i + m_pipeCount);
            
            _arr.push_back(_point + ( i + 1 ) % m_pipeCount);
            _arr.push_back(_point + i + m_pipeCount);
            _arr.push_back(_point + m_pipeCount + ( i + 1 ) % m_pipeCount);
        }
        return _arr;
    }
    
    // append next point
    virtual void appendNext(float dt) {
        vec3 _next = nextPoint(dt);
        vector<DynamicVertex> _newPoints = createPathVertices(m_current, _next, m_pipeRadius);
        m_vertices.insert(m_vertices.end(), _newPoints.begin(), _newPoints.end());
        m_current = _next;
        
        vector<unsigned short> _newIndices = createPathIndices();
        m_indices.insert(m_indices.end(), _newIndices.begin(), _newIndices.end());
    }
};

class OrderTwoDynamicPath: public DynamicPath
{
private:
    float m_a;
    float m_b;
    float m_c;
    float m_d;
    
public:
    OrderTwoDynamicPath(float a, float b, float c, float d, float r, vec3 origin)
    : m_a(a), m_b(b), m_c(c), m_d(d), DynamicPath(r, origin) {
        float _dt = -0.01;
        vec3 _prev = nextPoint(_dt);
        vector<DynamicVertex> _starts = createPathVertices(_prev, m_origin, m_pipeRadius);
        m_vertices.insert(m_vertices.end(), _starts.begin(), _starts.end());
    }
    
    vec3 nextPoint(float dt) {
        float _dx = ( m_a * m_current.x + m_b * m_current.y ) * dt;
        float _dy = ( m_c * m_current.x + m_d * m_current.y ) * dt;
        vec3 _next = m_current + vec3(_dx, _dy, 0.0);
        return _next;
    }
    
    vector<DynamicVertex> createPathVertices(vec3 lastPoint, vec3 currentPoint, float radius) {
        vector<DynamicVertex> _arr = vector<DynamicVertex>();
        
        // 管道上的点
        float x1 = currentPoint.x;
        float y1 = currentPoint.y;
        float x0 = lastPoint.x;
        float y0 = lastPoint.y;
        
        float _sqrt = sqrtf( ( x1 - x0 ) * ( x1 - x0) + ( y1 - y0 ) * ( y1 - y0 ) );
        for ( int i = 0 ; i < m_pipeCount ; i++ ) {
            DynamicVertex _vertex = {vec3(0, 0, 0), vec3(0, 0, 0) };
            _vertex.position.x = x1 - m_pipeRadius * sin( 2 * M_PI * i / m_pipeCount ) * ( y1 - y0 ) / _sqrt;
            _vertex.position.y = y1 + m_pipeRadius * sin( 2 * M_PI * i / m_pipeCount ) * ( x1 - x0 ) / _sqrt;
            _vertex.position.z = m_pipeRadius * cos( 2 * M_PI * i / m_pipeCount );
            
            _vertex.normal.x = _vertex.position.x - x1;
            _vertex.normal.y = _vertex.position.y - y1;
            _vertex.normal.z = _vertex.position.z - 0;
            
            float _length = sqrtf( _vertex.normal.x * _vertex.normal.x
                                  + _vertex.normal.y * _vertex.normal.y
                                  + _vertex.normal.z * _vertex.normal.z );
            _vertex.normal.x = _vertex.normal.x / _length;
            _vertex.normal.y = _vertex.normal.y / _length;
            _vertex.normal.z = _vertex.normal.z / _length;
            
            _arr.insert(_arr.end(), _vertex);
        }
        return _arr;
    }
};

#endif /* DynamicPath_hpp */
