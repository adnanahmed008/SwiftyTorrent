//
//  FilesView.swift
//  SwiftyTorrent
//
//  Created by Danylo Kostyshyn on 7/16/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import SwiftUI
import MediaKit

struct FilesView: View {
    
    var model: FilesViewModel
    
    var body: some View {
        List {
            ForEach(model.directory.allSubDirectories, id: \.path) { subDir in
                NavigationLink(destination: FilesView(model: subDir)) {
                    FileRow(model: subDir)
                }
            }
            ForEach(model.directory.allFiles, id: \.path) { file in
                NavigationLink(destination: {
                    Group {
                        if file.isVideo() {
                            VLCViewHost(previewItem: file)
                        } else {
                            QLViewHost(previewItem: file)
                        }
                    }
                }()) {
                    FileRow(model: file)
                }
            }
        }.truncationMode(.middle)
            .navigationBarTitle(Text(model.title), displayMode: .inline)
    }
    
}
