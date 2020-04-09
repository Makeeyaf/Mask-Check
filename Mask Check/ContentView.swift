//  Copyright © 2020 Makeeyaf. All rights reserved

import SwiftUI
import MapKit

struct ContentView: View {
    private let mapViewController = MCMapViewController()
    @State private var userTrackingMode: MKUserTrackingMode = .follow
    @State private var isSearchVisible: Bool = false
    @State private var isNoticeVisible: Bool = false
//    @State private var radius: Int = 500
    
    var body: some View {
        ZStack {
            MCMapControl(userTrackingMode: $userTrackingMode)
                .environmentObject(self.mapViewController)
                .edgesIgnoringSafeArea(.all)
                
            HStack {
                VStack {
                    Spacer()
                    helpView()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .shadow(radius: 7)
                        .padding()
                }
                Spacer()
                VStack {
                    Spacer()
//                    MCUserTrackingButton()
//                        .environmentObject(MCUserTrackingButtonController(mapView: self.mapViewController.mapView))
//                        .fixedSize()
                    VStack {
                        Button(action: {
                            self.isSearchVisible = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .modifier(MapIcon())
                        }
                        Divider()
                            .padding(.vertical, 0.5)
                            .background(Color(UIColor.systemFill))
                        Button(action: {
                            switch self.userTrackingMode {
                            case .follow:
                                self.userTrackingMode = .followWithHeading
                            case .followWithHeading:
                                self.userTrackingMode = .none
                            case .none:
                                self.userTrackingMode = .follow
                            @unknown default:
                                self.userTrackingMode = .none
                            }
                        }) {
                            Image(systemName: self.getIcon())
                                .modifier(MapIcon())
                        }
                    }
                    .modifier(MapButton())

                    
                }.padding()
                
            }.padding()
        }
        .sheet(isPresented: $isSearchVisible) {
            SearchView(mapViewController: self.mapViewController)
        }
        .alert(isPresented: $isNoticeVisible) {
            Alert(title: Text("안내"), message: Text("마스크 종류는 성인용 마스크만 대상으로 하며, 재고정보는 5분~10분의 지연시간이 있습니다."), primaryButton: .default(Text("확인")), secondaryButton: .destructive(Text("다시 표시하지 않음"), action: {
                UserDefaults.standard.set(true, forKey: "notice_disabled")
            }))
        }
        .onAppear {
            if !UserDefaults.standard.bool(forKey: "notice_disabled") {
                self.isNoticeVisible = true
            }
            
        }
        
    }
    
    private func getIcon() -> String {
        switch userTrackingMode {
        case .follow:
            return "location.fill"
        case .followWithHeading:
            return "location.north.line.fill"
        default:
            return "location"
        }
        
    }
    
}

fileprivate struct MapIcon: ViewModifier {
    var fontColor: Color = Color("buttonColor")

    func body(content: Content) -> some View {
        content
            .foregroundColor(self.fontColor)
            .font(.title)
            .frame(width: 50, height: 50)
    }
}

fileprivate struct MapButton: ViewModifier {
    var backgroundColor: Color = .init(UIColor.secondarySystemBackground)
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .fixedSize()
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(radius: 7)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.colorScheme, .light)
            ContentView().environment(\.colorScheme, .dark)
            ContentView().environment(\.colorScheme, .light).previewDevice(PreviewDevice(rawValue: "iPhone SE"))
        }
        
    }
}
