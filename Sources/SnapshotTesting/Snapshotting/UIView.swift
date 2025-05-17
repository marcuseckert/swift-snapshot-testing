#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIView, Format == UIImage {
  /// A snapshot strategy for comparing views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing views based on pixel equality.
  ///
  /// - Parameters:
  ///   - snapStrategy:
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    snapStrategy: SnapStrategy = .snapInNewWindow,
    onWillSnapshot: (()->())? = nil,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { view in
        snapshotView(
          config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: .init()),
          snapStrategy: snapStrategy,
          onWillSnapshot: onWillSnapshot,
          traits: traits,
          view: view,
          viewController: .init()
        )
      }
  }
}

extension Snapshotting where Value == UIView, Format == String {
  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing views based on a recursive description of their properties and hierarchies.
  public static func recursiveDescription(
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting<UIView, String> {
      return SimplySnapshotting.lines.pullback { view in
        let dispose = prepareView(
          config: .init(safeArea: .zero, size: size ?? view.frame.size, traits: traits),
          snapStrategy: .snapInNewWindow,
          onWillSnapshot: nil,
          traits: .init(),
          view: view,
          viewController: .init()
        )
        defer { dispose() }
        return purgePointers(
          view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
            as! String
        )
      }
  }
}

extension Snapshotting where Value == [UIView], Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }


  public static func image(
    snapStrategy: SnapStrategy = .snapInNewWindow,
    filter: ((UIWindow)->Bool)? = nil,
    precision: Float = 1
  )
  -> Snapshotting {
    let traits = UITraitCollection()

    return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { views in
      return snapshotViews(views: views, arrangement: .unchanged)
    }
  }
}

#endif
