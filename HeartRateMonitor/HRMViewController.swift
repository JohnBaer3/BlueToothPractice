
import UIKit
import CoreBluetooth

class HRMViewController: UIViewController {

  @IBOutlet weak var heartRateLabel: UILabel!
  @IBOutlet weak var bodySensorLocationLabel: UILabel!

  let deviceName = "INB-0001"
  let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "00010002-0000-1000-8000-00805F00050F")
  
  var centralManager: CBCentralManager!
  var heartRatePeripheral: CBPeripheral!

  
  override func viewDidLoad() {
    super.viewDidLoad()
    centralManager = CBCentralManager(delegate: self, queue: nil)
    heartRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: heartRateLabel.font!.pointSize, weight: .regular)
  }

  func onHeartRateReceived(_ heartRate: Int) {
    heartRateLabel.text = String(heartRate)
    print("BPM: \(heartRate)")
  }
}


extension HRMViewController: CBCentralManagerDelegate {
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
      case .unknown:
        print("central.state is .unknown")
      case .resetting:
        print("central.state is .resetting")
      case .unsupported:
        print("central.state is .unsupported")
      case .unauthorized:
        print("central.state is .unauthorized")
      case .poweredOff:
        print("central.state is .poweredOff")
      case .poweredOn:
        print("central.state is .poweredOn")
        centralManager.scanForPeripherals(withServices: nil)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    if peripheral.name == deviceName{
      print(peripheral)
      
      heartRatePeripheral = peripheral
      heartRatePeripheral.delegate = self
      centralManager.stopScan()
      centralManager.connect(heartRatePeripheral)
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected!")
    heartRatePeripheral.discoverServices(nil)
  }
}


extension HRMViewController: CBPeripheralDelegate {
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else { return }

    //We go through all the services discovered
    for service in services {
      print(service)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let characteristics = service.characteristics else { return }

    for characteristic in characteristics {
      print(characteristic)
      if characteristic.properties.contains(.read) {
        print("\(characteristic.uuid): properties contains .read")
        peripheral.readValue(for: characteristic)
      }
      if characteristic.properties.contains(.notify) {
        print("\(characteristic.uuid): properties contains .notify")
        peripheral.setNotifyValue(true, for: characteristic)
      }
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    switch characteristic.uuid {
      case heartRateMeasurementCharacteristicCBUUID:
        print(characteristic.value ?? "no value")
        
        //This is where the byte array is I'm preeeeetty sure
        //So grab the different positions in the 16 byte array here...?
        let bodySensorLocation = bodyLocation(from: characteristic)
        bodySensorLocationLabel.text = bodySensorLocation
      default:
        print("Unhandled Characteristic UUID: \(characteristic.uuid)")
    }
  }
  
  private func bodyLocation(from characteristic: CBCharacteristic) -> String {
    guard let characteristicData = characteristic.value,
      let byte = characteristicData.first else { return "Error" }
    
    let arr = characteristicData[8]
    print("bla: \(arr)")
    
    print(byte)
    return String(byte)
    
    //Switch on the different indices of characteristicData - for position 0, 2, 4, 6, 8, 10, 12, 14
    
    
//    switch byte {
//      case 0: return "Other"
//      case 1: return "Chest"
//      case 2: return "Wrist"
//      case 3: return "Finger"
//      case 4: return "Hand"
//      case 5: return "Ear Lobe"
//      case 6: return "Foot"
//      default:
//        return "Reserved for future use"
//    }
  }
  
//  private func heartRate(from characteristic: CBCharacteristic) -> Int {
//    guard let characteristicData = characteristic.value else { return -1 }
//    let byteArray = [UInt8](characteristicData)
//
//    let firstBitValue = byteArray[0] & 0x01
//    if firstBitValue == 0 {
//      // Heart Rate Value Format is in the 2nd byte
//      return Int(byteArray[1])
//    } else {
//      // Heart Rate Value Format is in the 2nd and 3rd bytes
//      return (Int(byteArray[1]) << 8) + Int(byteArray[2])
//    }
//  }
  
}
