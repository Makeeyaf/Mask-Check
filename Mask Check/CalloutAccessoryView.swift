//  Copyright © 2020 Makeeyaf. All rights reserved

import SwiftUI

struct CalloutAccessoryView: View {
    let status: MCRemainStat
    let stock_at: String?
    let created_at: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("마스크 재고: ").bold()
                Text(status.description)
            }.font(.subheadline)
            
            HStack {
                Text("입고시간: ").bold()
                Text(getFormattedDateTime(stock_at))
            }.font(.subheadline)
            
            HStack {
                Spacer()
                Text("\(getFormattedDateTime(created_at)) 기준")
            }
            .font(.caption)
            .foregroundColor(Color.gray)
        }
        .background(Color.clear)
        
        .padding(.vertical, 10)
        .fixedSize()
    }
    
    private func getFormattedDateTime(_ dateTimeInString: String?) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
        inputFormatter.timeZone = .current
        guard let dateTimeInString = dateTimeInString, let dateTime = inputFormatter.date(from: dateTimeInString) else { return "?" }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .short
        outputFormatter.timeZone = .current
        outputFormatter.doesRelativeDateFormatting = true
        
        return outputFormatter.string(from: dateTime)
    }
}

struct CalloutAccessoryView_Previews: PreviewProvider {
    static var previews: some View {
//        let title = "목동약국"
//        let subTitle = "조금"
        let stock_at = "2020/03/20 12:35:00"
        let create_at = "2020/03/20 23:55:00"
        return CalloutAccessoryView(status: MCRemainStat.few, stock_at: stock_at, created_at: create_at).previewLayout(.sizeThatFits)
    }
}
