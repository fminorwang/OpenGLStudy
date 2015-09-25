// DynamicSystemShader.fsh

varying mediump vec3 eyespaceNormal;
varying lowp vec3 diffuse;

uniform highp vec3 lightPosition;
uniform highp vec3 ambientMaterial;
uniform highp vec3 specularMaterial;
uniform highp float shininess;

uniform sampler2D sampler;

void main(void)
{
    highp vec3 N = normalize(eyespaceNormal);
    highp vec3 L = normalize(lightPosition);
    highp vec3 E = vec3(0, 0, 1);
    highp vec3 H = normalize(L + E);
    
    highp float df = max(0.0, dot(N, L));
    highp float sf = max(0.0, dot(N, H));
    sf = pow(sf, shininess);
    
    lowp vec3 color = ambientMaterial + df * diffuse + sf * specularMaterial;
    gl_FragColor = vec4(color, 1);
}
