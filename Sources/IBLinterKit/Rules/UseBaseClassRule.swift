//
//  UseBaseClassRule.swift
//  IBLinterKit
//
//  Created by masamichi on 2019/03/07.
//

import Foundation
import IBDecodable

extension Rules {
    public struct UseBaseClassRule: Rule {

        public static var identifier: String = "use_base_class"

        private var baseClasses: [String: [String]] = [:]

        public init(context: Context) {
            for baseClassConfig in context.config.useBaseClassRule {
                self.baseClasses[baseClassConfig.elementClass] = baseClassConfig.baseClasses
            }
        }

        public func validate(storyboard: StoryboardFile) -> [Violation] {
            guard let scenes = storyboard.document.scenes else { return [] }
            let views = scenes.compactMap { $0.viewController?.viewController.rootView }
            return views.flatMap { validate(for: $0, file: storyboard) }
        }

        public func validate(xib: XibFile) -> [Violation] {
            guard let views = xib.document.views else { return [] }
            return views.flatMap { validate(for: $0.view, file: xib) }
        }

        private func validate<T: InterfaceBuilderFile>(for view: ViewProtocol, file: T) -> [Violation] {
            let violation: [Violation] = {
                guard let baseClassesForElement = baseClasses[view.elementClass] else { return [] }
                guard let customClass = view.customClass else {
                    let message = "CustomClass is not set to \(view.elementClass) (\(view.id)) "
                    return [Violation(pathString: file.pathString, message: message, level: .warning)]
                }

                if !baseClassesForElement.contains(customClass) {
                    let message = "\(customClass) (\(view.id) is not contained in the BaseClasses"
                    return [Violation(pathString: file.pathString, message: message, level: .warning)]
                }
                return []
            }()
            return violation + (view.subviews?.flatMap { validate(for: $0.view, file: file) } ?? [])
        }
    }
}
