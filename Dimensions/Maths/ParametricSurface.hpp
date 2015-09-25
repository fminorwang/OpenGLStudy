//
//  ParametricSurface.hpp
//  TouchCone
//
//  Created by fminor on 3/16/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef TouchCone_ParametricSurface_hpp
#define TouchCone_ParametricSurface_hpp

#import "Interfaces.hpp"

struct ParametricInterval {
    ivec2 divisions;
    vec2 upperBound;
    vec2 textureCount;
};

class ParametricSurface : public ISurface
{
private:
    vec2 computeDomain(float i, float j) const;
    vec2 m_upperBound;
    ivec2 m_slices;
    ivec2 m_divisions;
    vec2 m_textureCount;
    
public:
    int getVertexCount() const;
    int getLineIndexCount() const;
    int getTriangleIndexCount() const;
    void generateVertices(vector<float>& vertices, unsigned char flags) const;
    void generateLineIndices(vector<unsigned short>& indices) const;
    void generateTriangleIndices(vector<unsigned short> & indices) const;
    
protected:
    void setInterval(const ParametricInterval &interval);
    virtual vec3 evaluate(const vec2 & domain) const = 0;
    virtual bool invertNormal(const vec2 & domain) const { return false; }
};

#endif
