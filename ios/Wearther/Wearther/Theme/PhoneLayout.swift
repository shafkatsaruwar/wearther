import SwiftUI

/// Density helpers so the home board reads “zoomed out” on real phones
/// (SE → Pro Max) instead of filling the first viewport like a tablet mock.
enum PhoneLayout {
    /// Narrow phones (SE / mini / standard).
    static func isCompactWidth(_ width: CGFloat) -> Bool {
        width < 400
    }

    /// Short phones where a fixed non-scrolling board overflows.
    static func isCompactHeight(_ height: CGFloat) -> Bool {
        height < 760
    }

    /// Outer margin from the screen edge to the decision board.
    static func horizontalPadding(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 16 : 20
    }

    static func boardSpacing(for height: CGFloat) -> CGFloat {
        isCompactHeight(height) ? 7 : 9
    }

    /// Outfit answer title — kept readable, not hero-billboard.
    static func displayTitleSize(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 22 : 25
    }

    /// City / brand mark in the header.
    static func cityTitleSize(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 20 : 22
    }

    static func boardInnerPadding(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 12 : 14
    }

    static func boardCornerRadius(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 20 : 24
    }
}
