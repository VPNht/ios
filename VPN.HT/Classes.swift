//
//  Classes.swift
//  VPN.HT
//
//  Created by Douwe Bos on 17-05-15.
//  Copyright (c) 2015 Douwe Bos. All rights reserved.
//
import UIKit
import MapKit
import Security

struct StaticVar {
	static let lightBackgroundColor = UIColor(red: 237/255, green: 237/255, blue: 237/255, alpha: 1)
	static let darkBackgroundColor = UIColor(red: 90/255, green: 90/255, blue: 90/255, alpha: 1)
	static let greenBackgroundColor = UIColor(red: 44/255, green: 199/255, blue: 106/255, alpha: 1)
	static let redBackgroundColor = UIColor(red: 199/255, green: 44/255, blue: 44/255, alpha: 1)
}

class IpAnnotation: NSObject, MKAnnotation {
	var title: String?
	var subtitle: String?
	var ipAddress: String?
	var location: String?
	var coordinate: CLLocationCoordinate2D
	var categoryID = 0
	
	init(coordinate: CLLocationCoordinate2D) {
		self.coordinate = coordinate
		super.init()
	}
}

class vpnServer {
	let country: String!
	let city: String!
	let ip: String!
	let long: Float!
	let lat: Float!
	
	init(country: String, city: String!, ip: String!, long: Float!, lat: Float!) {
		self.country = country
		self.city = city
		self.ip = ip
		self.long = long
		self.lat = lat
	}
}
