// SphereShader.vsh

attribute vec4 position;        // x decides latitude, y decides longtitude, z = count of all x, w = count of all y

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

uniform vec3 centerPoint;
uniform float radius;
uniform float latitudeCounts;

void main()
{
    // vec4 _pos = vec4(position.x, position.x * position.x, position.z, position.w );
    float _z = radius - ( 2.0 * radius ) * position.x / ( latitudeCounts - 1.0 );
    
    float _r = sqrt( radius * radius - _z * _z );
    float _angle = radians(360.0) * position.y / position.z;
    float _x = _r * cos(_angle);
    float _y = _r * sin(_angle);
    
    _x += centerPoint.x;
    _y += centerPoint.y;
    _z += centerPoint.z;
    vec4 _point = vec4(_x, _y, _z, position.w);
    // gl_Position = projectionMatrix * modelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0);
    gl_Position = projectionMatrix * modelViewMatrix * _point;
    gl_PointSize = 1.0;
}