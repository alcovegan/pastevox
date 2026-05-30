import AppKit
import Foundation

struct ClipboardBackup {
    let items: [[NSPasteboard.PasteboardType: Data]]
    let changeCount: Int

    static func capture(from pasteboard: NSPasteboard = .general) -> ClipboardBackup {
        var backedUpItems: [[NSPasteboard.PasteboardType: Data]] = []

        for item in pasteboard.pasteboardItems ?? [] {
            var backedUpItem: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    backedUpItem[type] = data
                }
            }
            if !backedUpItem.isEmpty {
                backedUpItems.append(backedUpItem)
            }
        }

        return ClipboardBackup(items: backedUpItems, changeCount: pasteboard.changeCount)
    }

    func restore(to pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()

        let pasteboardItems = items.map { backedUpItem in
            let item = NSPasteboardItem()
            for (type, data) in backedUpItem {
                item.setData(data, forType: type)
            }
            return item
        }

        if !pasteboardItems.isEmpty {
            pasteboard.writeObjects(pasteboardItems)
        }
    }
}
