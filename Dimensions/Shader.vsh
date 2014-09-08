
attribute vec4 position;

uniform float factor;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main()
{
    vec4 _point = vec4(0.1, 0.1, 0.1, 0);
    // float _x = position.x * position.x - position.y * position.y;
    // float _y = 2.0 * position.x * position.y;
    float _x = position.x;
    float _y = position.y;
    
    float _r = sqrt(position.x * position.x + position.y * position.y);
    _r = pow(_r, pow(2.0, factor));

    float _angle = 0.0;
    if ( _x == 0.0 && _y == 0.0 ) {
        _angle = 0.0;
    } else {
        _angle = atan(_y, _x) + radians(180.0);
    }
    _angle = _angle * pow(2.0, factor);
    
    _x = _r * cos(_angle);
    _y = _r * sin(_angle);
    // gl_Position = modelViewMatrix * vec4(_x, _y, 0, position.w );
    gl_Position = projectionMatrix * modelViewMatrix * vec4(_x, _y, 0, position.w );
    gl_PointSize = 1.0;
}
