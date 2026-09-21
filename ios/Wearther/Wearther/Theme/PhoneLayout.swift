import SwiftUI

/// Lightweight sizing helpers so layout adapts across iPhone widths/heights
/// (SE → Pro Max) without hard-coding one phone's canvas.
enum PhoneLayout {
    /// Narrow phones (SE / mini-class widths).
    static func isCompactWidth(_ width: CGFloat) -> Bool {
        width < 390
    }

    /// Short phones where a fixed non-scrolling board overflows.
    static func isCompactHeight(_ height: CGFloat) -> Bool {
        height < 720
    }

    static func horizontalPadding(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 12 : 16
    }

    static func boardSpacing(for height: CGFloat) -> CGFloat {
        isCompactHeight(height) ? 10 : 14
    }

    static func displayTitleSize(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 28 : 34
    }

    static func cityTitleSize(for width: CGFloat) -> CGFloat {
        isCompactWidth(width) ? 22 : 26
    }
}
