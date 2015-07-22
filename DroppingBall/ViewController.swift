//
//  ViewController.swift
//  DroppingBall
//
//  Created by weizhou on 7/18/15.
//  Copyright (c) 2015 weizhou. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    static let characteristicUUID = "36BC9D9B-5FF0-4860-9DD9-FEB5CC019186"
    static let serviceUUID = "0E76CFF0-8F72-4302-83ED-16777697544A"
    
    let statusLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 30))

    let ball: UIView = {
        let tmp = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        tmp.layer.cornerRadius = 50
        tmp.backgroundColor = UIColor.orangeColor()
        return tmp
        }()
    
    let bottom = UIView(frame: CGRectZero)
    
    var animator: UIDynamicAnimator!
    var peripheralManager: CBPeripheralManager!
    var characteristic = CBMutableCharacteristic(type: CBUUID(string: ViewController.characteristicUUID), properties: .Notify, value: nil, permissions: .Readable)
    
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        
        bottom.frame = CGRect(x: 0, y: view.frame.size.height-10, width: view.frame.size.width/2, height: 10)
        bottom.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(bottom)
        
        view.addSubview(ball)
        ball.center = CGPoint(x: view.frame.size.width/2-100, y: view.frame.size.height - 50 - 10)
        
        view.addSubview(statusLabel)
        statusLabel.center = view.center
        statusLabel.textAlignment = .Center
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gr = UIPanGestureRecognizer(target: self, action: "panned:")
        ball.addGestureRecognizer(gr)
        
        animator = UIDynamicAnimator(referenceView: view)
        let gravority = UIGravityBehavior(items: [ball])
        let collison = UICollisionBehavior(items: [ball])
        collison.addBoundaryWithIdentifier("boundary", forPath: UIBezierPath(rect: bottom.frame))
        let itemBehavior = UIDynamicItemBehavior(items: [ball])
        itemBehavior.elasticity = 0.6
        animator.addBehavior(gravority)
        animator.addBehavior(collison)
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        let gr2 = UITapGestureRecognizer(target: self, action: "tapped:")
        view.addGestureRecognizer(gr2)
        
        
        statusLabel.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        peripheralManager.stopAdvertising()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        guard peripheral.state == .PoweredOn else {
            print("bluetooth is power off\n")
            return
        }
        let service = CBMutableService(type: CBUUID(string: ViewController.serviceUUID), primary: true)
        service.characteristics = [characteristic]
        peripheralManager.addService(service)
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: ViewController.serviceUUID)]])
        statusLabel.text = "begin advertising"
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        statusLabel.text = "did subscribed"
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        statusLabel.text = "did unsubscribe"
    }
    
}

extension ViewController {
    
    func panned(sender: UIPanGestureRecognizer) {
        ball.center = sender.locationInView(view)
        if sender.state == UIGestureRecognizerState.Ended {
            if ball.center.x > self.view.frame.size.width/2 {
                let json = ["x": ball.center.x - self.view.frame.size.width/2, "y": ball.center.y + 100]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
                peripheralManager.updateValue(data, forCharacteristic: characteristic, onSubscribedCentrals: nil)
                statusLabel.text = "data sended"    
            }
            animator.updateItemUsingCurrentState(ball)
        }
    }
    
    func tapped(sender: UITapGestureRecognizer) {
        ball.center = CGPoint(x: 200, y: 200)
        animator.updateItemUsingCurrentState(ball)
    }
}