//
//  HomeView.swift
//  whisper-ios
//
//  Created by creevo on 2022/12/29.
//  Copyright © 2022 jp.openly. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack{
            RecordList()
            RecognitionPane()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
