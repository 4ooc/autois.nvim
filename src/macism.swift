// reference https://github.com/laishulu/macism/blob/master/macism.swift

import Carbon
import Cocoa
import Foundation

class InputSource: Equatable {
    static func == (lhs: InputSource, rhs: InputSource) -> Bool {
        return lhs.id == rhs.id
    }

    let tisInputSource: TISInputSource

    var id: String {
        return tisInputSource.id
    }

    var name: String {
        return tisInputSource.name
    }

    var isCJKV: Bool {
        if let lang = tisInputSource.sourceLanguages.first {
            return lang == "ko" || lang == "ja" || lang == "vi"
            || lang.hasPrefix("zh")
        }
        return false
    }

    init(tisInputSource: TISInputSource) {
        self.tisInputSource = tisInputSource
    }

    func select() {
        let currentSource = InputSourceManager.getCurrentSource()
        if currentSource.id == self.id {
            return
        }
        TISSelectInputSource(tisInputSource)
    }
}

class InputSourceManager {
    static var inputSources: [InputSource] = []
    static var uSeconds: UInt32 = 20000

    static func initialize() {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false)
        .takeRetainedValue() as NSArray
        let inputSourceList = inputSourceNSArray as! [TISInputSource]

        inputSources = inputSourceList.filter(
            {
                $0.category == TISInputSource.Category.keyboardInputSource
                && $0.isSelectable
            }).map { InputSource(tisInputSource: $0) }
    }

    static func nonCJKVSource() -> InputSource? {
        return inputSources.first(where: { !$0.isCJKV })
    }

    static func getCurrentSource()->InputSource{
        return InputSource(
            tisInputSource:
            TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        )
    }

    static func getInputSource(name: String)->InputSource{
        let inputSources = InputSourceManager.inputSources
        return inputSources.filter({$0.id == name}).first!
    }
}

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    private func getProperty(_ key: CFString) -> AnyObject? {
        let cfType = TISGetInputSourceProperty(self, key)
        if (cfType != nil) {
            return Unmanaged<AnyObject>.fromOpaque(cfType!)
            .takeUnretainedValue()
        } else {
            return nil
        }
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var name: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isSelectable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }
}

InputSourceManager.initialize()
let arguments = CommandLine.arguments
if arguments.count == 1 {
    let currentSource = InputSourceManager.getCurrentSource()
    print(currentSource.id)
} else if arguments.count == 3 && arguments[1] == "!" {
    let inputSources = InputSourceManager.inputSources
    let a = inputSources.filter({$0.id != arguments[2]}).first!
    print(a.id)
} else {
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    let options = [checkOptPrompt: true]
    let isAppTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary?)
    if(isAppTrusted == true) {
        let dstSource = InputSourceManager.getInputSource(
            name: arguments[1]
        )
        if CommandLine.arguments.count == 3 {
            InputSourceManager.uSeconds = UInt32(arguments[2])!
        }
        dstSource.select()
    } else {
        usleep(5000000)
    }
}