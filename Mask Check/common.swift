//  Copyright © 2020 Makeeyaf. All rights reserved

import Foundation
import MapKit
import Combine

enum MCRemainStat {
    /*
     재고 상태
     100개 이상(녹색): 'plenty'
     30개 이상 100개미만(노랑색): 'some'
     2개 이상 30개 미만(빨강색): 'few'
     1개 이하(회색): 'empty'
     판매중지: 'break'
     */

    case plenty
    case some
    case few
    case empty
    case none
    case unknown
    
    var status: String {
        switch self {
        case .plenty:
            return "plenty"
        case .some:
            return "some"
        case .few:
            return "few"
        case .empty:
            return "empty"
        case .none:
            return "break"
        case .unknown:
            return "unknown"
        }
    }
    
    var description: String {
        switch self {
        case .plenty:
            return "100개 이상"
        case .some:
            return "30 ~ 100개"
        case .few:
            return "30개 이하"
        case .empty:
            return "없음"
        case .none:
            return "중지"
        case .unknown:
            return "미상"
        }
    }
    
    var color: UIColor {
        switch self {
        case .plenty:
            return UIColor.systemGreen
        case .some:
            return UIColor.systemYellow
        case .few:
            return UIColor.systemRed
        case .empty:
            return UIColor.systemGray
        case .none:
            return UIColor.black
        case .unknown:
            return UIColor.black
        }
    }
}

struct MCStoreStatus {
    let status: String
    let color: UIColor
}


final class MCMapPin: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let remain_stat: MCRemainStat
    let stock_at: String?
    let created_at: String?

    init(_ store: MCStore) {
        title = store.name
        stock_at = store.stock_at
        created_at = store.created_at
        coordinate = CLLocationCoordinate2D(latitude: store.lat, longitude: store.lng)
        
        if let status = store.remain_stat {
            switch status {
            case MCRemainStat.plenty.status:
                remain_stat = .plenty
                subtitle = MCRemainStat.plenty.description
            case MCRemainStat.some.status:
                remain_stat = .some
                subtitle = MCRemainStat.some.description
            case MCRemainStat.few.status:
                remain_stat = .few
                subtitle = MCRemainStat.few.description
            case MCRemainStat.empty.status:
                remain_stat = .empty
                subtitle = MCRemainStat.empty.description
            default:
                remain_stat = .none
                subtitle = MCRemainStat.none.description
            }
        }
        else {
            remain_stat = .unknown
            subtitle = MCRemainStat.unknown.description
        }
    }
}

/*
 위도(wgs84 좌표계) / 최소:33.0, 최대:43.0
 경도(wgs84 표준) / 최소:124.0, 최대:132.0
 반경(미터) / 최대 5000(5km)까지 조회 가능
 */
final class MCCheck {
    let host: String = "8oi9s0nnth.apigw.ntruss.com"
//    // Debounce 사용할 경우
//    var position: CLLocationCoordinate2D = .init(latitude: 36.378218, longitude: 127.834492)
//    var radius: Int = 1000
//    private var workItem: DispatchWorkItem?
//    private var delay: Double = 0.3
//
//
//    func fetch(at position: CLLocationCoordinate2D, in radius: Int) {
//        self.position = position
//        self.radius = radius
//        self.workItem?.cancel()
//        let workItem = DispatchWorkItem { [unowned self] in
//            self.getStore(at: self.position, in: self.radius)
//        }
//        self.workItem = workItem
//        DispatchQueue.main.asyncAfter(deadline: .now() + self.delay, execute: workItem)
//    }
    
    func getStore(at position: CLLocationCoordinate2D, in radius: Int, completion: @escaping (MCResponse) -> Void) {
        #if DEBUG
        print("\(type(of: self)).\(#function)")
        #endif
        var store = URLComponents()
        store.scheme = "https"
        store.host = host
        store.path = "/corona19-masks/v1/storesByGeo/json"
        store.queryItems = [
            URLQueryItem(name: "lat", value: "\(position.latitude)"),
            URLQueryItem(name: "lng", value: "\(position.longitude)"),
            URLQueryItem(name: "m", value: "\(radius)")
        ]
        
        guard let storeURL = store.url else { fatalError("Invalid API Path") }
        if position.latitude < 33 || position.latitude > 43 || position.longitude < 124 || position.longitude > 132 {
            completion(MCResponse(count: 0, stores: []))
        } else {
            request(storeURL, completion: completion)
        }
    }
    
    private var cancelable: AnyCancellable?
    
    private func request(_ url: URL, completion: @escaping (MCResponse) -> Void) {
        self.cancelable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
        .decode(type: MCResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    #if DEBUG
                    print("\(error.localizedDescription)")
                    #endif
                }
            }, receiveValue: { response in
                #if DEBUG
                print("Total: \(response.count)")
                #endif
                completion(response)
            })
    }
}

struct MCResponse: Codable {
    let count: Int
    let stores: [MCStore]
}

struct MCStore: Codable {
    let name: String
    let lat: Double
    let lng: Double
    let stock_at: String?
    let remain_stat: String?
    let created_at: String?
}
