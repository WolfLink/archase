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
        planeGeometry.materials.first?.colorBufferWriteMask = []
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
    
    func updateAtTime(deltaT: TimeInterval, colliders: [SCNNode], fleePosition: SCNVector3, cameraPosition: SCNVector3, cameraAngle: Float, fuzzies: [Fuzzy]) {
        age += deltaT
        let dt = Float(deltaT)
        let originalPosition = float3(position)
        
        // factor for fleeing camera target
        let deltaFlee = float3(fleePosition) - originalPosition
        let signFlee = simd_sign(deltaFlee)
        let d2 = simd_dot(deltaFlee, deltaFlee)
        let strength = max(1, 1/d2)
        
        var updatedPosition = originalPosition
        updatedPosition -= signFlee * strength * dt / 10
        
        // factor for fleeing camera position
        let deltaCam = float3(fleePosition) - originalPosition
        let signCam = simd_sign(deltaCam)
        let dc2 = simd_dot(deltaCam, deltaCam)
        let cstrength = max(1, 1/dc2)
        
        updatedPosition -= signCam * cstrength * dt / 10

        // factor for fleeing other fuzzies
        for fuzzy in fuzzies {
            guard fuzzy != self else { continue }
            let deltaFuzz = float3(fuzzy.position) - originalPosition
            let signFuzz = simd_sign(deltaFuzz)
            let d2f = simd_dot(signFuzz, signFuzz)
            let strf = max(1, 1/d2f)
            updatedPosition -= signFuzz * strf * dt / 20
        }
        
        // factor for fleeing camera angle
        /*let viewVec = float3(fleePosition) - float3(cameraPosition)
        let myVec = originalPosition - float3(cameraPosition)
        let newDirection = simd_cross(myVec, float3(0,1,0))
        let newDirNorm = simd_normalize(newDirection)
        
        updatedPosition += newDirNorm * dt/10
        print(myVec - viewVec)*/
        /*let viewVec = float3(fleePosition) - float3(cameraPosition)
        let meVec = originalPosition - float3(fleePosition)
        let newVec = simd_cross(viewVec, meVec)
        updatedPosition += newVec * dt / 10*/
        /*let myAngle = atan2(originalPosition.y - cameraPosition.y, originalPosition.x - cameraPosition.x)
        let theirAngle = atan2(fleePosition.y - cameraPosition.y, fleePosition.x - cameraPosition.x)
        let angleStrength = myAngle - cameraAngle
        let direction = simd_cross(originalPosition - float3(cameraPosition), float3(0, 1, 0))
        let normDir = simd_normalize(direction)
        updatedPosition += normDir * dt * max(1/(angleStrength*10), 0.05)*/
        //updatedPosition -= angleStrength * dt * normDir
       // print("looking at: \(myAngle - theirAngle)")
        
        
        
        //apply hard bounds
        let pcenter = float3(parentPlane.planeNode.boundingSphere.center)
        let hardDistance = distance22D(A: updatedPosition, B: pcenter)
        let hardLimit = max(parentPlane.planeNode.boundingSphere.radius * parentPlane.planeNode.boundingSphere.radius, 1)
        if hardDistance < hardLimit {
            self.position = SCNVector3(updatedPosition.x, originalPosition.y, updatedPosition.z)
        } else {
            let ratio = sqrt(hardLimit / hardDistance)
            let finalDelta = (updatedPosition - pcenter) * ratio
            updatedPosition = originalPosition + finalDelta
            updatedPosition = updatedPosition * strength + originalPosition * (1-strength)
            self.position = SCNVector3(updatedPosition.x, originalPosition.y, updatedPosition.z)
        }
    }
}
let strength = 0.01
func distance22D(A: float3, B: float3) -> Float {
    let deltaX = A.x - B.x
    let deltaZ = A.z - B.z
    return Float(deltaX * deltaX + deltaZ * deltaZ)
}

func randCGFloat() -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
}
