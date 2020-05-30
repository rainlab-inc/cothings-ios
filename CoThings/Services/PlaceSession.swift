//
//  Session.swift
//  CoThings
//
//  Created by Umur Gedik on 2020/05/05.
//  Copyright © 2020 Umur Gedik. All rights reserved.
//

import SwiftUI
import Combine

class PlaceSession: ObservableObject {
    @Published var connectionStatus: ConnectionStatus
    @Published var rooms: [Room]
    
    let beaconDetector: BeaconDetector
    private let service: CoThingsBackend
	private let notificationService = NotificationService()
    
    private var roomsCancellable: AnyCancellable?
    private var connectionStatusCancellable: AnyCancellable?
    private var beaconEnterCanceller: AnyCancellable?
    private var beaconExitCanceller: AnyCancellable?

	private var notifyOnEnter: Bool = UserDefaults.standard.bool(forKey: NotifyOnEnterKey)
	private var notifyOnExit: Bool = UserDefaults.standard.bool(forKey: NotifyOnExitKey)
	private var notifyWithSound: Bool = UserDefaults.standard.bool(forKey: NotifyWithSoundKey)
	private var notifyWithOneLineMessage: Bool = UserDefaults.standard.bool(forKey: NotifyWithOneLineMessageKey)

    init(service: CoThingsBackend, beaconDetector: BeaconDetector) {
        self.service = service
        self.rooms = []
        self.connectionStatus = service.status
        self.beaconDetector = beaconDetector
        
        self.beaconDetector.stopScanningAll()
        self.roomsCancellable = self.service.roomsPublisher
            .sink {newRooms in
                for oldRoom in Set(self.rooms).subtracting(newRooms) {
                    self.beaconDetector.stopScanning(room: oldRoom)
                }
                
                for newRoom in Set(newRooms).subtracting(self.rooms) {
                    self.beaconDetector.startScanning(room: newRoom)
                }
                
                self.rooms = newRooms
            }
        
        self.connectionStatusCancellable = self.service.statusPublisher
            .assign(to: \.connectionStatus, on: self)
        
        beaconEnterCanceller = self.beaconDetector.enters.sink { roomID in
            self.increasePopulationInBackground(roomID: roomID)
			self.sendNotificationIfEnabled(roomId: roomID, isEntered: true)
        }
        
        beaconExitCanceller = self.beaconDetector.exits.sink { roomID in
            self.decreasePopulationInBackground(roomID: roomID)
			self.sendNotificationIfEnabled(roomId: roomID, isEntered: true)
        }
    }

	private func ensureSocketConnection() {
		service.connectInBackground()
	}

	private func ensureSocketDisconnected() {
		service.disconnectInBackground()
	}
    
    func increasePopulation(roomID: Room.ID) {
        guard
            connectionStatus == .ready,
            let roomIndex = rooms.firstIndex(where: {$0.id == roomID}) else {
            return
        }
        
        var newRoom = rooms[roomIndex]
        newRoom.population += 1
        rooms[roomIndex] = newRoom
        
        service.increasePopulation(roomID: roomID) { res in
            if case .failure = res {
                self.rooms = self.service.rooms
            }
        }
    }
    
    func decreasePopulation(roomID: Room.ID) {
        guard
            connectionStatus == .ready,
            let roomIndex = rooms.firstIndex(where: {$0.id == roomID}) else {
            return
        }
        
        var newRoom = rooms[roomIndex]
        newRoom.population -= 1
        rooms[roomIndex] = newRoom
        
        service.decreasePopulation(roomID: roomID) { res in
            if case .failure = res {
                self.rooms = self.service.rooms
            }
        }
    }

	func increasePopulationInBackground(roomID: Room.ID) {
		ensureSocketConnection()
		service.increasePopulation(roomID: roomID) { _ in
			self.ensureSocketDisconnected()
		}
	}

	func decreasePopulationInBackground(roomID: Room.ID) {
		ensureSocketConnection()
		service.decreasePopulation(roomID: roomID) { _ in
			self.ensureSocketDisconnected()
		}
	}

	func sendNotificationIfEnabled(roomId: Int, isEntered: Bool) {
		if (isEntered && !notifyOnEnter) {
			return
		}

		if (!isEntered && !notifyOnExit) {
			return
		}

		let message = isEntered ? "Entered" : "Exited"
		var title = "Room: \(roomId)"
		title = !notifyWithOneLineMessage ? title : title + " " + message

		notificationService.showNotification(title: title, message: message, withSound: notifyWithSound)
	}
}
