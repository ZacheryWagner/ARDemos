# ARDemos

## Overview
A series of demos demonstrating various applications of ARKit

### Demos

#### Face Tracking
Use a Snapchat like tab bar to apply various hand drawn overlays onto a face
* Swipe through the tab bar to swap face texture
* Tap the center button to take a screenshot
* Hold the center button to take a video

#### Object Manipulation
* Tap on a plane to place
* Move around the object by panning with one finger
* Rotate by panning with two fingers
* Reize by pinching
* Change color by tapping the Object

#### Rocket Launch
A demo for learning how to use particles, animations, and more complicated gestures in AR
* Slide down to start the thrusters
* Slide up to launch the rocket

#### 3D Stickers
Experiment to test quickly caluclating an angle of an object in reference to a tracked face and anchoring based on that angle
* Tap the tracked face to place 3D stickers

### Links
Some Resources I've found helpful and/or interesting while learning and developing AR Features

#### ARKit
* [ARKit Documentation](https://developer.apple.com/documentation/arkit)
* [Introducing ARKit 3](https://developer.apple.com/videos/play/wwdc2019/604/)
* [Explore ARKit 4](https://developer.apple.com/videos/play/wwdc2020/10611/)
* [Explore ARKit 5](https://developer.apple.com/videos/play/wwdc2021/10073/)
* [Building Collaborative AR Experiences](https://developer.apple.com/videos/play/wwdc2019/610/)

#### Metal
* [Modern Rendering with Metal](https://developer.apple.com/videos/play/wwdc2019/601/)
* [Ray Tracing with Metal](https://developer.apple.com/videos/play/wwdc2019/613/)
* [Discover ray tracing with Metal](https://developer.apple.com/videos/play/wwdc2020/10012/)
* [Accelerate machine learning with Metal Performance Shaders Graph](https://developer.apple.com/videos/play/wwdc2021/10152/)
* [Rendering Physically-Based ModelIO Materials](https://metalbyexample.com/modelio-materials/)


#### Model I/O
* [Model I/O Documentation](https://developer.apple.com/documentation/modelio)
* [Rendering Physically-Based ModelIO Materials](https://metalbyexample.com/modelio-materials/)
* [Model I/O - Swift, Xcode, and iOS](https://www.youtube.com/watch?v=_cdnDPzXAh4)

#### Reflectins
* [Adding Realistic Reflections to an AR Experience](https://developer.apple.com/documentation/arkit/camera_lighting_and_effects/adding_realistic_reflections_to_an_ar_experience)
* [ARKit by Example — Part 4: Realism - Lighting & PBR](https://blog.markdaws.net/arkit-by-example-part-4-realism-lighting-pbr-b9a0bedb013e)

### Note
There are much better practices for managing models and AR Sessions.  The production code 
this eventually became has a totally refactored architecture.  I do not recommend using this 
as a reference for learning AR.  Proprietary assets have been removed for the privacy of my 
former place of employment.  As a result this will likely not run.
