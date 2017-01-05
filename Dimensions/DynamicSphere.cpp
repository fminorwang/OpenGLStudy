//
//  DynamicSphere.m
//  Dimensions
//
//  Created by fminor on 04/01/2017.
//  Copyright © 2017 fminor. All rights reserved.
//

#include "DynamicSphere.hpp"
#include <OpenGLES/ES2/gl.h>

DynamicSphere::DynamicSphere(vec3 center, float radius)
{
    sphere = new Sphere(radius, center);
    sphere->generateVertices(vertexVector, VertexFlagsNormal);
    sphere->generateTriangleIndices(indexVector);
}

void DynamicSphere::generateBuffer()
{
    glGenBuffers(1, &vertexSlot);
    glGenBuffers(1, &indexSlot);
    
    bindBuffer();
}

void DynamicSphere::bindBuffer()
{
    glBindBuffer(GL_ARRAY_BUFFER, vertexSlot);
    glBufferData(GL_ARRAY_BUFFER,
                 sizeof(vertexVector[0]) * 6 * sphere->getVertexCount(),
                 &vertexVector[0],
                 GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexSlot);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 sizeof(indexVector[0]) * sphere->getTriangleIndexCount(),
                 &indexVector[0],
                 GL_STATIC_DRAW);
}
