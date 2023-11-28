//
//  navi.swift
//  cenima
//
//  Created by Aniurm on 2023/11/27.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import CoreLocation
import os


class ViewController: UIViewController, NavigationServiceDelegate {
    let logger = Logger(subsystem: "ARTrack", category: "INFO")
    
    var navigationService: NavigationService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
    }
    
    func setupNavigation() {
        // Define two waypoints to travel between
        let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
        let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")
        
        // Set options
        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
        routeOptions.includesSteps = true
        
        // Request a route using MapboxDirections.swift
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first else { return }
                // Create a navigation service
                self?.navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: routeOptions, simulating: .never)
                self?.navigationService?.delegate = self
                guard let self = self else { return }
                // Initialize the NavigationViewController with custom NavigationOptions
                let navigationOptions = NavigationOptions(navigationService: self.navigationService)
                let viewController = NavigationViewController(for: response, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
                viewController.modalPresentationStyle = .fullScreen
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }

    // NavigationServiceDelegate method
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        // log current step
        logger.info("Current step: \(progress.currentLegProgress.currentStep.description)")
    }
}
