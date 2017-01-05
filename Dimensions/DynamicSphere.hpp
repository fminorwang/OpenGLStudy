//
//  DynamicSphere.h
//  Dimensions
//
//  Created by fminor on 04/01/2017.
//  Copyright © 2017 fminor. All rights reserved.
//

#include "ParametricEquations.hpp"
#include <OpenGLES/gltypes.h>

typedef struct DynamicSphere {
    Sphere              *sphere;
    vector<float>       vertexVector;
    vector<unsigned short> indexVector;
    GLuint              vertexSlot;
    GLuint              indexSlot;
    
    DynamicSphere() { }
    DynamicSphere(vec3 center, float raduis);
    
    void generateBuffer();
    void bindBuffer();
    
} DynamicSphere;


