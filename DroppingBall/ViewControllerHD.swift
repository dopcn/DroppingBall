//
//  ViewControllerHDViewController.swift
//  DroppingBall
//
//  Created by weizhou on 7/18/15.
//  Copyright (c) 2015 weizhou. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewControllerHD: UIViewController {
    
    let statusLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 500, height: 30))

    let ball: UIView = {
        let tmp = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        tmp.layer.cornerRadius = 50
        tmp.backgroundColor = UIColor.orangeColor()
        return tmp
        }()
    
    let bottom = UIView(frame: CGRectZero)
    
    var animator: UIDynamicAnimator!
    
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var added = false
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.whiteColor()
        
        bottom.frame = CGRect(x: view.frame.size.width/2, y: view.frame.size.height-10, width: view.frame.size.width/2, height: 10)
        bottom.backgroundColor = UIColor.lightGrayColor()
        view.addSubview(bottom)
        
        view.addSubview(ball)
        ball.center = CGPoint(x: view.frame.size.width-300, y: -200)
        
        view.addSubview(statusLabel)
        statusLabel.center = view.center
        statusLabel.textAlignment = NSTextAlignment.Center
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator = UIDynamicAnimator(referenceView: view)
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        statusLabel.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        centralManager.stopScan()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension ViewControllerHD: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        guard central.state == .PoweredOn else {
            print("bluetooth is power off")
            return
        }
        statusLabel.text = "start scan"
        centralManager.scanForPeripheralsWithServices([CBUUID(string: ViewController.serviceUUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        guard -35 < RSSI.integerValue && RSSI.integerValue < -15 else {
            return
        }
        statusLabel.text = "did discover peripheral"
        if let discoveredPeripheral = self.discoveredPeripheral {
            if discoveredPeripheral == peripheral {
                return
            }
        }
        self.discoveredPeripheral = peripheral
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        statusLabel.text = "fail to connect to peripheral"
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        statusLabel.text = "peripheral connect success"
        centralManager.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: ViewController.serviceUUID)])
    }
    
}

extension ViewControllerHD: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if error != nil {
            statusLabel.text = "\(error!.domain)"
            return
        }
        statusLabel.text = "did discover service"
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: ViewController.characteristicUUID)], forService: service)
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error != nil {
            statusLabel.text = "\(error!.domain)"
            return
        }
        
        statusLabel.text = "did discover characteristic"
        for characteristic in service.characteristics! {
            if characteristic.UUID.isEqual(CBUUID(string: ViewController.characteristicUUID)) {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                statusLabel.text = "set notify finished"
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            statusLabel.text = "\(error!.domain)"
            return
        }
        
        let dict = try! NSJSONSerialization.JSONObjectWithData(characteristic.value!, options: []) as! Dictionary<String, Int>
        print(dict)
        let x = dict["x"]!
        let y = dict["y"]!
        ball.center = CGPoint(x: Int(self.view.frame.size.width)/2 + x, y: -y)
        if !added {
            let gravority = UIGravityBehavior(items: [ball])
            animator.addBehavior(gravority)
            let collision = UICollisionBehavior(items: [ball])
            collision.addBoundaryWithIdentifier("boundary", forPath: UIBezierPath(rect: bottom.frame))
            animator.addBehavior(collision)
            let itemBehavoir = UIDynamicItemBehavior(items: [ball])
            itemBehavoir.elasticity = 0.6
            animator.addBehavior(itemBehavoir)
            added = true
        } else {
            animator.updateItemUsingCurrentState(ball)
        }
        
    }
    
}

