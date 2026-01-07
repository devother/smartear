//
//  ViewController.swift
//  SmartEar
//
//  Created by Роман Щипицин on 06.01.2026.
//

import UIKit
import AVFoundation

final class ViewController: UIViewController {

    private let audioManager = AudioEngineManager()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SmartEar"
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Улавливайте окружающие звуки и слышите их через динамики iPhone или наушники."
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.text = "Уровень: — dB"
        return label
    }()

    private lazy var startButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .large
        configuration.title = "Начать прослушивание"
        configuration.baseBackgroundColor = .systemGreen
        configuration.baseForegroundColor = .white

        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.addTarget(self, action: #selector(toggleListening), for: .touchUpInside)
        return button
    }()

    private lazy var amplificationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var inputControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Авто", "iPhone", "Наушники"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(inputChanged(_:)), for: .valueChanged)
        return control
    }()

    private lazy var amplificationSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 2.0
        slider.value = 1.0
        slider.addTarget(self, action: #selector(amplificationChanged(_:)), for: .valueChanged)
        return slider
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureLayout()
        updateAmplificationLabel()
        updateStateUI(isRunning: false)
        bindLevelUpdates()
    }

    // MARK: - Actions

    @objc private func toggleListening() {
        if audioManager.isRunning {
            stopListening()
        } else {
            startListeningWithPermissionCheck()
        }
    }

    @objc private func amplificationChanged(_ sender: UISlider) {
        audioManager.applyAmplification(sender.value)
        updateAmplificationLabel()
    }

    @objc private func inputChanged(_ sender: UISegmentedControl) {
        let source: AudioEngineManager.InputSource
        switch sender.selectedSegmentIndex {
        case 1: source = .builtInMic
        case 2: source = .headsetMic
        default: source = .auto
        }

        do {
            try audioManager.setPreferredInput(source)
        } catch {
            presentError(error)
            sender.selectedSegmentIndex = 0
        }
    }

    // MARK: - Private helpers

    private func startListeningWithPermissionCheck() {
        let permission = AVAudioSession.sharedInstance().recordPermission
        
        switch permission {
        case .granted:
            // Разрешение уже есть, запускаем сразу
            startListening()
        case .denied:
            // Разрешение отклонено, показываем ошибку
            presentError(AudioEngineManager.AudioEngineError.microphonePermissionDenied)
        case .undetermined:
            // Запрашиваем разрешение и сразу запускаем после получения
            audioManager.requestPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    // Разрешение получено, запускаем прослушивание
                    self.startListening()
                } else {
                    // Разрешение отклонено
                    self.presentError(AudioEngineManager.AudioEngineError.microphonePermissionDenied)
                }
            }
        @unknown default:
            break
        }
    }

    private func startListening() {
        do {
            try audioManager.startListening(amplification: amplificationSlider.value)
            updateStateUI(isRunning: true)
        } catch {
            presentError(error)
            updateStateUI(isRunning: false)
        }
    }

    private func stopListening() {
        audioManager.stop()
        updateStateUI(isRunning: false)
    }

    private func configureLayout() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            descriptionLabel,
            inputControl,
            startButton,
            amplificationLabel,
            amplificationSlider,
            levelLabel,
            statusLabel
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func updateStateUI(isRunning: Bool) {
        var configuration = startButton.configuration ?? UIButton.Configuration.filled()
        configuration.title = isRunning ? "Остановить" : "Начать прослушивание"
        configuration.baseBackgroundColor = isRunning ? .systemRed : .systemGreen
        startButton.configuration = configuration

        statusLabel.text = isRunning ? "Прослушивание активно" : "Готово к запуску"
        statusLabel.textColor = isRunning ? .systemGreen : .secondaryLabel
        if !isRunning {
            levelLabel.text = "Уровень: — dB"
        }
    }

    private func updateAmplificationLabel() {
        let value = amplificationSlider.value
        amplificationLabel.text = String(format: "Усиление: %.1fx", value)
    }

    private func bindLevelUpdates() {
        audioManager.onLevelUpdate = { [weak self] db in
            self?.levelLabel.text = String(format: "Уровень: %.1f dB", db)
        }
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

