//
//  Interfaces.hpp
//  TouchCone
//
//  Created by fminor on 3/16/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef TouchCone_Interfaces_hpp
#define TouchCone_Interfaces_hpp

#include "Vector.hpp"
#include "Quaternion.hpp"
#include <vector>
#include <string>

using namespace std;

enum VertexFlags {
    VertexFlagsNormal       = 1 << 0,
    VertexFlagsTexCoords    = 1 << 1
};

struct IApplicationEngine
{
    virtual void initialize(int width, int height) = 0;
    virtual void render() const = 0;
    virtual void updateAnimation(float timeStep) = 0;
    virtual void onFingerUp(ivec2 location) = 0;
    virtual void onFingerDown(ivec2 location) = 0;
    virtual void onFingerMove(ivec2 oldLocation, ivec2 newLocation) = 0;
    virtual ~IApplicationEngine() {}
};

struct ISurface
{
    virtual int getVertexCount() const = 0;
    virtual int getLineIndexCount() const = 0;
    virtual int getTriangleIndexCount() const = 0;
    virtual void generateVertices(vector<float>& vertices, unsigned char flags = 0) const = 0;
    virtual void generateLineIndices(vector<unsigned short>& indices) const = 0;
    virtual void generateTriangleIndices(vector<unsigned short> & indices) const = 0;
    virtual ~ISurface() {}
};

struct ICurve
{
    virtual int getVertexCount() const = 0;
    virtual int getLineIndexCount() const = 0;
    virtual void generateVertices(vector<float>& vertices, unsigned char flags = 0) const = 0;
    virtual void generateLineIndices(vector<unsigned short>& indices) const = 0;
    virtual ~ICurve() {}
};

struct Visual
{
    vec3 color;
    ivec2 lowerLeft;
    ivec2 viewportSize;
    Quaternion orientation;
};

struct IRenderingEngine
{
    virtual void initialize(const vector<ICurve *>& curves) {}
    virtual void initialize(const vector<ISurface *>& surfaces) = 0;
    virtual void render(const vector<Visual>& visuals) const = 0;
    virtual ~IRenderingEngine() {}
};

struct IResourceManager
{
    virtual string getResourcePath() const = 0;
    virtual void loadPngImage(const string & filename) = 0;
    virtual void* getImageData() = 0;
    virtual ivec2 getImageSize() = 0;
    virtual void unloadImage() = 0;
    virtual ~IResourceManager() {}
};

IResourceManager* createResourceManager();
IApplicationEngine * createApplicationEngine(IRenderingEngine* renderingEngine, IResourceManager* resourceManager);

namespace ES1 {
    IRenderingEngine* createRenderingEngine(IResourceManager *resourceManager);
}
namespace ES2 {
    IRenderingEngine* createRenderingEngine(IResourceManager *resourceManager);
}

#endif
