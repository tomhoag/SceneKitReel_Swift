//
//  GameViewController.swift
//  FPSPaintScene
//
//  Created by Tom on 6/12/17.
//  Copyright © 2017 SquarePi. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

class GameViewController: UIViewController, SCNPhysicsContactDelegate, SCNSceneRendererDelegate {

    var scene:SCNScene!
    
    // save spot light transform
    var originalSpotTransform:SCNMatrix4!
    
    var cameraNode:SCNNode!
    var cameraHandle:SCNNode!
    var cameraOrientation:SCNNode!
    
    var ambientLightNode:SCNNode!
    var spotLightParentNode:SCNNode!
    var spotLightNode:SCNNode!
    
    var mainWall:SCNNode!
    var floorNode:SCNNode!
    var invisibleWallForPhysicsSlide:SCNNode!
    
    var torus:SCNNode!
    var splashNode:SCNNode!
    var plok:SCNParticleSystem!
    
    //camera manipulation
    var cameraBaseOrientation:SCNVector3!
    var initialOffset:CGPoint!
    var lastOffset:CGPoint!
    var cameraHandleTransforms:[SCNMatrix4] = Array()
    var cameraOrientationTransforms:[SCNMatrix4] = Array()
    
    // MARK: - Entry 
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }
    
    //MARK: - Setup
    
    func setup() {
        
        //SCNView *sceneView = (SCNView *)self.view;
        let sceneView = self.view as! SCNView
        //redraw forever
        //sceneView.playing = true;
        sceneView.loops = true;
        sceneView.showsStatistics = true;
        
        sceneView.backgroundColor = UIColor.black
        
        //setup ivars
        //_boxes = [NSMutableArray array];
        
        //setup the scene
        setupScene() //[self setupScene];
        
        //present it
        sceneView.scene = scene;
        
        //tweak physics
        sceneView.scene?.physicsWorld.speed = 2.0;
        
        //let's be the delegate of the SCNView
        sceneView.delegate = self //as! SCNSceneRendererDelegate
        
        //initial point of view
        sceneView.pointOfView = cameraNode;
        
        //setup overlays
        //AAPLSpriteKitOverlayScene *overlay = [[AAPLSpriteKitOverlayScene alloc] initWithSize:sceneView.bounds.size];
        //sceneView.overlaySKScene = overlay;
        
        /*
        var gestureRecognizers = [UIGestureRecognizer]()
        //[gestureRecognizers addObjectsFromArray:sceneView.gestureRecognizers];
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(_:)))
        
        // add a pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan(_:)))
        
        // add a double tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2;
        
        tapGesture.requireGestureRecognizerToFail(panGesture)
        
        gestureRecognizers.append(doubleTapGesture)
        gestureRecognizers.append(tapGesture)
        gestureRecognizers.append(panGesture)
        
        
        //register gesture recognizers
        sceneView.gestureRecognizers = gestureRecognizers;
        */

        
    }

    func setupScene() {
        scene = SCNScene()
        setupEnvironment()
        setupSceneElements()
        //setupIntroEnvironment()
        showSpriteKitSlide()
    }
    
    func setupEnvironment() {
    // |_   cameraHandle
    //   |_   cameraOrientation
    //     |_   cameraNode
    
    //create a main camera
        cameraNode = SCNNode()
        cameraNode.position = SCNVector3Make(0, 0, 120);
    
        //create a node to manipulate the camera orientation
        cameraHandle = SCNNode()
        cameraHandle.position = SCNVector3Make(0, 60, 0);
    
        cameraOrientation = SCNNode()
    
        scene.rootNode.addChildNode(cameraHandle)
        cameraHandle.addChildNode(cameraOrientation)
        cameraOrientation.addChildNode(cameraNode)
    
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 800;
        cameraNode.camera?.yFov = 55;
        cameraNode.camera?.xFov = 75;
    
        cameraHandleTransforms.insert(cameraNode.transform, at: 0)
    
        // add an ambient light
        ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
    
        ambientLightNode.light?.type = SCNLight.LightType.ambient;
        ambientLightNode.light?.color = UIColor.init(white: 0.3, alpha: 1.0) //[SKColor colorWithWhite:0.3 alpha:1.0];
    
        scene.rootNode.addChildNode(ambientLightNode)
    
    
        //add a key light to the scene
        spotLightParentNode = SCNNode()
        spotLightParentNode.position = SCNVector3Make(0, 90, 20);
    
        spotLightNode = SCNNode()
        spotLightNode.rotation = SCNVector4Make(1,0,0,-Float.pi/4);//
    
        spotLightNode.light = SCNLight()
        spotLightNode.light?.type = SCNLight.LightType.spot;
        spotLightNode.light?.color = UIColor.init(white:1.0, alpha:1.0)
        spotLightNode.light?.castsShadow = true;
        spotLightNode.light?.shadowColor = UIColor.init(white:0, alpha:0.5)
        spotLightNode.light?.zNear = 30;
        spotLightNode.light?.zFar = 800;
        spotLightNode.light?.shadowRadius = 1.0;
        spotLightNode.light?.spotInnerAngle = 15;
        spotLightNode.light?.spotOuterAngle = 70;
    
        cameraNode.addChildNode(spotLightParentNode)
        spotLightParentNode.addChildNode(spotLightNode)
    
        //save spotlight transform
        originalSpotTransform = spotLightNode.transform
    
        //floor
        let floor = SCNFloor()
        floor.reflectionFalloffEnd = 0;
        floor.reflectivity = 0;
    
        floorNode = SCNNode()
        floorNode.geometry = floor;
        floorNode.geometry?.firstMaterial?.diffuse.contents = "wood.png";
        floorNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true;
        floorNode.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        floorNode.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        floorNode.geometry?.firstMaterial?.diffuse.mipFilter = .nearest
        floorNode.geometry?.firstMaterial?.isDoubleSided = false;
    
        floorNode.physicsBody =  SCNPhysicsBody.static()
        floorNode.physicsBody?.restitution = 1.0;
    
        scene.rootNode.addChildNode(floorNode)
    }

    func setupSceneElements() {
    
    // create the wall geometry
        let wallGeometry = SCNPlane.init(width: 800, height: 200)
        wallGeometry.firstMaterial?.diffuse.contents = "wallPaper.png";
        wallGeometry.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(8, 2, 1), SCNMatrix4MakeRotation(Float.pi/4, 0, 0, 1));
        wallGeometry.firstMaterial?.diffuse.wrapS = .repeat
        wallGeometry.firstMaterial?.diffuse.wrapT = .repeat
        wallGeometry.firstMaterial?.isDoubleSided = false;
        wallGeometry.firstMaterial?.locksAmbientWithDiffuse = true;
    
        let wallWithBaseboardNode = SCNNode.init(geometry: wallGeometry)
        wallWithBaseboardNode.position = SCNVector3Make(200, 100, -20);
        wallWithBaseboardNode.physicsBody = SCNPhysicsBody.static()
        wallWithBaseboardNode.physicsBody?.restitution = 1.0;
        wallWithBaseboardNode.castsShadow = false;
    
        let baseboardNode = SCNNode.init(geometry: SCNBox.init(width: 800, height: 8, length: 0.5, chamferRadius: 0))
        baseboardNode.geometry?.firstMaterial?.diffuse.contents = "baseboard.jpg";
        baseboardNode.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        baseboardNode.geometry?.firstMaterial?.isDoubleSided = false;
        baseboardNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true;
        baseboardNode.position = SCNVector3Make(0, -wallWithBaseboardNode.position.y + 4, 0.5);
        baseboardNode.castsShadow = false;
        baseboardNode.renderingOrder = -3; //render before others
    
        wallWithBaseboardNode.addChildNode(baseboardNode)
    
        //front walls
        mainWall = wallWithBaseboardNode;
        scene.rootNode.addChildNode(wallWithBaseboardNode)
        mainWall.renderingOrder = -3; //render before others
    
        //back
        let backWallNode = wallWithBaseboardNode.clone()
        backWallNode.opacity = 0;
        backWallNode.physicsBody = SCNPhysicsBody.static()
        backWallNode.physicsBody?.restitution = 1.0;
        backWallNode.physicsBody?.categoryBitMask = 1 << 2;
        backWallNode.castsShadow = false;
        backWallNode.physicsBody?.contactTestBitMask = ~0;
    
        backWallNode.position = SCNVector3Make(0, 100, 0);
        backWallNode.rotation = SCNVector4Make(0, 1, 0, Float.pi);
        scene.rootNode.addChildNode(backWallNode)
    
        //left
        var wallNode = wallWithBaseboardNode.clone()
        wallNode.position = SCNVector3Make(-120, 100, 40);
        wallNode.rotation = SCNVector4Make(0, 1, 0, Float.pi/2);
        scene.rootNode.addChildNode(wallNode)
    
        //right (an invisible wall to keep the bodies in the visible area when zooming in the Physics slide)
