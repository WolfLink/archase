//
//  GameClasses.swift
//  ARTest
//
//  Created by Marc Davis on 11/6/18.
//  Copyright © 2018 Marc Davis. All rights reserved.
//

import Foundation
import ARKit

class Plane: SCNNode {
    var planeAnchor: ARPlaneAnchor
    
    var planeGeometry: SCNPlane
    var planeNode: SCNNode
    
    init(_ anchor: ARPlaneAnchor) {
        self.planeAnchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        planeGeometry.materials = [SCNMaterial()]
        //planeGeometry.materials.first?.colorBufferWriteMask = []
        self.planeNode = SCNNode(geometry: planeGeometry)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        super.init()
        
        self.addChildNode(planeNode)
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        self.opacity = 0.5
    }
    
    func update(anchor: ARPlaneAnchor) {
        planeAnchor = anchor
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
    
    required init?(coder aDecoder: NSCoder) {
        print("unimplemented cause dumb")
        exit(0)
    }
}

class Fuzzy: SCNNode {
    let emitter = SCNParticleSystem(named: "glow", inDirectory: "art.scnassets")!
    let parentPlane: Plane
    var age: TimeInterval = 0
    
    init(color: UIColor, plane: Plane) {
        parentPlane = plane
        super.init()
        emitter.particleColorVariation = SCNVector4(0.03, 0.03, 0.03, 0.01)
        emitter.particleColor = color
        self.addParticleSystem(emitter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addCollisions(_ colliders: [SCNNode]) {
        emitter.colliderNodes = colliders
    }
    
    func updateAtTime(deltaT: TimeInterval, colliders: [SCNNode], fleePosition: SCNVector3) {
        age += deltaT
        let dt = Float(deltaT)
        let deltaFlee = float3(fleePosition) - float3(position)
        let signFlee = simd_sign(deltaFlee)
        let d2 = simd_dot(deltaFlee, deltaFlee)
        let strength = max(1, 1/d2)
    
        self.position.x -= signFlee.x * strength * dt / 10
        self.position.z -= signFlee.z * strength * dt / 10
        
        
        let bounds = parentPlane.planeNode.boundingBox
        let minBound = parentPlane.convertPosition(bounds.min, to: self.parent)
        let maxBound = parentPlane.convertPosition(bounds.max, to: self.parent)
        
        
        if self.position.x > maxBound.x {
            self.position.x = maxBound.x
        } else if self.position.x < minBound.x {
            self.position.x = minBound.x
        }
        
        if self.position.z > maxBound.z {
            self.position.z = maxBound.z
        } else if self.position.z < minBound.z {
            self.position.z = minBound.z
            
        }
    }
}


func randCGFloat() -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
}
