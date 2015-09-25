
const char* simpleVertexShader = STRINGIFY
(
 attribute vec4 position;
 attribute vec4 sourceColor;
 varying vec4 destinationColor;
 uniform mat4 Projection;
 uniform mat4 Modelview;
 
 void main(void)
 {
     destinationColor = sourceColor;
     gl_Position = Projection * Modelview * position;
 }
                                           
);