//        wallNode = wallNode.clone()
//        wallNode.opacity = 0;
//        wallNode.position = SCNVector3Make(120, 100, 40);
//        wallNode.rotation = SCNVector4Make(0, 1, 0, -(Float.pi/2));
//        invisibleWallForPhysicsSlide = wallNode
    
        //right (the actual wall on the right)
        wallNode = wallWithBaseboardNode.clone()
        wallNode.physicsBody = nil;
        wallNode.position = SCNVector3Make(600, 100, 40);
        wallNode.rotation = SCNVector4Make(0, 1, 0, -(Float.pi/2));
        scene.rootNode.addChildNode(wallNode)
    
        //top
        wallNode = wallWithBaseboardNode.copy() as! SCNNode
        wallNode.geometry = (wallNode.geometry?.copy() as! SCNGeometry)
        wallNode.geometry?.firstMaterial = SCNMaterial()
        wallNode.opacity = 1;
        wallNode.position = SCNVector3Make(200, 200, 0);
        wallNode.scale = SCNVector3Make(1, 10, 1);
        wallNode.rotation = SCNVector4Make(1, 0, 0, Float.pi/2);
        scene.rootNode.addChildNode(wallNode)
    
        //mainWall.isHidden = true; //hide at first (save some milliseconds)
    }
    
    static let W:CGFloat = 50
    static let SPRITE_SIZE:CGFloat = 256


    //present spritekit integration slide
    func showSpriteKitSlide()    {
        //place camera
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        cameraHandle.position = SCNVector3Make(cameraHandle.position.x+200, 60, 0)
        SCNTransaction.commit()
        
        //load plok particles
        plok = SCNParticleSystem(named: "plok.scnp", inDirectory: "assets.scnassets/particles")
        
        //#define W 50
        
        //create a spinning object
        torus = SCNNode()
        torus.position = SCNVector3Make(cameraHandle.position.x, 60, 10);
        torus.geometry = SCNTorus(ringRadius: GameViewController.W/2, pipeRadius: GameViewController.W/6)
        
        torus.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: torus.geometry!, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        torus.opacity = 0.0;
        
        // create a splash, this is used when a paintball hits other than the torus
        splashNode = SCNNode()
        splashNode.geometry = SCNPlane.init(width: 10, height: 10)
        splashNode.geometry?.firstMaterial?.transparent.contents = "splash.png";
        
        
        let material = torus.geometry?.firstMaterial;
        material?.specular.contents = UIColor(white:0.5, alpha:1.0)
        material?.shininess = 2.0;
        
        material?.normal.contents = "wood-normal.png"
        
        scene.rootNode.addChildNode(torus)
        
        let action = SCNAction.repeatForever(SCNAction.rotate(by: CGFloat.pi*2, around: SCNVector3Make(0.4,1,0), duration: 8))
        torus.runAction(action)
        
        //preload it to avoid frame drop
        (self.view as! SCNView).prepare(scene, shouldAbortBlock: nil)
        
        scene.physicsWorld.contactDelegate = self;
        
        //setup material
        let skScene = SKScene(size: CGSize(width:GameViewController.SPRITE_SIZE, height: GameViewController.SPRITE_SIZE))
        skScene.backgroundColor = UIColor.white
        material?.diffuse.contents = skScene;
        
        //tweak physics
        (self.view as! SCNView).scene?.physicsWorld.gravity = SCNVector3Make(0,-70,0)
        
        // show the torus
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        torus.opacity = 1.0
        SCNTransaction.commit()
    }

    // MARK: - Launch!!
    
    static let PAINT_FACTOR:Float = 2
    
    func launchColorBall()    {
        let ball = SCNNode()
        let sphere = SCNSphere(radius: 2.0)
        ball.geometry = sphere
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor(hue: CGFloat(arc4random()) / CGFloat(UInt32.max), saturation: 1, brightness: 1, alpha: 1)
        ball.geometry?.firstMaterial?.reflective.contents = "envmap.jpg";
        ball.geometry?.firstMaterial?.fresnelExponent = 1.0;
        ball.physicsBody = SCNPhysicsBody.dynamic()
        ball.physicsBody?.restitution = 0.9
        ball.physicsBody?.categoryBitMask = 0x4;
        ball.physicsBody?.contactTestBitMask = ~0;
        ball.physicsBody?.collisionBitMask = ~(0x4);
        ball.physicsBody?.contactTestBitMask = 0xff;
        
        ball.position = SCNVector3Make(cameraHandle.position.x, 20, 100);
        
        //add to scene
        scene.rootNode.addChildNode(ball)
        
        ball.physicsBody?.velocity = SCNVector3Make(GameViewController.PAINT_FACTOR * randomFloat(min: -20, max: 20), (75 + randomFloat(min: 0, max: 35)), GameViewController.PAINT_FACTOR * -60.0) // why did I need to change this from -30??

    }

    
    static var lastTime:TimeInterval = 0
    
    // MARK: - SCNSceneRendererDelegate
    func renderer(_ aRenderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if(time - GameViewController.lastTime > 0.1){
            GameViewController.lastTime = time;
            launchColorBall()
        }
    }
    
    // MARK: - SCNPhysicsContactDelegate
    
    static var eps:Float = 1

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        var ball:SCNNode? = nil;
        var other:SCNNode? = nil;
    
        if (contact.nodeA.physicsBody?.type == .dynamic) {
            ball = contact.nodeA;
            other = contact.nodeB;
        } else if((contact.nodeB.physicsBody?.type)! == .dynamic) {
            ball = contact.nodeB
            other = contact.nodeA
        }
    
        if ((ball) != nil) {
            let plokCopy = plok.copy() as! SCNParticleSystem
            plokCopy.particleImage = plok.particleImage
            plokCopy.particleColor = ball!.geometry!.firstMaterial!.diffuse.contents as! UIColor;
            let matrix = SCNMatrix4MakeTranslation(contact.contactPoint.x, contact.contactPoint.y, contact.contactPoint.z)
            scene.addParticleSystem(plokCopy, transform: matrix)
    
            if (other != torus) {
                let splashNodeClone = splashNode.clone()
                splashNodeClone.geometry = splashNodeClone.geometry?.copy() as? SCNGeometry
                splashNodeClone.geometry?.firstMaterial = splashNodeClone.geometry?.firstMaterial?.copy() as? SCNMaterial
                splashNodeClone.geometry?.firstMaterial?.diffuse.contents = plokCopy.particleColor;
                splashNodeClone.castsShadow = false;
                //node.geometry.firstMaterial.readsFromDepthBuffer = NO;
                splashNodeClone.geometry?.firstMaterial?.writesToDepthBuffer = false;
    
                GameViewController.eps += 0.0002;
                splashNodeClone.position = SCNVector3Make(contact.contactPoint.x, contact.contactPoint.y, mainWall.position.z + GameViewController.eps);
    
                let wait = SCNAction.wait(duration: 6.0)
                let fadeOut = SCNAction.fadeOut(duration: 1.5)
                let remove = SCNAction.removeFromParentNode()
                let action = SCNAction.sequence([ wait, fadeOut, remove])
                splashNodeClone.runAction(action)
                
                scene.rootNode.addChildNode(splashNodeClone)
    
            } else {
                //compute texture coordinate
                let scnView = self.view as! SCNView
                let pointA = SCNVector3Make(contact.contactPoint.x, contact.contactPoint.y, contact.contactPoint.z+20);
                let pointB = SCNVector3Make(contact.contactPoint.x, contact.contactPoint.y, contact.contactPoint.z-20);
                    
                let results = scnView.scene?.rootNode.hitTestWithSegment(from: pointA, to: pointB, options: [SCNHitTestOption.rootNode.rawValue: torus] )

                if ((results?.count)! > 0) {
                    let hit = results?[0]
                    let location = hit?.textureCoordinates(withMappingChannel: 0)
                    addPaintAtLocation(point: location!, color: plokCopy.particleColor)
                }
            }
            ball?.removeFromParentNode()
        }
    }

    func addPaintAtLocation(point: CGPoint, color:UIColor) {
        
        let skScene = torus.geometry?.firstMaterial?.diffuse.contents as! SKScene
        
        if skScene is SKScene {
        
            var p = point
            //update the contents of skScene by adding a splash of "color" at p (normalized [0, 1])
            p.x *= GameViewController.SPRITE_SIZE;
            p.y *= GameViewController.SPRITE_SIZE;
            
            var spriteNode = SKSpriteNode()
            spriteNode.position = p;
            spriteNode.xScale = 0.33;
            
            let spriteSplashNode = SKSpriteNode(imageNamed:"splash.png")
            spriteSplashNode.zRotation = CGFloat(randomFloat(min:0.0, max:2.0 * .pi))
            spriteSplashNode.color = color
            spriteSplashNode.colorBlendFactor = 1
            
            spriteNode.addChild(spriteSplashNode)
            skScene.addChild(spriteNode)
            
            //remove color splash at some point
            let wait = SKAction.wait(forDuration: 5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let action = SKAction.sequence([wait, fadeOut, remove])
            spriteNode.run(action)
            
            if (p.x < 16) {
                spriteNode = spriteNode.copy() as! SKSpriteNode
                p.x = GameViewController.SPRITE_SIZE + p.x;
                spriteNode.position = p;
                skScene.addChild(spriteNode)
            }
            else if (p.x > GameViewController.SPRITE_SIZE-16) {
                spriteNode = spriteNode.copy() as! SKSpriteNode
                p.x = (p.x - GameViewController.SPRITE_SIZE);
                spriteNode.position = p;
                skScene.addChild(spriteNode)
            }
        }
    }

    
    
   // MARK:  - Gestures
    
    func gestureDidEnd() {
//        if (_step == 3) {
//            //bubbles
//            //fieldOwner.physicsField.strength = 0.0;
//        }
    }
    
    func gestureDidBegin() {
        initialOffset = lastOffset;
    }
    

    func handleDoubleTap(_ gestureRecognizer:UIGestureRecognizer) {
        restoreCameraAngle()
    }
    
    func handlePan(_ gestureRecognizer:UITapGestureRecognizer) {
        if (gestureRecognizer.state == .ended) { //UIGestureRecognizerStateEnded) {
            gestureDidEnd()
            return;
        }
    
        if (gestureRecognizer.state == .began) { //UIGestureRecognizerStateBegan) {
            gestureDidBegin()
            return;
        }
    
        if (gestureRecognizer.numberOfTouches == 2) {
            //[self tiltCameraWithOffset:[(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.view]];
        }
    
        else {
            let p = gestureRecognizer.location(in: self.view)
            //handlePanAtPoint(p)
        }
    }
    
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        let p = gestureRecognizer.location(in: self.view)
        //handleTapAtPoint(p)
    }
    
    func handlePanAtPoint(p:CGPoint)    {
        /*
        let scnView = self.view as! SCNView
        
        if (_step == 2) {
            //particles
            SCNVector3 pTmp = [scnView projectPoint:SCNVector3Make(0, 0, 0)];
            SCNVector3 p3d = [scnView unprojectPoint:SCNVector3Make(p.x, p.y, pTmp.z)];
            SCNMatrix4 handlePos = _handle.worldTransform;
            
            
            float dy = MAX(0, p3d.y - handlePos.m42);
            float dx = handlePos.m41 - p3d.x;
            float angle = atan2f(dy, dx);
            
            
            angle -= 35.*M_PI/180.0; //handle is 35 degree by default
            
            //clamp
            #define MIN_ANGLE -M_PI_2*0.1
            #define MAX_ANGLE M_PI*0.8
            if (angle < MIN_ANGLE) angle = MIN_ANGLE;
            if (angle > MAX_ANGLE) angle = MAX_ANGLE;
            
            
            #define HIT_DELAY 3.0
            
            if (angle <= 0.66 && angle >= 0.48) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HIT_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //hit the fire!
                    _hitFire = YES;
                    });
            }
            else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HIT_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //hit the fire!
                    _hitFire = NO;
                    });
            }
            
            _handle.rotation = SCNVector4Make(1, 0, 0, angle);
        }
        */
        /*
        if (_step == 3) {
            //bubbles
            [self moveEmitterTo:p];
        }
        */
    }
    
    func handleDoubleTapAtPoint(p: CGPoint) {
        restoreCameraAngle()
    }
