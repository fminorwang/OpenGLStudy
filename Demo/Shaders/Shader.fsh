//
//  Shader.fsh
//  Demo
//
//  Created by fminor on 8/25/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
