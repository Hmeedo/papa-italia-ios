//
//  NavigationAppSheet.swift
//  AnsSaloon
//
//  Created by Hameed Dahabry on 24/05/2024.
//

import UIKit
import SwiftUI

struct NavigationAppSheet: View {
    let location: Location
    @Binding var showActionSheet: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Grid(alignment: .leading,verticalSpacing: 0) {
                Divider()
                ForEach(NavigationApp.allCases) { app in
                    GridRow {
                        VStack(spacing: 0) {
                            Button(action: {
                                app.open(location: location)
                                showActionSheet = false
                            }, label: {
                                HStack {
                                    Spacer()
                                    Image(app.icon)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(8)
                                        .padding(2)
                                    
                                    Text(app.displayName)
                                        .frame(width: 150, alignment: .leading)
                                    Spacer()
                                }
                            })
                            .frame(height: 50)
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                
                Button(action: {
                    showActionSheet = false
                }, label: {
                    HStack {
                        Spacer()
                        Text(Constants.cancelTitle)
                            .frame(width: 150, alignment: .center)
                            .bold()
                            .foregroundColor(.red)
                        Spacer()
                    }
                })
                .frame(height: 50)
                .padding(.vertical, 4)
            }
            .background(.regularMaterial)
            
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showActionSheet = false
        }
        .animation(.spring())
        .transition(.move(edge: .bottom))
    }
}


enum NavigationApp: CaseIterable, Identifiable {
    var id: Self { self }
    
    case waze
    case googleMaps
    case appleMaps
    
    var displayName : String {
        switch self {
        case .waze:
            "Waze"
        case .googleMaps:
            "Google Maps"
        case .appleMaps:
            "Apple Maps"
        }
    }
    
    var icon : String {
        switch self {
        case .waze:
            return "waze"
        case .googleMaps:
            return "googlemaps"
        case .appleMaps:
            return "applemaps"
        }
    }
    
    func url(location : Location) -> URL {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        switch self {
        case .waze:
            if let url = URL(string: "waze://"),UIApplication.shared.canOpenURL(url) == true {
                let link = "https://waze.com/ul?ll=\(latitude),\(longitude)&navigate=yes"
                return URL(string: link)!
            } else {
                let link = "http://itunes.apple.com/us/app/id323229106"
                return URL(string: link)!
            }
        case .googleMaps:
            if let url = URL(string: "comgooglemaps://"),UIApplication.shared.canOpenURL(url) == true {
                let link = "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving"
                return URL(string: link)!
            } else {
                let link = "https://itunes.apple.com/us/app/google-maps/id585027354?mt=8"
                return URL(string: link)!
            }
        case .appleMaps:
            let link = "https://maps.apple.com/?daddr=\(latitude),\(longitude)&t=k"
            return URL(string: link)!
        }
    }
    
    func open(location : Location) {
        UIApplication.shared.open(self.url(location: location))
    }
}
