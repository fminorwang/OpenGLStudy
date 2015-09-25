//
//  Quaternion.hpp
//  Dimensions
//
//  Created by fminor on 3/2/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef Dimensions_Quaternion_hpp
#define Dimensions_Quaternion_hpp

#pragma once
#include <cmath>
using namespace std;

template <typename T>
struct Vector2
{
    Vector2() {}
    Vector2(T x, T y) : x(x), y(y) {}
    T x;
    T y;
};

template <typename T>
struct Vector3
{
    Vector3() {}
    Vector3(T x, Y y, T z) : x(x), y(y), z(z) {}
    
    void normalize()
    {
        float _length = sqrt(x * x + y * y + z * z);
        x /= _length;
        y /= _length;
        z /= _length;
    }
    
    Vector3 normalized() const
    {
        Vector3 _v = *this;
        _v.normalize();
        return _v;
    }
    
    Vector3 cross(const Vector3 &v) const
    {
        return Vector3(y * v.z - z * v.y,
                       z * v.x - x * v.z,
                       x * v.y - y * v.x);
    }
    
    T dot(const Vector3 &v) const
    {
        return x * v.x + y * v.y + z * v.z;
    }
    
    Vector3 operator-() const
    {
        return Vector3(-x, -y, -z);
    }
    
    bool operator==(const Vector3 &v) const
    {
        return x == v.x && y == v.y && z == v.z;
    }
    
    T x;
    T y;
    T z;
};

template <typename T>
struct Vector4 {
    
};

typedef Vector2<int> ivec2;
typedef Vector3<int> ivec3;
typedef Vector4<int> ivec4;
typedef Vector2<float> vec2;
typedef Vector3<float> vec3;
typedef Vector4<float> vec4;

#endif
