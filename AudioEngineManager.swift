//
//  AudioEngineManager.swift
//  smartear
//
//  Created by Роман Щипицин on 05.01.2026.
//

import AVFoundation
import Foundation

protocol AudioEngineManagerDelegate: AnyObject {
    func audioEngineManager(_ manager: AudioEngineManager, didEncounterError error: Error)
    func audioEngineManagerDidStart(_ manager: AudioEngineManager)
    func audioEngineManagerDidStop(_ manager: AudioEngineManager)
}

class AudioEngineManager {
    
    // MARK: - Properties
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let outputNode: AVAudioOutputNode
    private let mixerNode = AVAudioMixerNode()
    
    weak var delegate: AudioEngineManagerDelegate?
    
    private var isRunning = false
    
    // Настройки усиления (gain)
    var inputGain: Float = 1.0 {
        didSet {
            mixerNode.volume = inputGain
        }
    }
    
    private var hasTapInstalled = false
    
    // MARK: - Initialization
    
    init() {
        inputNode = audioEngine.inputNode
        outputNode = audioEngine.outputNode
        
        setupAudioEngine()
    }
    
    // MARK: - Setup
    
    private func setupAudioEngine() {
        let inputFormat = inputNode.inputFormat(forBus: 0)
        let outputFormat = outputNode.outputFormat(forBus: 0)
        
        // Подключаем входной узел к микшеру
        audioEngine.attach(mixerNode)
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        audioEngine.connect(mixerNode, to: outputNode, format: outputFormat)
        
        // Устанавливаем начальное усиление
        mixerNode.volume = inputGain
    }
    
    private func setupAudioProcessing() {
        guard !hasTapInstalled else { return }
        
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Устанавливаем обработчик для входного аудио
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] (buffer, time) in
            // Аудио уже передается через mixerNode к выходу
            // Здесь можно добавить дополнительную обработку (фильтры, усиление и т.д.)
        }
        
        hasTapInstalled = true
    }
    
    // MARK: - Control Methods
    
    func start() throws {
        guard !isRunning else {
            print("Аудиодвижок уже запущен")
            return
        }
        
        // Запрашиваем разрешение на использование микрофона
        requestMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                do {
                    // Устанавливаем обработку аудио перед запуском
                    self.setupAudioProcessing()
                    
                    try self.audioEngine.start()
                    self.isRunning = true
                    DispatchQueue.main.async {
                        self.delegate?.audioEngineManagerDidStart(self)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.delegate?.audioEngineManager(self, didEncounterError: error)
                    }
                }
            } else {
                let error = NSError(domain: "AudioEngineManager",
                                  code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Доступ к микрофону запрещен"])
                DispatchQueue.main.async {
                    self.delegate?.audioEngineManager(self, didEncounterError: error)
                }
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        if hasTapInstalled {
            inputNode.removeTap(onBus: 0)
            hasTapInstalled = false
        }
        
        audioEngine.stop()
        isRunning = false
        
        delegate?.audioEngineManagerDidStop(self)
    }
    
    // MARK: - Permission Handling
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Audio Configuration
    
    func setInputGain(_ gain: Float) {
        inputGain = max(0.0, min(2.0, gain)) // Ограничиваем от 0 до 2
        mixerNode.volume = inputGain
    }
    
    // MARK: - Cleanup
    
    deinit {
        if isRunning {
            stop()
        }
    }
}
