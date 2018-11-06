//
//  ViewController.swift
//  ARTest
//
//  Created by Marc Davis on 10/30/18.
//  Copyright © 2018 Marc Davis. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var shipNode: SCNNode? = nil

    @IBOutlet var sceneView: ARSCNView!
    
    var planes: [ARPlaneAnchor:Plane] = [:]
    var collisionPlanes: [SCNNode] = []
    var fuzzies: [Fuzzy] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        
        // Set the scene to the view
        sceneView.scene.rootNode.addChildNode(lookingPosition)
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.session.delegate = self
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        /*guard let referenceTest = ARReferenceObject.referenceObjects(inGroupNamed: "arobjects", bundle: nil) else {
            print("it done a broke")
            exit(0)
        }
        configuration.detectionObjects = referenceTest;*/
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        /*if let objectAnchor = anchor as? ARPlaneAnchor {
            let scene = SCNScene(named: "art.scnassets/ship.scn")!
            node.addChildNode(scene.rootNode)
        }*/
        if let plane = anchor as? ARPlaneAnchor {
            let newp = Plane(plane)
            node.addChildNode(newp)
            planes[plane] = newp
            collisionPlanes.append(newp.planeNode)
            
            for fuzzy in fuzzies {
                fuzzy.addCollisions(collisionPlanes)
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let plane = anchor as? ARPlaneAnchor {
                self.planes[plane]!.update(anchor: plane)
            }
        }
    }
    var lookingPosition: SCNNode = SCNNode()
    var lastTime = 0 as TimeInterval
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let deltaT = time - lastTime
        lastTime = time
        let position = lookingPosition.position
        let root = sceneView.scene.rootNode
        let colliders = [Plane](planes.values)
        var markedByTheKindred = nil as Int?
        for (index, fuzzy) in fuzzies.enumerated() {
            guard time > 10 else { break }
            fuzzy.updateAtTime(deltaT: deltaT, colliders: colliders, fleePosition: position)
            if fuzzy.age > 5 && !sceneView.isNode(fuzzy, insideFrustumOf: sceneView.pointOfView!) && randCGFloat() > 0.9965 {
                markedByTheKindred = index
            }
        }
        if let index = markedByTheKindred {
            let dead = fuzzies.remove(at: index)
            dead.removeFromParentNode()
        }
        
        if time > 1, fuzzies.count < 5 {
            guard let plane = colliders.randomElement() else { return }
            let fuzz = Fuzzy(color: UIColor(hue: randCGFloat(), saturation: randCGFloat()*0.1 + 0.9, brightness: randCGFloat() * 0.1 + 0.5, alpha: 1),plane: plane)
            fuzzies.append(fuzz)
            fuzz.position = SCNVector3(float3(plane.worldPosition) + float3(Float(randCGFloat()), 0, Float(randCGFloat())))
            root.addChildNode(fuzz)
        }
    }
    
    let halfpoint = CGPoint(x: 0.5, y: 0.5)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let result = frame.hitTest(halfpoint, types: .existingPlane)
        guard let first = result.first else { return }
        let transform = first.worldTransform
        lookingPosition.setWorldTransform(SCNMatrix4(transform))
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
