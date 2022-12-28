//
//  HomeView.swift
//  whisper-ios
//
//  Created by creevo on 2022/12/29.
//  Copyright © 2022 jp.openly. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @State var isActive: Bool = false
    var body: some View {
        VStack{
            RecordList()
            RecordButtonPane(isActive: $isActive)
                .frame(height: 150)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
