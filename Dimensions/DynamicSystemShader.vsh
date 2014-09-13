// DynamicSystemShader.vsh

attribute vec4 position;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main()
{
    // vec4 _pos = vec4(position.x, position.x * position.x, position.z, position.w );
    gl_Position = projectionMatrix * modelViewMatrix * position;
    gl_PointSize = 2.0;
}
