//
//  LoadingState.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/13/26.
//

import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case failed(Error)

    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true

        case let (.failed(lhsError), .failed(rhsError)):
            return (lhsError as NSError).isEqual(rhsError as NSError)

        default:
            return false
        }
    }
}
 
