//
//  LocationNode.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation
import SpriteKit

///A location node can be added to a scene using a coordinate.
///Its scale and position should not be adjusted, as these are used for scene layout purposes
///To adjust the scale and position of items within a node, you can add them to a child node and adjust them there
open class LocationNode: SCNNode {
    ///Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation!
    
    ///Whether the location of the node has been confirmed.
    ///This is automatically set to true when you create a node using a location.
    ///Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    ///except when the locationEstimateMethod is set to use Core Location data only,
    ///as then it becomes true immediately.
    public var locationConfirmed = false
    
    ///Whether a node's position should be adjusted on an ongoing basis
    ///based on its' given location.
    ///This only occurs when a node's location is within 100m of the user.
    ///Adjustment doesn't apply to nodes without a confirmed location.
    ///When this is set to false, the result is a smoother appearance.
    ///When this is set to true, this means a node may appear to jump around
    ///as the user's location estimates update,
    ///but the position is generally more accurate.
    ///Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true
    
    ///Whether a node's position and scale should be updated automatically on a continual basis.
    ///This should only be set to false if you plan to manually update position and scale
    ///at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true
    
    public var lastNodeUpdate = 0.0
    
    public init(location: CLLocation?) {
        self.location = location
        self.locationConfirmed = location != nil
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class LocationAnnotationNode: LocationNode {
    
    public let titlePlace: String?
    
    ///Subnodes and adjustments should be applied to this subnode
    ///Required to allow scaling at the same time as having a 2D 'billboard' appearance
    public let annotationNode: SCNNode
    
    ///Whether the node should be scaled relative to its distance from the camera
    ///Default value (false) scales it to visually appear at the same size no matter the distance
    ///Setting to true causes annotation nodes to scale like a regular node
    ///Scaling relative to distance may be useful with local navigation-based uses
    ///For landmarks in the distance, the default is correct
    public var scaleRelativeToDistance = false
    
    public init(location: CLLocation?, titlePlace: String?) {
        self.titlePlace = titlePlace
        
        self.annotationNode = SCNNode()
        
        super.init(location: location)
        
        if let plane = createBubble(width: 200, height: 80) {
            annotationNode.geometry = plane
        }
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(annotationNode)
    }
    
    func createBubble(width: CGFloat, height: CGFloat, distance: String! = "0m") -> SCNPlane? {
        guard let bubbleView: BubbleView = Bundle.main.loadNibNamed("BubbleView", owner: self, options: nil)?.first as? BubbleView else {return nil}
        
        let offset = CGFloat(54.0)
        var titlePlaceForBubble =  titlePlace!
        let maxLengh = 20
        if titlePlaceForBubble.count > maxLengh {
            let endIndex = titlePlaceForBubble.index(titlePlaceForBubble.startIndex, offsetBy: maxLengh - 3)
            titlePlaceForBubble = String(titlePlaceForBubble.prefix(upTo: endIndex))
            titlePlaceForBubble.append("...")
        }
        let textWidth = widthOfString(textString: titlePlaceForBubble, font: bubbleView.placeText.font)
        let distanceWidth = widthOfString(textString: distance!, font: bubbleView.distance.font)
        let widthOfBubbleView = offset + textWidth + distanceWidth
        
        let width: CGFloat = widthOfBubbleView
        let height: CGFloat = 80
        
        bubbleView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        bubbleView.placeText.text = titlePlaceForBubble
        bubbleView.distance.text = distance
        bubbleView.layoutIfNeeded()
        
        UIGraphicsBeginImageContextWithOptions(bubbleView.bounds.size, false, UIScreen.main.scale);
        bubbleView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let plane = SCNPlane(width: width / 100.0, height: height / 100.0)
        plane.firstMaterial!.diffuse.contents = screenShot
        plane.firstMaterial!.lightingModel = .constant
        
        return plane
    }
    
    func updateDistance(distanceToLocation: CLLocation?) {
        
        if let location = distanceToLocation {
            let distanceString = "\(String(format: "%.2fm", self.location.distance(from: location)))"
            if let plane = createBubble(width: 200, height: 80, distance: distanceString) {
               annotationNode.geometry = plane
            }
        }
    }
    
    func widthOfString(textString: String, font: UIFont) -> CGFloat{
        let fontAttributes = [NSAttributedStringKey.font: font]
        let size = textString.size(withAttributes: fontAttributes)
        return size.width
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
