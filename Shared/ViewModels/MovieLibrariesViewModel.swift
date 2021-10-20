//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUICollection

final class MovieLibrariesViewModel: ViewModel {
    
    @Published var rows = [LibraryRow]()
    @Published var totalPages = 0
    @Published var currentPage = 0
    @Published var hasNextPage = false
    @Published var hasPreviousPage = false
    
    private var libraries = [BaseItemDto]()
    private let columns: Int
    
    @RouterObject
    var router: MovieLibrariesCoordinator.Router?
    
    init(
        columns: Int = 7
    ) {
        self.columns = columns
        super.init()

        requestLibraries()
    }
    
    func requestLibraries() {
        
        UserViewsAPI.getUserViews(
            userId: SessionManager.main.currentLogin.user.id)
            .trackActivity(loading)
          .sink(receiveCompletion: { completion in
              self.handleAPIRequestError(completion: completion)
          }, receiveValue: { response in
              if let responseItems = response.items {
                  self.libraries = []
                  for library in responseItems {
                      if library.collectionType == "movies" {
                          self.libraries.append(library)
                      }
                  }
                  if self.libraries.count == 1, let library = self.libraries.first {
                      // show library
                      self.router?.route(to: \.library, library)
                  } else {
                      // display list of libraries
                      self.rows = self.calculateRows()
                  }
              }
          })
          .store(in: &cancellables)
    }
    
    private func calculateRows() -> [LibraryRow] {
        guard libraries.count > 0 else { return [] }
        let rowCount = libraries.count / columns
        var calculatedRows = [LibraryRow]()
        for i in (0...rowCount) {
            let firstItemIndex = i * columns
            var lastItemIndex = firstItemIndex + columns
            if lastItemIndex > libraries.count {
                lastItemIndex = libraries.count
            }

            var rowCells = [LibraryRowCell]()
            for item in libraries[firstItemIndex..<lastItemIndex] {
                print("item: \(item.title) index: \(i)")
                let newCell = LibraryRowCell(item: item)
                rowCells.append(newCell)
            }
            if i == rowCount && hasNextPage {
                var loadingCell = LibraryRowCell(item: nil)
                loadingCell.loadingCell = true
                rowCells.append(loadingCell)
            }

            calculatedRows.append(
                LibraryRow(
                  section: i,
                  items: rowCells
                )
            )
        }
        print("caluculated \(calculatedRows.count) rows")
        return calculatedRows
    }
}
