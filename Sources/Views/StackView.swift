// Copyright 2016 LinkedIn Corp.
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import UIKit

/**
 A view that stacks its subviews along a single axis.
 
 It is similar to UIStackView except that it uses StackLayout instead of Auto Layout, which means layout is much faster.
 
 Although StackView is faster than UIStackView, it still does layout on the main thread.
 If you want to get the full benefit of LayoutKit, use StackLayout directly.
 
 Unlike UIStackView, if you position StackView with Auto Layout, you must call invalidateIntrinsicContentSize on that StackView
 whenever any of its subviews' intrinsic content sizes change (e.g. changing the text of a UILabel that is positioned by the StackView).
 Otherwise, Auto Layout won't recompute the layout of the StackView.
 
 Subviews MUST implement sizeThatFits so StackView can allocate space correctly.
 If a subview uses Auto Layout, then the subview may implement sizeThatFits by calling systemLayoutSizeFittingSize.
 */
open class StackView: UIView {

    /// The axis along which arranged views are stacked.
    public let axis: Axis

    /**
     The distance in points between adjacent edges of sublayouts along the axis.
     For Distribution.EqualSpacing, this is a minimum spacing. For all other distributions it is an exact spacing.
     */
    public let spacing: CGFloat

    /// The distribution of space along the stack's axis.
    public let distribution: StackLayoutDistribution

    /// The distance that the arranged views are inset from the stack view. Defaults to 0.
    public let contentInsets: UIEdgeInsets

    /// The stack's alignment inside its parent.
    public let alignment: Alignment

    /// The alignment of stack's children.
    public let childrenAlignment: Alignment

    /// The stack's flexibility.
    public let flexibility: Flexibility?

    public var intrinsicWidth: CGFloat?

    public var intrinsicHeight: CGFloat?

    private var arrangedSubviews: [UIView] = []

    public init(axis: Axis,
                spacing: CGFloat = 0,
                distribution: StackLayoutDistribution = .leading,
                contentInsets: UIEdgeInsets = .zero,
                alignment: Alignment = .fill,
                childrenAlignment: Alignment = .fill,
                flexibility: Flexibility? = nil,
                intrinsicWidth: CGFloat? = nil,
                intrinsicHeight: CGFloat? = nil) {

        self.axis = axis
        self.spacing = spacing
        self.distribution = distribution
        self.contentInsets = contentInsets
        self.alignment = alignment
        self.childrenAlignment = childrenAlignment
        self.flexibility = flexibility
        self.intrinsicWidth = intrinsicWidth
        self.intrinsicHeight = intrinsicHeight

        super.init(frame: .zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Adds a subview to the stack.
     
     Subviews MUST implement sizeThatFits so StackView can allocate space correctly.
     If a subview uses Auto Layout, then the subview can implement sizeThatFits by calling systemLayoutSizeFittingSize.
     */
    open func addArrangedSubviews(_ subviews: [UIView]) {
        arrangedSubviews.append(contentsOf: subviews)
        subviews.forEach(addSubview)

        updateContentHuggingPriority()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func updateContentHuggingPriority() {
        setContentHuggingPriority(
            .from(stackLayout.flexibility.flex(.horizontal)),
            for: .horizontal
        )

        setContentHuggingPriority(
            .from(stackLayout.flexibility.flex(.vertical)),
            for: .vertical
        )
    }

    /**
     Deletes all subviews from the stack.
     */
    open func removeArrangedSubviews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        arrangedSubviews.removeAll()

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return stackLayout.measurement(within: size).size
    }

    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(
            CGSize(
                width: intrinsicWidth ?? CGFloat.greatestFiniteMagnitude,
                height: intrinsicHeight ?? CGFloat.greatestFiniteMagnitude
            )
        )
    }

    open override func layoutSubviews() {
        stackLayout.measurement(within: bounds.size).arrangement(within: bounds).makeViews(in: self)

        // Add hidden subviews, so they always know their place in the hierarchy.
        arrangedSubviews
            .filter { $0.isHidden }
            .forEach { addSubview($0) }
    }

    private var stackLayout: Layout {
      let sublayouts = arrangedSubviews
        .filter { !$0.isHidden }
        .map { BoilerplateLayout($0, alignment: childrenAlignment) }

        let stack = StackLayout(
            axis: axis,
            spacing: spacing,
            distribution: distribution,
            alignment: alignment,
            flexibility: flexibility,
            sublayouts: sublayouts,
            config: nil)

        let insetLayout = InsetLayout(insets: contentInsets, sublayout: stack)

        if (intrinsicWidth != nil || intrinsicHeight != nil) {
            return SizeLayout(
                minWidth: intrinsicWidth,
                maxWidth: intrinsicWidth,
                minHeight: intrinsicHeight,
                maxHeight: intrinsicHeight,
                sublayout: insetLayout
            )
        } else {
            return insetLayout
        }
    }
}


private extension UILayoutPriority {

    static func from(_ flex: Flexibility.Flex) -> UILayoutPriority {
        flex.map { UILayoutPriority(rawValue: Float(-$0).clipped(inside: 0...999)) }
        ?? .required
    }
}


private extension Comparable {

    func clipped(inside bounds: ClosedRange<Self>) -> Self {
        let minimum = bounds.lowerBound
        let maximum = bounds.upperBound

        return  min(max(self, minimum), maximum)
    }
}
