//
//  IRenderingEngine.hpp
//  Dimensions
//
//  Created by fminor on 2/27/15.
//  Copyright (c) 2015 fminor. All rights reserved.
//

#ifndef Dimensions_IRenderingEngine_hpp
#define Dimensions_IRenderingEngine_hpp

enum DeviceOrientation {
    DeviceOrientationUnknown,
    DeviceOrientationPortrait,
    DeviceOrientationPortraitUpsideDown,
    DeviceOrientationLandscapeLeft,
    DeviceOrientationLandscapeRight,
    DeviceOrientationFaceUp,
    DeviceOrientationFaceDown
};

struct IRenderingEngine* createRenderer1();
struct IRenderingEngine* createRenderer2();

struct IRenderingEngine {
    virtual void initialize(int width, int height) = 0;
    virtual void render() const = 0;
    virtual void updateAnimation(float timeStep) = 0;
    virtual void onRotate(DeviceOrientation newOrientation) = 0;
    virtual ~IRenderingEngine() {};
};

#endif
