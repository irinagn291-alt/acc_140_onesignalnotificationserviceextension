import SwiftUI

enum AppTheme {
    static let background  = Color(red: 18/255.0, green: 14/255.0, blue: 26/255.0)
    static let surface     = Color(red: 36/255.0, green: 23/255.0, blue: 51/255.0)
    static let accent      = Color(red: 196/255.0, green: 78/255.0, blue: 255/255.0)
    static let label       = Color(red: 243/255.0, green: 236/255.0, blue: 250/255.0)
    static let sublabel    = Color(red: 155/255.0, green: 125/255.0, blue: 184/255.0)
    static let positive    = Color(red: 255/255.0, green: 138/255.0, blue: 91/255.0)
    static let negative    = Color(red: 255/255.0, green: 77/255.0, blue: 109/255.0)
    static let edge        = Color.primary.opacity(0.08)

    static let corner: CGFloat      = 20
    static let cornerSmall: CGFloat = 14
    static let cornerLarge: CGFloat = 28

    static func display(_ size: CGFloat) -> Font  { .system(size: size, weight: .bold,      design: .default) }
    static func heading(_ size: CGFloat) -> Font  { .system(size: size, weight: .semibold,  design: .default) }
    static func body(_ size: CGFloat) -> Font     { .system(size: size, weight: .regular,   design: .default) }
    static func caption(_ size: CGFloat) -> Font  { .system(size: size, weight: .medium,    design: .default) }
    static func mono(_ size: CGFloat) -> Font     { .system(size: size, weight: .regular,   design: .monospaced) }
}
