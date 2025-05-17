#if os(iOS) || os(tvOS)
import UIKit

extension Snapshotting where Value == UIViewController, Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    on config: ViewImageConfig,
    onWillSnapshot: (()->())? = nil,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {

      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { viewController in
        snapshotView(
          config: size.map { .init(safeArea: config.safeArea, size: $0, traits: config.traits) } ?? config,
          snapStrategy: .snapInNewWindow,
          onWillSnapshot: onWillSnapshot,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
      }
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
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

      return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { viewController in
        snapshotView(
          config: .init(safeArea: .zero, size: size, traits: traits),
          snapStrategy: snapStrategy,
          onWillSnapshot: onWillSnapshot,
          traits:  traits,
          view: viewController.view,
          viewController: viewController
        )
      }
  }
}


extension Snapshotting where Value == [UIViewController], Format == UIImage {
  /// A snapshot strategy for comparing view controller views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing view controller views based on pixel equality.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - precision: The percentage of pixels that must match.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func image(
    snapStrategy: SnapStrategy = .snapInNewWindow,
    arrangement: ImageArrangement = .unchanged,
    onWillSnapshot: (()->())? = nil,
    precision: Float = 1,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
  )
  -> Snapshotting {

    return SimplySnapshotting.image(precision: precision, scale: traits.displayScale).asyncPullback { viewControllers in

      return Async { callback in
        viewControllers.map{ viewController in
          snapshotViewWithLocation(
            config: .init(safeArea: .zero, size: size, traits: traits),
            snapStrategy: snapStrategy,
            onWillSnapshot: onWillSnapshot,
            traits: traits,
            view: viewController.view,
            viewController: viewController
          )
        }.sequence().run { images in

          let minX = images.map{$0.1.x}.min() ?? 0.0
          let minY = images.map{$0.1.y}.min() ?? 0.0

          let img = combineImages(images: images,
                                  shift: CGPoint(x: -minX, y: -minY),
                                  arrangement: arrangement,
                                  traits: .init(),
                                  spacing: 15)!
          callback(img)
        }
      }

    }
  }

}




extension Snapshotting where Value == UIViewController, Format == String {
  /// A snapshot strategy for comparing view controllers based on their embedded controller hierarchy.
  public static var hierarchy: Snapshotting {
    return Snapshotting<String, String>.lines.pullback { viewController in
      let dispose = prepareView(
        config: .init(),
        snapStrategy: .snapInNewWindow,
        onWillSnapshot: nil,
        traits: .init(),
        view: viewController.view,
        viewController: viewController
      )
      defer { dispose() }
      return purgePointers(
        viewController.perform(Selector(("_printHierarchy"))).retain().takeUnretainedValue() as! String
      )
    }
  }

  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  public static var recursiveDescription: Snapshotting {
    return Snapshotting.recursiveDescription()
  }

  /// A snapshot strategy for comparing view controller views based on a recursive description of their properties and hierarchies.
  ///
  /// - Parameters:
  ///   - config: A set of device configuration settings.
  ///   - size: A view size override.
  ///   - traits: A trait collection override.
  public static func recursiveDescription(
    on config: ViewImageConfig = .init(),
    onWillSnapshot: (()->())? = nil,
    size: CGSize? = nil,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting<UIViewController, String> {
      return SimplySnapshotting.lines.pullback { viewController in
        let dispose = prepareView(
          config: .init(safeArea: config.safeArea, size: size ?? config.size, traits: config.traits),
          snapStrategy: .snapInNewWindow,
          onWillSnapshot: onWillSnapshot,
          traits: traits,
          view: viewController.view,
          viewController: viewController
        )
        defer { dispose() }
        return purgePointers(
          viewController.view.perform(Selector(("recursiveDescription"))).retain().takeUnretainedValue()
            as! String
        )
      }
  }
}



#endif
