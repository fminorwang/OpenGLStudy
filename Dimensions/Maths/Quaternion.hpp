//
//  Quaternion.hpp
//  Dimensions
//
//  Created by fminor on 3/2/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#pragma once
#include <cmath>
#include "Matrix.hpp"
using namespace std;

template <typename T>
struct QuaternionT {
    T x;
    T y;
    T z;
    T w;
    
    QuaternionT();
    QuaternionT(T x, T y, T z, T w);
    
    QuaternionT<T> slerp(T mu, const QuaternionT<T> &q) const;
    QuaternionT<T> rotated(const QuaternionT<T> &b) const;
    QuaternionT<T> scaled(T scale) const;
    T dot(const QuaternionT<T> &q) const;
    Matrix3<T> toMatrix() const;
    Vector4<T> toVector() const;
    QuaternionT<T> operator - (const QuaternionT<T> &q) const;
    QuaternionT<T> operator + (const QuaternionT<T> &q) const;
    bool operator == (const QuaternionT<T> &q) const;
    bool operator != (const QuaternionT<T> &q) const;
    void normalize();
    void rotate(const QuaternionT<T> &q);
    static QuaternionT<T> createFromVectors(const Vector3<T> &v0, const Vector3<T> &v1);
    static QuaternionT<T> createFromAxisAngle(const Vector3<T> &axis, float radians);
};

template <typename T>
inline QuaternionT<T>::QuaternionT() : x(0), y(0), z(0), w(1)
{
}

template <typename T>
inline QuaternionT<T>::QuaternionT(T x, T y, T z, T w) : x(x), y(y), z(z), w(w)
{
}

template <typename T>
inline QuaternionT<T> QuaternionT<T>::slerp(T t, const QuaternionT<T> &v1) const
{
    const T epsilon = 0.0005f;
    T _dot = dot(v1);
    if ( _dot > 1 - epsilon ) {
        QuaternionT<T> result = v1 + ( *this - v1 ).scaled(t);
        result.normalize();
        return result;
    }
    if ( _dot < 0 ) {
        _dot = 0;
    }
    if ( _dot > 1 ) {
        _dot = 1;
    }
    T theta0 = acos(_dot);
    T theta = theta0 * t;
    QuaternionT<T> v2 = v1 - scaled(_dot);
    v2.normalize();
    QuaternionT<T> q = scaled(cos(theta)) + v2.scaled(sin(theta));
    q.normalize();
    return q;
}

template <typename T>
inline QuaternionT<T> QuaternionT<T>::rotated(const QuaternionT<T> & b) const
{
    QuaternionT<T> q;
    q.w = w * b.w - x * b.x - y * b.y - z * b.z;
    q.x = w * b.x + x * b.w + y * b.z - z * b.y;
    q.y = w * b.y + y * b.w + z * b.x - x * b.z;
    q.z = w * b.z + z * b.w + x * b.y - y * b.x;
    q.normalize();
    return q;
}

template <typename T>
inline QuaternionT<T> QuaternionT<T>::scaled(T s) const
{
    return QuaternionT<T>(x * s, y * s, z * s, w * s);
}

template <typename T>
inline T QuaternionT<T>::dot(const QuaternionT<T> &q) const
{
    return x * q.x + y * q.y + z * q.z + w * q.w;
}

template <typename T>
inline Matrix3<T> QuaternionT<T>::toMatrix() const
{
    const T s = 2;
    T xs, ys, zs;
    T wx, wy, wz;
    T xx, xy, xz;
    T yy, yz, zz;
    xs = x * s;     ys = y * s;     zs = z * s;
    wx = w * xs;    wy = w * ys;    wz = w * zs;
    xx = x * xs;    xy = x * ys;    xz = x * zs;
    yy = y * ys;    yz = y * zs;    zz = z * zs;
    
    Matrix3<T> m;
    m.x.x = 1 - ( yy + zz );    m.y.x = xy - wz;    m.z.x = xz + wy;
    m.x.y = xy + wz;    m.y.y = 1 - ( xx + zz );    m.z.y = yz - wx;
    m.x.z = xz - wy;    m.y.z = yz + wx;    m.z.z = 1 - ( xx + yy );
    return m;
}

template <typename T>
inline Vector4<T> QuaternionT<T>::toVector() const
{
    return Vector4<T>(x, y, z, w);
}

template <typename T>
QuaternionT<T> QuaternionT<T>::operator - (const QuaternionT<T> &q) const
{
    return QuaternionT<T>(x - q.x, y - q.y, z - q.z, w - q.w);
}

template <typename T>
QuaternionT<T> QuaternionT<T>::operator + (const QuaternionT<T> &q) const
{
    return QuaternionT<T>(x + q.x, y + q.y, z + q.z, w + q.w);
}

template <typename T>
bool QuaternionT<T>::operator == (const QuaternionT<T> &q) const
{
    return x == q.x && y == q.y && z == q.z && w == q.w;
}

template <typename T>
bool QuaternionT<T>::operator != (const QuaternionT<T> &q) const
{
    return !(*this == q);
}

template <typename T>
inline QuaternionT<T> QuaternionT<T>::createFromVectors(const Vector3<T> &v0, const Vector3<T> &v1)
{
    if ( v0 == -v1 ) {
        return QuaternionT<T>::createFromAxisAngle(vec3(1, 0, 0), m_pi);
    }
    Vector3<T> c = v0.cross(v1);
    T d = v0.dot(v1);
    T s = sqrt(( 1 + d ) * 2);
    QuaternionT<T> q;
    q.x = c.x / s;
    q.y = c.y / s;
    q.z = c.z / s;
    q.w = s / 2.0f;
    return q;
}

template <typename T>
inline QuaternionT<T> QuaternionT<T>::createFromAxisAngle(const Vector3<T> &axis, float radians)
{
    QuaternionT<T> q;
    q.w = cos(radians / 2);
    q.x = q.y = q.z = sin(radians / 2);
    q.x *= axis.x;
    q.y *= axis.y;
    q.z *= axis.z;
    return q;
}

template <typename T>
inline void QuaternionT<T>::normalize()
{
    *this = scaled(1 / sqrt(dot(*this)));
}

template <typename T>
inline void QuaternionT<T>::rotate(const QuaternionT<T> &q2)
{
    QuaternionT<T> q;
    QuaternionT<T> &q1 = *this;
    q.x = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
    q.y = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
    q.z = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z;
    q.w = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x;
    q.normalize();
    *this = q;
}

typedef QuaternionT<float> Quaternion;
