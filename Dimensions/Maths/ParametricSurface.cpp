//
//  ParametricSurface.cpp
//  TouchCone
//
//  Created by fminor on 3/18/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#include <stdio.h>
#include "ParametricSurface.hpp"

void ParametricSurface::setInterval(const ParametricInterval &interval)
{
    m_upperBound = interval.upperBound;
    m_divisions = interval.divisions;
    m_slices = m_divisions - ivec2(2, 1);
    m_textureCount = interval.textureCount;
}

int ParametricSurface::getVertexCount() const
{
    return m_divisions.x * m_divisions.y;
}

int ParametricSurface::getLineIndexCount() const
{
    return 4 * m_slices.x * m_slices.y;
}

int ParametricSurface::getTriangleIndexCount() const
{
    return 6 * m_slices.x * m_slices.y;
}

vec2 ParametricSurface::computeDomain(float i, float j) const
{
    return vec2(i * m_upperBound.x / m_slices.x,
                j * m_upperBound.y / m_slices.y);
}

void ParametricSurface::generateVertices(vector<float> &vertices, unsigned char flags) const
{
    int _floatsPerVertex = 3;
    if ( flags & VertexFlagsNormal ) {
        _floatsPerVertex += 3;
    }
    if ( flags & VertexFlagsTexCoords ) {
        _floatsPerVertex += 2;
    }
    vertices.resize(getVertexCount() * _floatsPerVertex);
    float* _attribute = (float *)&vertices[0];
    for ( int j = 0 ; j < m_divisions.y ; j++ ) {
        for ( int i = 0 ; i < m_divisions.x ; i++ ) {
            // 计算位置坐标
            vec2 domain = computeDomain(i, j);
            vec3 range = evaluate(domain);
            _attribute = range.write(_attribute);
            
            // 计算法线
            if ( flags & VertexFlagsNormal ) {
                float s = i, t = j;
                if ( i == 0 ) {
                    s += 0.01f;
                }
                if ( i == m_divisions.x - 1 ) {
                    s -= 0.01f;
                }
                if ( j == 0 ) {
                    t += 0.01f;
                }
                if ( j == m_divisions.y - 1 ) {
                    t -= 0.01f;
                }
                
                vec3 p = evaluate(computeDomain(s, t));
                vec3 u = evaluate(computeDomain(s + 0.01f, t)) - p;
                vec3 v = evaluate(computeDomain(s, t + 0.01f)) - p;
                vec3 _normal = u.cross(v).normalized();
                if ( invertNormal(domain) ) {
                    _normal = -_normal;
                }
                _attribute = _normal.write(_attribute);
            }
            
            // 计算纹理
            if ( flags & VertexFlagsTexCoords ) {
                float s = m_textureCount.x * i / m_slices.x;
                float t = m_textureCount.y * j / m_slices.y;
                _attribute = vec2(s, t).write(_attribute);
            }
        }
    }
}

void ParametricSurface::generateLineIndices(vector<unsigned short> &indices) const
{
    indices.resize(getLineIndexCount());
    vector<unsigned short>::iterator index = indices.begin();
    for ( int j = 0, vertex = 0 ; j < m_slices.y ; j++ ) {
        for ( int i = 0 ; i < m_slices.x ; i++ ) {
            int _next = ( i + 1 ) % m_divisions.x;
            *index++ = vertex + i;
            *index++ = vertex + _next;
            *index++ = vertex + i;
            *index++ = vertex + i + m_divisions.x;
        }
        vertex += m_divisions.x;
    }
}

void ParametricSurface::generateTriangleIndices(vector<unsigned short> &indices) const
{
    indices.resize(getTriangleIndexCount());
    vector<unsigned short>::iterator index = indices.begin();
    for ( int j = 0, vertex = 0 ; j < m_slices.y ; j++ ) {
        for ( int i = 0 ; i < m_slices.x ; i++ ) {
            int _next = ( i + 1 ) % m_divisions.x;
            *index++ = vertex + i;
            *index++ = vertex + _next;
            *index++ = vertex + i + m_divisions.x;
            *index++ = vertex + _next;
            *index++ = vertex + _next + m_divisions.x;
            *index++ = vertex + i + m_divisions.x;
        }
        vertex += m_divisions.x;
    }

}