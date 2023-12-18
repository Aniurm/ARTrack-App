//
//  ContentView.swift
//  cenima
//
//  Created by Aniurm on 2023/11/27.
//

import SwiftUI
import CoreBluetooth

let SERVICE_UUID = CBUUID(string: "12a59900-17cc-11ec-9621-0242ac130002")

struct NaviView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Update the view controller if needed
    }
}

class BluetoothViewModel: NSObject, ObservableObject, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?

    // Record the device we want to connect to.
    private var peripheral: CBPeripheral?

    var writableCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)

        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YYYY-MM-dd HH:mm:ss" 

        // Send a message to the device every 1 seconds.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.sendData("Hello, ARTrack! " + dateformatter.string(from: Date()))
        }
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
            print("Status: Scanning for peripherals...")
        } else {
            print("Error: Bluetooth not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // We want the device with the name "ARTrack"
        if peripheral.name == "ARtrack" {
            self.centralManager?.stopScan()
            self.peripheral = peripheral
            self.centralManager?.connect(peripheral, options: nil)
            print("Status: Found ARTrack!")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            peripheral.delegate = self
            peripheral.discoverServices(nil)
            print("Status: Connected to ARTrack!")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        print("Log: All services: \(peripheral.services ?? [])")

        if let service = peripheral.services?.first(where: { $0.uuid == SERVICE_UUID }) {
            print("Log: Service: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        print("Log: All characteristics: \(service.characteristics ?? [])")

        for characteristic in service.characteristics ?? [] {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
                print("Log: Discovered writable characteristic: \(characteristic)")
            }
        }
    }

    func sendData(_ data: String) {
        if let peripheral = self.peripheral, let characteristic = writableCharacteristic {
            let dataToSend = data.data(using: .utf8)
            peripheral.writeValue(dataToSend!, for: characteristic, type: .withResponse)
            print("Status: Sent data: \(data)")
        }
    }
}

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    var body: some View {
        VStack {
            // Embed the UIViewControllerRepresentable
            NaviView()
        }
        .padding()
    }
}
