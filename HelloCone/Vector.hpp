//
//  Vector.hpp
//  Dimensions
//
//  Created by fminor on 3/2/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef Dimensions_Vector_hpp
#define Dimensions_Vector_hpp

#include <cmath>
using namespace std;

const float m_pi = 4 * atan(1.0f);
const float m_2_pi = 2 * m_pi;

template <typename T>
struct Vector2
{
    Vector2() {}
    Vector2(T x, T y) : x(x), y(y) {}
    
    T dot(const Vector2 &v) const
    {
        return x * v.x + y * v.y;
    }
    
    Vector2 operator+(const Vector2 &v) const
    {
        return Vector2(x + v.x, y + v.y);
    }
    
    Vector2 operator-(const Vector2 &v) const
    {
        return Vector2(x - v.x, y - v.y);
    }
    
    void operator+=(const Vector2 &v)
    {
        *this = Vector2(x + v.x, y + v.y);
    }
    
    void operator-=(const Vector2 &v)
    {
        *this = Vector2(x - v.x, y - v.y);
    }
    
    Vector2 operator/(float s) const
    {
        return Vector2(x / s, y / s);
    }
    
    Vector2 operator*(float s) const
    {
        return Vector2(x * s, y * s);
    }
    
    void operator/=(float s)
    {
        *this = Vector2(x / s, y / s);
    }
    
    void operator*=(float s)
    {
        *this = Vector2(x * s, y * s);
    }
    
    void normalize()
    {
        float _s = 1.0f / this->length();
        x *= _s;
        y *= _s;
    }
    
    Vector2 normalized() const
    {
        Vector2 _newVector = *this;
        _newVector.normalize();
        return _newVector;
    }
    
    T lengthSquared() const
    {
        return x * x + y * y;
    }
    
    T length() const
    {
        return sqrt(lengthSquared());
    }
    
    const T* pointer() const
    {
        return &x;
    }
    
    operator Vector2<float>() const
    {
        return Vector2<float>(x, y);
    }
    
    bool operator==(const Vector2 &v) const
    {
        return x == v.x && y == v.y;
    }
    
    // 插值
    Vector2 lerp(float t, const Vector2 &v) const
    {
        return Vector2(( 1 - t ) * x + t * v.x,
                       ( 1 - t ) * y + t * v.y);
    }
    
    template <typename P>
    P* write(P *pData)
    {
        Vector2 *pVector = (Vector2 *)pData;
        *pVector++ = *this;
        return (P*)pVector;
    }
    
    T x;
    T y;
};

template <typename T>
struct Vector3
{
    Vector3() {}
    Vector3(T x, T y, T z) : x(x), y(y), z(z) {}
    
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
    
    Vector3 operator+(const Vector3 &v) const
    {
        return Vector3(x + v.x, y + v.y, z + v.z);
    }
    
    void operator+=(const Vector3 &v)
    {
        x += v.x;
        y += v.y;
        z += v.z;
    }
    
    Vector3 operator-(const Vector3 &v) const
    {
        return Vector3(x - v.x, y - v.y, z - v.z);
    }
    
    void operator-=(const Vector3 &v)
    {
        x -= v.x;
        y -= v.y;
        z -= v.z;
    }
    
    Vector3 operator-() const
    {
        return Vector3(-x, -y, -z);
    }
    
    Vector3 operator/(T s) const
    {
        return Vector3(x / s, y / s, z / s);
    }
    
    void operator/=(T s)
    {
        x /= s;
        y /= s;
        z /= s;
    }
    
    Vector3 operator*(T s) const
    {
        return Vector3(x * s, y * s, z * s);
    }
    
    void operator*(T s)
    {
        x *= s;
        y *= s;
        z *= s;
    }
    
    bool operator==(const Vector3 &v) const
    {
        return x == v.x && y == v.y && z == v.z;
    }
    
    void lerp(float t, const Vector3 &v) const
    {
        return Vector3(x * ( 1 - t ) + v.x * t,
                       y * ( 1 - t ) + v.y * t,
                       z * ( 1 - t ) + v.z * t);
    }
    
    const T* pointer() const
    {
        return &x;
    }
    
    template <typename P>
    P* write(P *pData)
    {
        Vector3 *pVector = (Vector3 *)pData;
        *pVector++ = *this;
        return (P*)pVector;
    }

    
    T x;
    T y;
    T z;
};

template <typename T>
struct Vector4 {
    T x;
    T y;
    T z;
    T w;
    
    Vector4() {}
    Vector4(T x, T y, T z, T w) : x(x), y(y), z(z), w(w) {}
    
    T dot(const Vector4 &v) const
    {
        return x * v.x + y * v.y + z * v.z + w * v.w;
    }
    
    Vector4 lerp(float t, const Vector4 &v) const
    {
        return Vector4(x * ( 1 - t ) + v.x * t,
                       y * ( 1 - t ) + v.y * t,
                       z * ( 1 - t ) + v.z * t,
                       w * ( 1 - t ) + v.w * t);
    }
    
    const T* pointer() const
    {
        return &x;
    }
};

typedef Vector2<bool> bvec2;

typedef Vector2<int> ivec2;
typedef Vector3<int> ivec3;
typedef Vector4<int> ivec4;

typedef Vector2<float> vec2;
typedef Vector3<float> vec3;
typedef Vector4<float> vec4;

#endif
