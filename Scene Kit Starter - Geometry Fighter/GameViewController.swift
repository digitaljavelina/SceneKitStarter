//
//  GameViewController.swift
//  Scene Kit Starter - Geometry Fighter
//
//  Created by Michael Henry on 10/2/16.
//  Copyright (c) 2016 Digital Javelina, LLC. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: NSTimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        
        scnView.delegate = self
        
        scnView.playing = true
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func spawnShape() {
        var geometry: SCNGeometry
        
        switch ShapeType.random() {
        case .Sphere: geometry = SCNSphere(radius: 1.0)
        case .Pyramid: geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .Torus: geometry = SCNTorus(ringRadius: 1.0, pipeRadius: 0.5)
        case .Capsule: geometry = SCNCapsule(capRadius: 1.0, height: 1.0)
        case .Cylinder: geometry = SCNCylinder(radius: 1.0, height: 1.0)
        case .Cone: geometry = SCNCone(topRadius: 1.0, bottomRadius: 1.0, height: 1.0)
        case .Tube: geometry = SCNTube(innerRadius: 1.0, outerRadius: 1.0, height: 1.0)
        case .Box: geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        }
        
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        
        geometryNode.physicsBody?.applyForce(force, atPosition: position, impulse: true)
        
        let trailEmitter = createTrail(color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        if color == UIColor.blackColor() {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
        
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentationNode.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        
        return trail
    }
    
    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 10.0, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleTouchFor(node: SCNNode) {
        if node.name == "GOOD" {
            createExplosion(node.geometry!, position: node.presentationNode.position, rotation: node.presentationNode.rotation)
            game.score += 1
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            createExplosion(node.geometry!, position: node.presentationNode.position, rotation: node.presentationNode.rotation)
            game.lives -= 1
            node.removeFromParentNode()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let location = touch.locationInView(scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            handleTouchFor(result.node)
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .Surface
        
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, withTransform: transformMatrix)
    }
    
}

extension GameViewController: SCNSceneRendererDelegate {
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if time > spawnTime {
            spawnShape()
            spawnTime = time + NSTimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        
        cleanScene()
        game.updateHUD()
    }
    
}
