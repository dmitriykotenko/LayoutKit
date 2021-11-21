//  Copyright © 2021 Mobecan. All rights reserved.

import UIKit


/// Wraps a UIView so that it conforms to Layout protocol.
public struct BoilerplateLayout: ConfigurableLayout {

  public let alignment: Alignment
  public let needsView = true
  public let view: UIView
  public let viewReuseId: String? = nil

  public init(_ view: UIView,
              alignment: Alignment = .fill) {
    self.view = view
    self.alignment = alignment
  }

  public func measurement(within maxSize: CGSize) -> LayoutMeasurement {
    .init(
      layout: self,
      size: view.sizeThatFits(maxSize),
      maxSize: maxSize,
      sublayouts: sublayouts.map { $0.measurement(within: maxSize) }
    )
  }

  public func arrangement(within rect: CGRect,
                          measurement: LayoutMeasurement) -> LayoutArrangement {
    let frame = alignment.position(
      size: measurement.size,
      in: rect
    )

    let bounds = CGRect(origin: .zero, size: frame.size)

    return LayoutArrangement(
      layout: self,
      frame: frame,
      sublayouts: measurement.sublayouts.map {
        $0.arrangement(within: bounds)
      }
    )
  }

  private var sublayouts: [Layout] {
    mainSublayout.map { [$0] } ?? []
  }

  private var mainSublayout: Layout? {
    ((view as? LayoutContainer)?.layout)
  }

  public func makeView() -> UIView { view }

  public func configure(view: UIView) {}

  public var flexibility: Flexibility {
    Flexibility(
      horizontal: flexForAxis(.horizontal),
      vertical: flexForAxis(.vertical)
    )
  }

  private func flexForAxis(_ axis: NSLayoutConstraint.Axis) -> Flexibility.Flex {
    switch view.contentHuggingPriority(for: axis) {
    case .required:
      return nil
    case let priority:
      return -Int32(priority.rawValue)
    }
  }
}