/*
    func preventAccidentalNext(delay: CGFloat) {
        _preventNext = YES;
        
        //disable the next button for "delay" seconds to prevent accidental tap
        AAPLSpriteKitOverlayScene *overlay = (AAPLSpriteKitOverlayScene *)((SCNView*)self.view).overlaySKScene;
        [overlay.nextButton runAction:[SKAction fadeAlphaBy:-0.5 duration:0.5]];
        [overlay.previousButton runAction:[SKAction fadeAlphaBy:-0.5 duration:0.5]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _preventNext = NO;
            [overlay.previousButton runAction:[SKAction fadeAlphaTo:_step > 1 ? 1 : 0 duration:0.75]];
            [overlay.nextButton runAction:[SKAction fadeAlphaTo:_introductionStep == 0 && _step < 5 ? 1 : 0 duration:0.75]];
            });
    }
 */
    /*
    func handleTapAtPoint(p: CGPoint) {
        //test buttons
        SKScene *skScene = ((SCNView*)self.view).overlaySKScene;
        
        let skScene = (self.view as! SCNView).overlaySKScene
        
        let p2D = [skScene convertPointFromView:p];
        SKNode *node = [skScene nodeAtPoint:p2D];
        
        // wait X seconds before enabling the next tap to avoid accidental tap
        BOOL ignoreNext = _preventNext;
        
        if (_introductionStep) {
            //next introduction step
            if (!ignoreNext){
                [self preventAccidentalNext:1];
                [self nextIntroductionStep];
            }
            return;
        }
        
        if (ignoreNext == NO) {
            if (_step == 0 || [node.name isEqualToString:@"next"] || [node.name isEqualToString:@"back"]) {
                BOOL shouldGoBack = [node.name isEqualToString:@"back"];
                
                if ([node.name isEqualToString:@"next"]) {
                    ((SKSpriteNode*)node).color = [SKColor colorWithRed:1 green:0 blue:0 alpha:1];
                    [node runAction:[SKAction customActionWithDuration:0.7 actionBlock:^(SKNode *node, CGFloat elapsedTime) {
                        ((SKSpriteNode*)node).colorBlendFactor = 0.7 - elapsedTime;
                        }]];
                }
                
                [self restoreCameraAngle];
                
                [self preventAccidentalNext:_step==1 ? 3 : 1];
                
                if (shouldGoBack)
                [self previous];
                else
                [self next];
                
                return;
            }
        }
    /*
        if (_step == 1) {
            //bounce physics!
            SCNView *scnView = (SCNView *) self.view;
            SCNVector3 pTmp = [scnView projectPoint:SCNVector3Make(0, 0, -60)];
            SCNVector3 p3d = [scnView unprojectPoint:SCNVector3Make(p.x, p.y, pTmp.z)];
            
            p3d.y = 0;
            p3d.z = 0;
            
            [self explosionAt:p3d receivers:_boxes removeOnCompletion:NO];
        }
    */
    /*
        if (_step == 3) {
            //bubbles
            [self moveEmitterTo:p];
        }
    */
    /*
        if (_step == 5) {
            //shader
            [self showNextShaderStage];
        }
    */
    }
 */
    
    // MARK: - Helpers & Utility Funcs
    
    // utility function
    func randomFloat(min: Float = 0, max: Float = 100) -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }

    //restore the default camera orientation and position
    func restoreCameraAngle()    {
        //reset drag offset
        initialOffset = CGPoint(x:0, y:0);
        lastOffset = initialOffset;
        
        //restore default camera
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        cameraHandle.eulerAngles = SCNVector3Make(0, 0, 0);
        SCNTransaction.commit()
    }
    
    // MARK: - View Management
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
