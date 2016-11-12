//
//  AppDelegate.h
//  Seashells3D
//
//  Created by Matt on 3/25/14.
//  Copyright (c) 2014 Matt Rajca. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, nullable, weak) IBOutlet SCNView *sceneView;

@end

NS_ASSUME_NONNULL_END
