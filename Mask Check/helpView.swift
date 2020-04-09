//  Copyright © 2020 Makeeyaf. All rights reserved

import SwiftUI

struct helpView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(MCRemainStat.plenty.color))
                Text("\(MCRemainStat.plenty.description)")
            }
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(MCRemainStat.some.color))
                Text("\(MCRemainStat.some.description)")
            }
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(MCRemainStat.few.color))
                Text("\(MCRemainStat.few.description)")
            }
        }
        .padding()
    }
}

struct helpView_Previews: PreviewProvider {
    static var previews: some View {
        helpView().previewLayout(.sizeThatFits)
    }
}
