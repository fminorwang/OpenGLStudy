//
//  ParametricCurve.h
//  ModelView
//
//  Created by fminor on 4/3/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef __ModelView__ParametricCurve__
#define __ModelView__ParametricCurve__

#include <stdio.h>
#include "Interfaces.hpp"

struct ParametricInterval2D {
    int divisions;
    float upperBound;
};

class ParametricCurve : public ICurve
{
private:
    float computeDomain(int i) const;
    float m_upperBound;
    int m_slices;
    int m_divisions;
    
public:
    int getVertexCount() const;
    int getLineIndexCount() const;
    
    void generateVertices(vector<float>& vertices, unsigned char flags) const;
    void generateLineIndices(vector<unsigned short>& indices) const;
    
protected:
    void setInterval(const ParametricInterval2D &interval);
    virtual vec3 evaluate(const float domain) const = 0;
};


#endif
