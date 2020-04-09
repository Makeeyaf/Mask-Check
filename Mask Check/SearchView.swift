//  Copyright © 2020 Makeeyaf. All rights reserved

import SwiftUI
import MapKit

struct SearchView: View {
    let mapViewController: MCMapViewController
    @State var address: [MCMapItem] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                MCSearchBar(data: $address, center: mapViewController.mapView.region.center)
                List {
                    ForEach(address, id: \.id) { datum in
                        VStack(alignment: .leading) {
                            Text("\(datum.placemark.name ?? "")")
                            Text("\(datum.placemark.title ?? "")").font(.caption)
                        }
                        .onTapGesture {
                            guard let selectedRegion = datum.placemark.region as? CLCircularRegion else { return }
                            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            self.mapViewController.mapView.setRegion(MKCoordinateRegion(center: selectedRegion.center, span: span), animated: true)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .gesture(DragGesture().onChanged{_ in UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)})
            }
            .navigationBarTitle("검색", displayMode: .inline)
            .navigationBarItems(leading: Button("취소") {
                self.presentationMode.wrappedValue.dismiss()
            })
        }
        
    }
    
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let mapViewController = MCMapViewController()
        return SearchView(mapViewController: mapViewController)
    }
}


struct MCSearchBar: UIViewRepresentable {
    @Binding var data: [MCMapItem]
    var center: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
    }
    
    func makeCoordinator() -> MCSearchBarCoordinator {
        let span = MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        let region = MKCoordinateRegion(center: self.center, span: span)
        return MCSearchBarCoordinator(data: $data, at: region)
    }
    
    class MCSearchBarCoordinator: NSObject, UISearchBarDelegate {
        @Binding var data: [MCMapItem]
        var region: MKCoordinateRegion
        
        init(data: Binding<[MCMapItem]>, at region: MKCoordinateRegion) {
            _data = data
            self.region = region
            super.init()
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            #if DEBUG
            print("\(type(of: self)).\(#function)")
            #endif
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            #if DEBUG
            print("\(type(of: self)).\(#function)")
            print("\(searchBar.text ?? "empty")")
            #endif
            
            if !(searchBar.text?.isEmpty ?? true) {
                #if DEBUG
                print("not empty")
                #endif
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = searchBar.text
                request.resultTypes = [.address, .pointOfInterest]
                request.pointOfInterestFilter = .includingAll
                request.region = region
                
                let search = MKLocalSearch(request: request)
                search.start { (response, error) in
                    if let response = response {
                        self.data = response.mapItems.filter({$0.placemark.countryCode == "KR" }).map { MCMapItem(placemark: $0.placemark)}
                        #if DEBUG
                        print("\(self.data.debugDescription)")
                        #endif
                    }
                }
            } else {
                self.data = []
            }
            
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            #if DEBUG
            print("\(type(of: self)).\(#function)")
            #endif
        }
    }
}


struct MCMapItem {
    let id = UUID()
    let placemark: MKPlacemark
}
