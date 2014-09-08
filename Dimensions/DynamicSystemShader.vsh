// DynamicSystemShader.vsh

attribute vec4 position;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main()
{
    gl_Position = projectionMatrix * modelViewMatrix * position;
    gl_PointSize = 1.0;
}
