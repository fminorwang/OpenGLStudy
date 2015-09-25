//
//  ParametricEquations.hpp
//  TouchCone
//
//  Created by fminor on 3/18/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef TouchCone_ParametricEquations_hpp
#define TouchCone_ParametricEquations_hpp

#include "ParametricSurface.hpp"
#include "ParametricCurve.hpp"

class Cone : public ParametricSurface
{
private:
    float m_height;
    float m_radius;
    
public:
    Cone(float height, float radius) : m_height(height), m_radius(radius)
    {
        ParametricInterval _interval = { ivec2(20, 20), vec2(2 * m_pi, 1), vec2(30, 30) };
        setInterval(_interval);
    }
    
    vec3 evaluate(const vec2 & domain) const
    {
        float u = domain.x;
        float v = domain.y;
        float x = m_radius * ( 1 - v ) * cos(u);
        float y = m_height * ( v - 0.5f );
        float z = m_radius * ( 1 - v ) * (-sin(u));
        return vec3(x, y, z);
    }
};

class Sphere : public ParametricSurface
{
private:
    float m_radius;
    
public:
    Sphere(float radius) : m_radius(radius)
    {
        ParametricInterval _interval = { ivec2(40, 40), vec2(m_pi, m_pi * 2), vec2(20, 35) };
        setInterval(_interval);
    }
    
    vec3 evaluate(const vec2 & domain) const
    {
        float u = domain.x;
        float v = domain.y;
        float x = m_radius * sin(u) * cos(v);
        float y = - m_radius * cos(u);
        float z = m_radius * sin(u) * sin(v);
        return vec3(x, y, z);
    }
};

class Torus : public ParametricSurface
{
private:
    float m_r;
    float m_R;
    
public:
    Torus(float r, float R) : m_r(r), m_R(R)
    {
        ParametricInterval _interval = { ivec2(100, 20), vec2(m_pi * 2, m_pi * 2), vec2(30, 30) };
        setInterval(_interval);
    }
    
    vec3 evaluate(const vec2 & domain) const
    {
        float u = domain.x;
        float v = domain.y;
        float x = ( m_R + m_r * cos(v) ) * cos(u);
        float z = m_r * sin(v);
        float y = ( m_R + m_r * cos(v) ) * sin(u);
        return vec3(x, y, z);
    }
};

class Hyperbolic : public ParametricSurface
{
public:
    Hyperbolic()
    {
        ParametricInterval _interval = { ivec2(50, 50), vec2(50, 50), vec2(30, 30) };
        setInterval(_interval);
    }
    
    vec3 evaluate(const vec2 & domain) const
    {
        float u = domain.x / 20.f - 1.25f;
        float v = domain.y / 20.f - 1.25f;
        
        float x = u;
        float z = v;
        float y = x * x / 2 - z * z / 2;
        return vec3(x, y, z);
    }
};

class Elipsebolic : public ParametricSurface
{
public:
    Elipsebolic(float a, float b, float c) : m_a(a), m_b(b), m_c(c)
    {
        ParametricInterval _interval = { ivec2(40, 40), vec2(m_pi, m_pi * 2), vec2(30, 30) };
        setInterval(_interval);
    }
    
    vec3 evaluate(const vec2 & domain) const
    {
        float u = domain.x;
        float v = domain.y;
        
        float x = m_a * sin(u) * cos(v);
        float y = m_b * cos(u);
        float z = m_c * sin(u) * sin(v);
        
        return vec3(x, y, z);
    }
    
private:
    float m_a;
    float m_b;
    float m_c;
};

class Mobius : public ParametricSurface
{
public:
    Mobius()
    {
        ParametricInterval _interval = { ivec2(40, 40), vec2( 2 * m_pi, 2), vec2(30, 30) };
        setInterval(_interval);
    }
    
    vec3 evaluate(const vec2 & domain) const
    {
        float u = domain.x;
        float v = domain.y - 1;
        
        float x = ( 1 + v / 2  * cos( u / 2 )) * cos(u);
        float z = ( 1 + v / 2  * cos( u / 2 )) * sin(u);
        float y = v / 2 * sin( u / 2);
        
        return vec3(x, y, z);
    }
};

// 抛物线
class Parabolic : public ParametricCurve
{
private:
    float m_a;
    float m_b;
    float m_c;
    
public:
    Parabolic(float a, float b, float c) : m_a(a), m_b(b), m_c(c)
    {
        ParametricInterval2D _interval = { 100, 1.0f };
        setInterval(_interval);
    }
    
    vec3 evaluate(const float domain) const
    {
        float x = domain;
        float y = m_a * x * x + m_b * x + m_c;
        
        return vec3(x, y, 0.0);
    }
};

#endif
