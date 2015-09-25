// DynamicSystemShader.vsh

attribute vec4 position;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;

attribute vec3 normal;
attribute vec3 diffuseMaterial;

varying vec3 eyespaceNormal;
varying vec3 diffuse;

void main()
{
    eyespaceNormal = normalMatrix * normal;
    diffuse = diffuseMaterial;
    gl_Position = projectionMatrix * modelViewMatrix * position;
}
