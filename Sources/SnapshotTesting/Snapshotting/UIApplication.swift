//
//  UIWindow.swift
//  SnapshotTesting
//
//  Created by Marcus Eckert on 23.02.25.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIApplication, Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }


  public static func image(
    snapStrategy: SnapStrategy = .snapInNewWindow,
    arrangement: ImageArrangement = .unchanged,
    filter: ((UIWindow)->Bool)? = nil,
    precision: Float = 1
  )
  -> Snapshotting {

    return SimplySnapshotting.image(precision: precision, scale: 1.0).asyncPullback { application in
      let windows = application.connectedScenes
        .compactMap{$0 as? UIWindowScene}
        .flatMap{$0.windows}
        .filter{ filter?($0) ?? true }
        .compactMap{$0.rootViewController?.view}

      

      return snapshotViews(views: Array(windows.reversed()), arrangement: arrangement)
    }
  }
}

#endif
