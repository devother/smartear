//
//  AudioEngineManager.swift
//  SmartEar
//
//  Created by Роман Щипицин on 06.01.2026.
//

import AVFoundation
import Accelerate
import Foundation

/// Handles real-time audio capture and playback with adjustable amplification.
final class AudioEngineManager {

    enum InputSource {
        case auto
        case builtInMic
        case headsetMic
    }

    enum AudioEngineError: LocalizedError {
        case microphonePermissionDenied
        case preferredInputUnavailable

        var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "Доступ к микрофону отклонён. Разрешите использование микрофона в настройках."
            case .preferredInputUnavailable:
                return "Запрошенный микрофон недоступен. Подключите устройство или выберите другой источник."
            }
        }
    }

    private let audioSession = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var audioGraphConfigured = false
    private var tapInstalled = false

    private var interruptionObserver: NSObjectProtocol?
    private(set) var currentInput: InputSource = .auto
    var onLevelUpdate: ((Float) -> Void)?

    var isRunning: Bool {
        engine.isRunning
    }

    deinit {
        stop()
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startListening(amplification: Float) throws {
        guard audioSession.recordPermission == .granted else {
            throw AudioEngineError.microphonePermissionDenied
        }

        try configureAudioSession()
        try configureAudioGraphIfNeeded()
        applyAmplification(amplification)
        try applyPreferredInput(currentInput)
        installLevelTapIfNeeded()

        if engine.isRunning {
            engine.stop()
        }

        engine.prepare()
        try engine.start()
    }

    func stop() {
        guard engine.isRunning else { return }
        engine.stop()
        engine.reset()
        removeLevelTap()

        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Non-fatal; log for debugging while keeping UI responsive.
            print("Audio session deactivation failed: \(error.localizedDescription)")
        }
    }

    func applyAmplification(_ value: Float) {
        // Clamp to 0x - 2x as per requirements.
        mixer.outputVolume = max(0, min(value, 2.0))
    }

    func setPreferredInput(_ source: InputSource) throws {
        currentInput = source
        guard engine.isRunning else { return }
        try applyPreferredInput(source)
    }

    // MARK: - Private

    private func configureAudioGraphIfNeeded() throws {
        guard !audioGraphConfigured else { return }

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)

        engine.attach(mixer)
        engine.connect(input, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        audioGraphConfigured = true
    }

    private func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        try audioSession.setPreferredSampleRate(48_000)
        try audioSession.setPreferredIOBufferDuration(0.005)
        try audioSession.setActive(true, options: [])
    }

    private func applyPreferredInput(_ source: InputSource) throws {
        switch source {
        case .auto:
            try audioSession.setPreferredInput(nil)
        case .builtInMic:
            guard let builtIn = audioSession.availableInputs?.first(where: { $0.portType == .builtInMic }) else {
                throw AudioEngineError.preferredInputUnavailable
            }
            try audioSession.setPreferredInput(builtIn)
        case .headsetMic:
            guard let headset = audioSession.availableInputs?.first(where: { $0.portType == .headsetMic || $0.portType == .bluetoothHFP }) else {
                throw AudioEngineError.preferredInputUnavailable
            }
            try audioSession.setPreferredInput(headset)
        }
    }

    private func installLevelTapIfNeeded() {
        guard !tapInstalled else { return }
        let bus = 0
        mixer.installTap(onBus: bus, bufferSize: 1024, format: mixer.outputFormat(forBus: bus)) { [weak self] buffer, _ in
            self?.processLevel(buffer: buffer)
        }
        tapInstalled = true
    }

    private func removeLevelTap() {
        guard tapInstalled else { return }
        mixer.removeTap(onBus: 0)
        tapInstalled = false
    }

    private func processLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var rms: Float = 0
        let channelCount = Int(buffer.format.channelCount)

        for channel in 0..<channelCount {
            let data = channelData[channel]
            var sum: Float = 0
            vDSP_measqv(data, 1, &sum, vDSP_Length(frameLength))
            rms += sum
        }

        rms = sqrt(rms / Float(channelCount))
        let db = 20 * log10(max(rms, Float.ulpOfOne))

        DispatchQueue.main.async { [weak self] in
            self?.onLevelUpdate?(db)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            engine.pause()
        case .ended:
            do {
                try audioSession.setActive(true, options: [])
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        try engine.start()
                    }
                }
            } catch {
                print("Failed to resume after interruption: \(error.localizedDescription)")
            }
        @unknown default:
            break
        }
    }
}


