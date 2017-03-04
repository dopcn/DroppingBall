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
        tmp.backgroundColor = UIColor.orange
        return tmp
        }()
    
    let bottom = UIView(frame: CGRect.zero)
    
    var animator: UIDynamicAnimator!
    
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var added = false
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.white
        
        bottom.frame = CGRect(x: view.frame.size.width/2, y: view.frame.size.height-10, width: view.frame.size.width/2, height: 10)
        bottom.backgroundColor = UIColor.lightGray
        view.addSubview(bottom)
        
        view.addSubview(ball)
        ball.center = CGPoint(x: view.frame.size.width-300, y: -200)
        
        view.addSubview(statusLabel)
        statusLabel.center = view.center
        statusLabel.textAlignment = NSTextAlignment.center
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animator = UIDynamicAnimator(referenceView: view)
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        statusLabel.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        centralManager.stopScan()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension ViewControllerHD: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            print("bluetooth is power off")
            return
        }
        statusLabel.text = "start scan"
        centralManager.scanForPeripherals(withServices: [CBUUID(string: ViewController.serviceUUID)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard -35 < RSSI.intValue && RSSI.intValue < -15 else {
            return
        }
        statusLabel.text = "did discover peripheral"
        if let discoveredPeripheral = self.discoveredPeripheral {
            if discoveredPeripheral == peripheral {
                return
            }
        }
        self.discoveredPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusLabel.text = "fail to connect to peripheral"
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusLabel.text = "peripheral connect success"
        centralManager.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: ViewController.serviceUUID)])
    }
    
}

extension ViewControllerHD: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            statusLabel.text = "\(error!)"
            return
        }
        statusLabel.text = "did discover service"
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: ViewController.characteristicUUID)], for: service)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            statusLabel.text = "\(error!)"
            return
        }
        
        statusLabel.text = "did discover characteristic"
        for characteristic in service.characteristics! {
            if characteristic.uuid.isEqual(CBUUID(string: ViewController.characteristicUUID)) {
                peripheral.setNotifyValue(true, for: characteristic)
                statusLabel.text = "set notify finished"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            statusLabel.text = "\(error!)"
            return
        }
        
        let dict = try! JSONSerialization.jsonObject(with: characteristic.value!, options: []) as! Dictionary<String, Int>
        print(dict)
        let x = dict["x"]!
        let y = dict["y"]!
        ball.center = CGPoint(x: Int(self.view.frame.size.width)/2 + x, y: -y)
        if !added {
            let gravority = UIGravityBehavior(items: [ball])
            animator.addBehavior(gravority)
            let collision = UICollisionBehavior(items: [ball])
            collision.addBoundary(withIdentifier: "boundary" as NSCopying, for: UIBezierPath(rect: bottom.frame))
            animator.addBehavior(collision)
            let itemBehavoir = UIDynamicItemBehavior(items: [ball])
            itemBehavoir.elasticity = 0.6
            animator.addBehavior(itemBehavoir)
            added = true
        } else {
            animator.updateItem(usingCurrentState: ball)
        }
        
    }
    
}

