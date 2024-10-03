//
//  MapView.swift
//  AnsSaloon
//
//  Created by Hameed Dahabry on 23/05/2024.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapsViewModel()
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        NavigationView {
            if #available(iOS 17.0, *) {
                Map(coordinateRegion: $viewModel.region, annotationItems: [viewModel.location], annotationContent: { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        Image("logo_small")
                    }
                })
                .allowsHitTesting(viewModel.showNavigationActionSheet == false)
                .mapStyle(.hybrid(elevation: .realistic))
                .navigationTitle(locationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text(Constants.cancelTitle)
                        })
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.showNavigationActionSheet = true
                        }, label: {
                            Image(systemName: "location.circle")
                        })
                        
                    }
                }.overlay {
                    if viewModel.showNavigationActionSheet {
                        NavigationAppSheet(location: viewModel.location,
                                           showActionSheet: $viewModel.showNavigationActionSheet)
                        
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
        .ignoresSafeArea()
    }
    
    var locationTitle: String {
        if Constants.selectedLangauge == "he" {
            "מיקום"
        }else {
            "الموقع"
        }
    }
}

class MapsViewModel : ObservableObject {
    @Published var showNavigationActionSheet = false
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.860010, longitude: 35.366690),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var location : Location {
        Location(name: "Papa Italia", coordinate: CLLocationCoordinate2D(latitude: 32.860010, longitude: 35.366690))
    }
}

struct Location: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
}
