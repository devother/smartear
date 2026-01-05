//
//  ViewController.swift
//  smartear
//
//  Created by Роман Щипицин on 05.01.2026.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    private let audioEngineManager = AudioEngineManager()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SmartEar"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Слуховой аппарат"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Готов к работе"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Начать прослушивание", for: .normal)
        button.setTitle("Остановить прослушивание", for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var gainSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 2.0
        slider.value = 1.0
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(gainSliderChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var gainLabel: UILabel = {
        let label = UILabel()
        label.text = "Усиление: 1.0x"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var isListening = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioEngine()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isListening {
            stopListening()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(statusLabel)
        view.addSubview(toggleButton)
        view.addSubview(gainSlider)
        view.addSubview(gainLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            toggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toggleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 280),
            toggleButton.heightAnchor.constraint(equalToConstant: 60),
            
            gainLabel.topAnchor.constraint(equalTo: toggleButton.bottomAnchor, constant: 60),
            gainLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            gainLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            gainSlider.topAnchor.constraint(equalTo: gainLabel.bottomAnchor, constant: 12),
            gainSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            gainSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupAudioEngine() {
        audioEngineManager.delegate = self
    }
    
    // MARK: - Actions
    
    @objc private func toggleButtonTapped() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    @objc private func gainSliderChanged() {
        let gain = gainSlider.value
        audioEngineManager.setInputGain(gain)
        gainLabel.text = String(format: "Усиление: %.1fx", gain)
    }
    
    // MARK: - Listening Control
    
    private func startListening() {
        do {
            try audioEngineManager.start()
            isListening = true
            toggleButton.isSelected = true
            toggleButton.backgroundColor = .systemRed
            statusLabel.text = "Прослушивание активно"
            statusLabel.textColor = .systemGreen
        } catch {
            showErrorAlert(message: "Не удалось запустить прослушивание: \(error.localizedDescription)")
        }
    }
    
    private func stopListening() {
        audioEngineManager.stop()
        isListening = false
        toggleButton.isSelected = false
        toggleButton.backgroundColor = .systemBlue
        statusLabel.text = "Готов к работе"
        statusLabel.textColor = .secondaryLabel
    }
    
    // MARK: - Error Handling
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AudioEngineManagerDelegate

extension ViewController: AudioEngineManagerDelegate {
    func audioEngineManager(_ manager: AudioEngineManager, didEncounterError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showErrorAlert(message: error.localizedDescription)
            if self?.isListening == true {
                self?.stopListening()
            }
        }
    }
    
    func audioEngineManagerDidStart(_ manager: AudioEngineManager) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Прослушивание активно"
            self?.statusLabel.textColor = .systemGreen
        }
    }
    
    func audioEngineManagerDidStop(_ manager: AudioEngineManager) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Прослушивание остановлено"
            self?.statusLabel.textColor = .secondaryLabel
        }
    }
}
