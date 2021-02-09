//
//  ContentView.swift
//  Uber Clone
//
//  Created by 亚飞 on 2021/2/8.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    var body: some View {
        
        Home()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Home : View {
    
    @State var map = MKMapView()
    @State var manager = CLLocationManager()
    @State var alert = false
    @State var source : CLLocationCoordinate2D!
    @State var destination : CLLocationCoordinate2D!
    @State var name = ""
    @State var distance = ""
    @State var time = ""
    
    var body: some View {
        
        ZStack (alignment: .bottom){
            
            VStack {
                
                HStack {
                    
                    VStack(alignment: .leading, spacing: 15, content: {
                        
                        Text("Pick a Location")
                            .font(.title)
                            
                        if self.destination != nil {
                            
                            Text(self.name)
                                .fontWeight(.bold)
                        }
                    })
                    
                    Spacer()
                }
                .foregroundColor(.black)
                .padding()
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                .background(Color.white)
                
                MapView(map: self.$map, manager: self.$manager, alert: self.$alert, source: self.$source, destination: self.$destination,name: self.$name, distance: self.$distance, time: self.$time)
                    .onAppear() {
                        
                        self.manager.requestAlwaysAuthorization()
                    }
            }
            
            if self.destination != nil {
                
                VStack(spacing: 20) {
                    
                    HStack {
                        
                        VStack(spacing: 15) {
                            
                            Text("Destination")
                                .fontWeight(.bold)
                            Text(self.name)
                            
                            Text("Distance -" + self.distance + " KM")
                            
                            Text("Expected Time -" + self.time + " Min")
                        }
                        .foregroundColor(Color.black)
                        
                        Spacer()
                    }
                    
                    Button {
                        
                    } label: {
                        
                        Text("Book Now")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(width: UIScreen.main.bounds.width / 2)
                    }
                    .background(Color.red)
                    .clipShape(Capsule())

                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom)
                .background(Color.white)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: self.$alert, content: {
            
            Alert(title: Text("Error"), message: Text("Please Enable location In Setting!!!"), dismissButton: .destructive(Text("OK")))
        })
    }
}

struct MapView : UIViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        
        return MapView.Coordinator(parent1: self)
    }
    
    
    @Binding var map : MKMapView
    @Binding var manager : CLLocationManager
    @Binding var alert : Bool
    @Binding var source : CLLocationCoordinate2D!
    @Binding var destination : CLLocationCoordinate2D!
    @Binding var name : String
    @Binding var distance : String
    @Binding var time : String
    
    
    func makeUIView(context: Context) -> MKMapView {
         
        map.delegate = context.coordinator
        manager.delegate = context.coordinator
        map.showsUserLocation = true
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.tap(ges:)))
        map.addGestureRecognizer(gesture)
        return map
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        
        var parent : MapView
        
        init(parent1 : MapView) {
            
            parent = parent1
        }
        

        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

            if status == .denied {

                self.parent.alert.toggle()
            }
            else {

                self.parent.manager.startUpdatingLocation()
            }
        }
        
        
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            
            let region = MKCoordinateRegion(center: locations.last!.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            
            self.parent.source = locations.last!.coordinate
            
            self.parent.map.region = region
        }
        
        @objc func tap(ges: UITapGestureRecognizer) {
            
            let location = ges.location(in: self.parent.map)
            let mplocation = self.parent.map.convert(location, toCoordinateFrom: self.parent.map)
            
            let point = MKPointAnnotation()
//            point.title = "Marked"
            point.subtitle = "Destination"
            point.coordinate = mplocation
            
            self.parent.destination = mplocation
            
            let decoder = CLGeocoder()
            decoder.reverseGeocodeLocation(CLLocation(latitude: mplocation.latitude, longitude: mplocation.longitude)) { (places, err) in
                
                if err != nil {
                    
                    print((err?.localizedDescription)!)
                    return
                }
                
                self.parent.name = places?.first?.name ?? ""
                point.title = places?.first?.name ?? ""
            }
            
            let req = MKDirections.Request()
            req.source = MKMapItem(placemark: MKPlacemark(coordinate: self.parent.source))
            req.destination = MKMapItem(placemark: MKPlacemark(coordinate: mplocation))
            
            let directions = MKDirections(request: req)
            
            directions.calculate { (dir, err) in
                
                if err != nil {
                    
                    print((err?.localizedDescription)!)
                    return
                }
                
                let polyline = dir?.routes[0].polyline
                
                let dis = dir?.routes[0].distance as! Double
                self.parent.distance = String(format: "%.1lf", dis / 1000)
                
                let time = dir?.routes[0].expectedTravelTime as! Double
                self.parent.time = String(format: "%.1lf", time / 60)
                
                self.parent.map.removeOverlays(self.parent.map.overlays)
                
                self.parent.map.addOverlay(polyline!)
                self.parent.map.setRegion(MKCoordinateRegion(polyline!.boundingMapRect), animated: true)
            }
            
            self.parent.map.removeAnnotations(self.parent.map.annotations)
            self.parent.map.addAnnotation(point)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
            let over = MKPolylineRenderer(overlay: overlay)
            over.strokeColor = .red
            over.lineWidth = 3
            return over
        }
    }
}
