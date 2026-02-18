import Carbon
import Foundation

final class GlobalHotkeyManager {
    typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: Handler?

    private let hotKeyID = EventHotKeyID(signature: makeFourCharCode("CLCH"), id: 1)

    deinit {
        unregister()
    }

    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_L),
        modifiers: UInt32 = UInt32(cmdKey | optionKey),
        handler: @escaping Handler
    ) {
        unregister()
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let eventHandler: EventHandlerUPP = { _, eventRef, userData in
            guard let userData, let eventRef else { return noErr }

            let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var eventHotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &eventHotKeyID
            )

            guard status == noErr,
                  eventHotKeyID.signature == manager.hotKeyID.signature,
                  eventHotKeyID.id == manager.hotKeyID.id
            else {
                return noErr
            }

            DispatchQueue.main.async {
                manager.handler?()
            }

            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandler,
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        handler = nil
    }
}

private func makeFourCharCode(_ string: String) -> FourCharCode {
    precondition(string.count == 4, "FourCharCode는 4글자여야 합니다.")
    return string.utf16.reduce(0) { ($0 << 8) + FourCharCode($1) }
}
