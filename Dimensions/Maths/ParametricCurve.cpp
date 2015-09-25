//
//  ParametricCurve.cpp
//  ModelView
//
//  Created by fminor on 4/3/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#include "ParametricCurve.hpp"

void ParametricCurve::setInterval(const ParametricInterval2D &interval)
{
    m_upperBound = interval.upperBound;
    m_divisions = interval.divisions;
    m_slices = m_divisions - 1;
}

int ParametricCurve::getVertexCount() const
{
    return m_divisions;
}

int ParametricCurve::getLineIndexCount() const
{
    return 2 * m_slices;
}

float ParametricCurve::computeDomain(int i) const
{
    return i * m_upperBound / m_slices;
}

void ParametricCurve::generateVertices(vector<float> &vertices, unsigned char flags) const
{
    int _floatsPerVertex = 3;
    vertices.resize(getVertexCount() * _floatsPerVertex);
    float* _attribute = (float *)&vertices[0];
    for ( int i = 0 ; i < m_divisions ; i++ ) {
        // 计算位置坐标
        float _domain = computeDomain(i);
        vec3 _range = this->evaluate(_domain);
        _attribute = _range.write(_attribute);
    }
}

void ParametricCurve::generateLineIndices(vector<unsigned short> &indices) const
{
    indices.resize(getLineIndexCount());
    vector<unsigned short>::iterator index = indices.begin();
    for ( int i = 0 ; i < m_slices ; i++ ) {
        *index++ = i;
        *index++ = i + 1;
    }
}