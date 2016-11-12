//
//  AppDelegate.m
//  Seashells3D
//
//  Created by Matt on 3/25/14.
//  Copyright (c) 2014 Matt Rajca. All rights reserved.
//

#import "AppDelegate.h"

#import "Accelerate/Accelerate.h"

@implementation AppDelegate

typedef struct {
	float x, y, z;
	float nx, ny, nz;
} Vertex;

#define SUBDIVISIONS 250
#define COMPONENTS 3

// First example from: https://reference.wolfram.com/language/ref/ParametricPlot3D.html
SCNGeometry *CreateBlob()
{
	// Allocate enough space for our vertices
	const NSInteger vertexCount = (SUBDIVISIONS + 1) * (SUBDIVISIONS + 1);
	Vertex *const vertices = malloc(sizeof(Vertex) * vertexCount);

	// Calculate the uv step interval given the number of subdivisions
	const float uStep = 2.0f * M_PI / SUBDIVISIONS; // (2pi - 0) / subdivisions
	const float vStep = 2.0f * M_PI / SUBDIVISIONS; // (pi - -pi) / subdivisions

	Vertex *currentVertex = vertices;
	float u = 0;

	// Loop through our uv-space, generating 3D vertices.
	for (NSInteger i = 0; i <= SUBDIVISIONS; i++, u += uStep) {
		float v = -M_PI;

		for (NSInteger j = 0; j <= SUBDIVISIONS; j++, v += vStep, currentVertex++) {
			// Vertex calculations.
			currentVertex->x = cosf(u);
			currentVertex->y = sinf(u) + cosf(v);
			currentVertex->z = sinf(v);

			// Normal calculations.
			// dx/du, dy/du, dz/du = (-sin(u), cos(u), 0) = T1
			// dx/dv, dy/dv, dz/dv = (0, -sin(v), cos(v)) = T2
			// Cross product T1 X T2:
			// (cos(u) cos(v), sin(u) cos(v), sin(u) sin(v))
			currentVertex->nx = cosf(u) * cosf(v);
			currentVertex->ny = sinf(u) * cosf(v);
			currentVertex->nz = sinf(u) * sinf(v);

			// Normalize the results.
			float dot = 0;
			vDSP_dotpr(&currentVertex->nx, 1, &currentVertex->nx, 1, &dot, COMPONENTS);

			currentVertex->nx /= sqrtf(dot);
			currentVertex->ny /= sqrtf(dot);
			currentVertex->nz /= sqrtf(dot);
		}
	}

	const NSInteger indexCount = (SUBDIVISIONS * SUBDIVISIONS) * COMPONENTS * 2;
	unsigned short *const indices = malloc(sizeof(unsigned short) * indexCount);

	// Generate indices.
	unsigned short *idx = indices;
	unsigned short stripStart = 0;

	for (NSInteger i = 0; i < SUBDIVISIONS; i++, stripStart += (SUBDIVISIONS + 1)) {
		for (NSInteger j = 0; j < SUBDIVISIONS; j++) {
			unsigned short v1 = stripStart + j;
			unsigned short v2 = stripStart + j + 1;
			unsigned short v3 = stripStart + (SUBDIVISIONS+1) + j;
			unsigned short v4 = stripStart + (SUBDIVISIONS+1) + j + 1;

			*idx++ = v4;
			*idx++ = v2;
			*idx++ = v3;
			*idx++ = v1;
			*idx++ = v3;
			*idx++ = v2;
		}
	}

	NSData *data = [NSData dataWithBytes:vertices length:vertexCount * sizeof(Vertex)];
	free(vertices);

	SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithData:data
																 semantic:SCNGeometrySourceSemanticVertex
															  vectorCount:vertexCount
														  floatComponents:YES
													  componentsPerVector:COMPONENTS
														bytesPerComponent:sizeof(float)
															   dataOffset:0
															   dataStride:sizeof(Vertex)];

	SCNGeometrySource *normalSource = [SCNGeometrySource geometrySourceWithData:data
																	   semantic:SCNGeometrySourceSemanticNormal
																	vectorCount:vertexCount
																floatComponents:YES
															componentsPerVector:COMPONENTS
															  bytesPerComponent:sizeof(float)
																	 dataOffset:offsetof(Vertex, nx)
																	 dataStride:sizeof(Vertex)];

	SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:[NSData dataWithBytes:indices length:indexCount * sizeof(unsigned short)]
																primitiveType:SCNGeometryPrimitiveTypeTriangles
															   primitiveCount:indexCount/COMPONENTS
																bytesPerIndex:sizeof(unsigned short)];

	free(indices);

	return [SCNGeometry geometryWithSources:@[source, normalSource] elements:@[element]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Set up the scene.
	SCNScene *scene = [SCNScene scene];

	// 1. Camera
	SCNNode *cameraNode = [SCNNode node];
	cameraNode.camera = [SCNCamera camera];
	cameraNode.position = SCNVector3Make(4, 4, 30);
	cameraNode.transform = CATransform3DRotate(cameraNode.transform, -M_PI/14, -1, 0, 0);
	[scene.rootNode addChildNode:cameraNode];

	// 2. Spot light
	SCNLight *spotLight = [SCNLight light];
	spotLight.type = SCNLightTypeOmni;
	spotLight.color = [NSColor whiteColor];

	SCNNode *spotLightNode = [SCNNode node];
	spotLightNode.light = spotLight;
	spotLightNode.position = SCNVector3Make(-2, 1, 0);
	[cameraNode addChildNode:spotLightNode];

	// 3. Seashell
	SCNGeometry *seashellGeometry = CreateBlob();
	seashellGeometry.firstMaterial = [SCNMaterial material];
	seashellGeometry.firstMaterial.diffuse.contents = [NSColor redColor];
	seashellGeometry.firstMaterial.doubleSided = YES;

	CGFloat radius = 0;
	[seashellGeometry getBoundingSphereCenter:nil radius:&radius];

	SCNNode *parent = [SCNNode node];
	parent.position = SCNVector3Make(0, radius * 2, 0);

	SCNNode *seashellGeometryNode = [SCNNode nodeWithGeometry:seashellGeometry];
	seashellGeometryNode.pivot = CATransform3DMakeTranslation(0, 0, radius);
	seashellGeometryNode.rotation = SCNVector4Make(4, -2, 0, -M_PI_4);
	[parent addChildNode:seashellGeometryNode];

	[scene.rootNode addChildNode:parent];

	// 4. Floor
	SCNFloor *floor = [SCNFloor floor];
	floor.firstMaterial.diffuse.contents = [NSColor darkGrayColor];
	floor.reflectivity = 0.2;
	floor.reflectionFalloffEnd = 8;
	[scene.rootNode addChildNode:[SCNNode nodeWithGeometry:floor]];
	
	// Set the scene.
	self.sceneView.scene = scene;
	
	// Begin the rotation animation.
	CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"rotation"];
	rotationAnimation.duration = 10;
	rotationAnimation.repeatCount = FLT_MAX;
	rotationAnimation.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0, 1, 0, M_PI*2)];
	
	[parent addAnimation:rotationAnimation forKey:nil];
}

@end
