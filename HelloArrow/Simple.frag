
const char* simpleFragmentShader = STRINGIFY
(
 varying lowp vec4 destinationColor;
 void main(void)
 {
     gl_FragColor = destinationColor;
 }
 );