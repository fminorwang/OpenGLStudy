//
//  VertexShaderCompiler.h
//  Dimensions
//
//  Created by fminor on 9/7/14.
//  Copyright (c) 2014 fminor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VertexShaderCompiler : NSObject
{
    GLuint                              _program;
}

+ (VertexShaderCompiler *)sharedCompiler;

@end
