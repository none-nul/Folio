import AppKit

/// Menu-bar entries for the reader (READER-03/04): zoom and layout in 显示, plus 前往 and 批注 menus.
enum ReaderMenus {
    static func viewItems() -> [NSMenuItem] {
        let item = MainMenu.item
        var items = [
            item(String(localized: "实际大小"), #selector(ReaderWindowController.actualSize(_:)), "0", .command),
            item(String(localized: "放大"), #selector(ReaderWindowController.zoomIn(_:)), "+", .command),
            item(String(localized: "缩小"), #selector(ReaderWindowController.zoomOut(_:)), "-", .command),
            item(String(localized: "适合页宽"), #selector(ReaderWindowController.zoomToFit(_:)), "9", .command),
            .separator(),
            item(String(localized: "单页连续"), #selector(ReaderWindowController.setSinglePage(_:)), "", .command),
            item(String(localized: "双页连续"), #selector(ReaderWindowController.setTwoPages(_:)), "", .command),
            .separator(),
        ]
        let sidebar = NSMenu(title: String(localized: "阅读边栏"))
        for tab in ReaderSidebarTab.allCases {
            let entry = item(tab.title, #selector(ReaderWindowController.showReaderSidebarTab(_:)),
                             "\(tab.rawValue + 2)", [.command, .option])
            entry.tag = tab.rawValue
            sidebar.addItem(entry)
        }
        items.append(MainMenu.submenu(String(localized: "阅读边栏"), sidebar))
        items.append(item(String(localized: "对照阅读"), #selector(ReaderWindowController.toggleParallelReading(_:)), "", .command))
        return items
    }

    static func menus() -> [(String, NSMenu)] {
        let item = MainMenu.item
        let go = NSMenu(title: String(localized: "前往"))
        go.addItem(item(String(localized: "上一页"), #selector(ReaderWindowController.goToPreviousPage(_:)),
                        String(Character(UnicodeScalar(NSUpArrowFunctionKey)!)), [.command, .option]))
        go.addItem(item(String(localized: "下一页"), #selector(ReaderWindowController.goToNextPage(_:)),
                        String(Character(UnicodeScalar(NSDownArrowFunctionKey)!)), [.command, .option]))
        // Home / End are left to the focused view (PDFView pages, text fields scroll).
        go.addItem(item(String(localized: "第一页"), #selector(ReaderWindowController.goToFirstPage(_:)), "", .command))
        go.addItem(item(String(localized: "最后一页"), #selector(ReaderWindowController.goToLastPage(_:)), "", .command))
        go.addItem(.separator())
        go.addItem(item(String(localized: "后退"), #selector(ReaderWindowController.goBack(_:)), "[", .command))
        go.addItem(item(String(localized: "前进"), #selector(ReaderWindowController.goForward(_:)), "]", .command))
        go.addItem(.separator())
        go.addItem(item(String(localized: "前往页面…"), #selector(ReaderWindowController.goToPageNumber(_:)), "g", [.command, .option]))

        let annotate = NSMenu(title: String(localized: "批注"))
        for tool in AnnotationTool.allCases where tool != .highlight {
            let entry = item(tool.title, #selector(ReaderWindowController.selectTool(_:)), tool.keyEquivalent, [.command, .control])
            entry.tag = tool.rawValue
            entry.image = NSImage(systemSymbolName: tool.symbol, accessibilityDescription: nil)
            annotate.addItem(entry)
            if tool == .select { annotate.addItem(.separator()) }
        }
        let shortcut = HighlightShortcut.current
        let highlight = item(String(localized: "高亮所选文字"), #selector(ReaderWindowController.highlightSelection(_:)),
                             shortcut.key, NSEvent.ModifierFlags(rawValue: shortcut.modifiers.rawValue))
        highlight.identifier = highlightItemIdentifier
        highlight.image = NSImage(systemSymbolName: AnnotationTool.highlight.symbol, accessibilityDescription: nil)
        annotate.insertItem(highlight, at: 2)
        annotate.addItem(.separator())
        let colors = NSMenu(title: String(localized: "颜色"))
        for (index, color) in AnnotationColor.allCases.enumerated() {
            let entry = item(color.title, #selector(ReaderWindowController.selectColor(_:)), "", .command)
            entry.tag = index
            entry.image = ReaderWindowController.colorSwatch(color)
            colors.addItem(entry)
        }
        annotate.addItem(MainMenu.submenu(String(localized: "颜色"), colors))
        annotate.addItem(.separator())
        annotate.addItem(item(String(localized: "添加到笔记"), #selector(ReaderWindowController.addSelectionToNote(_:)), "m", [.command, .control]))
        annotate.addItem(item(String(localized: "删除所选批注"), #selector(ReaderWindowController.deleteSelectedAnnotation(_:)), "", .command))
        return [(String(localized: "前往"), go), (String(localized: "批注"), annotate)]
    }

    static let highlightItemIdentifier = NSUserInterfaceItemIdentifier("folio.highlightSelection")

    /// Points the 批注 menu item at the shortcut. No menu yet (during launch) is fine.
    static func apply(_ shortcut: HighlightShortcut) {
        guard let item = menuItem(highlightItemIdentifier, in: NSApp.mainMenu) else { return }
        item.keyEquivalent = shortcut.key
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: shortcut.modifiers.rawValue)
    }

    /// Title of another menu command that already uses this shortcut.
    static func reservedTitle(matching shortcut: HighlightShortcut) -> String? {
        guard let menu = NSApp.mainMenu else { return nil }
        return shortcut.conflictingTitle(among: claims(in: menu, excluding: highlightItemIdentifier))
    }

    private static func menuItem(_ identifier: NSUserInterfaceItemIdentifier, in menu: NSMenu?) -> NSMenuItem? {
        guard let menu else { return nil }
        for item in menu.items {
            if item.identifier == identifier { return item }
            if let submenu = item.submenu, let found = menuItem(identifier, in: submenu) { return found }
        }
        return nil
    }

    private static func claims(in menu: NSMenu, excluding identifier: NSUserInterfaceItemIdentifier) -> [HighlightShortcut.Claim] {
        var result: [HighlightShortcut.Claim] = []
        for item in menu.items {
            if item.identifier != identifier, !item.keyEquivalent.isEmpty {
                result.append(.init(key: item.keyEquivalent,
                                    modifiers: HighlightShortcut.Modifiers(rawValue: item.keyEquivalentModifierMask.rawValue),
                                    title: item.title))
            }
            if let submenu = item.submenu { result += claims(in: submenu, excluding: identifier) }
        }
        return result
    }
}
