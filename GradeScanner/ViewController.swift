//
//  ViewController.swift
//  GradeScanner
//
//  Created by Nate Armstrong on 9/22/21.
//

import UIKit
import AVFoundation
import Vision

struct User {
    let name: String
    let avatar: UIImage
}

let users: [User] = [
    User(name: "Frodo Baggins", avatar: UIImage(named: "frodo")!),
    User(name: "Tim Cook", avatar: UIImage(named: "tim")!),
    User(name: "Paul Atreides", avatar: UIImage(named: "paul")!)
]

class ViewController: UIViewController {
    enum Step {
        case scanning
        case found(User)
        case form(User)
    }

    struct State {
        var step: Step
        var score: Int
    }

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    var statusLabel: UILabel!
    var candidateView: UIView!
    var candidateImageView: UIImageView!
    var candidateNameLabel: UILabel!
    var formView: UIView!
    var formNameLabel: UILabel!
    var formContainerView: UIView!
    var scoreValueLabel: UILabel!
    var slider: UISlider!

    var formBottomConstraint: NSLayoutConstraint!

    var lastCaptureDate: Date?
    var captureInterval = 0.25

    var state: State = State(step: .scanning, score: 0) {
        didSet { DispatchQueue.main.async { self.update() } }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
        guard captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
        dataOutput.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))
        captureSession.addOutput(dataOutput)

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.connection?.videoOrientation = .portrait
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.commitConfiguration()
        captureSession.startRunning()

        configureStatusView()
        candidateView = configureCandidateView()
        formView = configureFormView()

        update()
    }

    func update() {
        switch state.step {
            case .scanning:
                statusLabel.text = "SCANNING FOR NAME"
                candidateView.isHidden = true
                view.layoutIfNeeded()
                UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1, options: []) {
                    self.formBottomConstraint.constant = (self.view.bounds.size.height / 2)
                    self.view.layoutIfNeeded()
                }
            case .found(let user):
                statusLabel.text = "MATCH DETECTED"
                formView.isHidden = true
                candidateNameLabel.isHidden = false
                candidateNameLabel.text = user.name
                candidateImageView.image = user.avatar
                candidateView.isHidden = false
            case .form(let user):
                statusLabel.text = "WAITING TO SCAN"
                self.formView.isHidden = false
                view.layoutIfNeeded()
                UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1, options: []) {
                    self.formBottomConstraint.constant = 0
                    self.candidateView.isHidden = true
                    self.view.layoutIfNeeded()
                }
                formNameLabel.text = user.name
        }
        scoreValueLabel.text = "\(state.score) / 10"
        slider.value = Float(state.score)
    }

    func configureStatusView() {
        let statusView = UIView()
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusView.layer.cornerRadius = 16
        view.addSubview(statusView)
        statusView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        statusView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32).isActive = true
        statusView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32).isActive = true

        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "SCANNING FOR NAME"
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusView.addSubview(statusLabel)
        statusLabel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor).isActive = true
        statusLabel.topAnchor.constraint(equalTo: statusView.topAnchor, constant: 6).isActive = true
        statusLabel.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: -6).isActive = true
        statusLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 6).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -6).isActive = true
    }

    func configureCandidateView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        let candidateView = UIView()
        candidateView.translatesAutoresizingMaskIntoConstraints = false
        candidateView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        candidateView.layer.cornerRadius = 8
        candidateView.layer.addDropShadow()
        view.addSubview(candidateView)
        candidateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        candidateView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true

        candidateImageView = UIImageView(image: UIImage(systemName: "person.circle.fill")?.withRenderingMode(.alwaysTemplate))
        candidateImageView.translatesAutoresizingMaskIntoConstraints = false
        candidateImageView.tintColor = .gray
        candidateImageView.layer.cornerRadius = 75 / 2
        candidateImageView.clipsToBounds = true
        candidateImageView.contentMode = .scaleAspectFill
        candidateView.addSubview(candidateImageView)
        candidateImageView.centerXAnchor.constraint(equalTo: candidateView.centerXAnchor).isActive = true
        candidateImageView.topAnchor.constraint(equalTo: candidateView.topAnchor, constant: 16).isActive = true
        candidateImageView.widthAnchor.constraint(equalToConstant: 75).isActive = true
        candidateImageView.heightAnchor.constraint(equalToConstant: 75).isActive = true

        candidateNameLabel = UILabel()
        candidateNameLabel.translatesAutoresizingMaskIntoConstraints = false
        candidateNameLabel.text = "Nate Armstrong"
        candidateNameLabel.textColor = .black
        candidateNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        candidateView.addSubview(candidateNameLabel)
        candidateNameLabel.topAnchor.constraint(equalTo: candidateImageView.bottomAnchor, constant: 12).isActive = true
        candidateNameLabel.leadingAnchor.constraint(equalTo: candidateView.leadingAnchor, constant: 16).isActive = true
        candidateNameLabel.trailingAnchor.constraint(equalTo: candidateView.trailingAnchor, constant: -16).isActive = true
        candidateNameLabel.bottomAnchor.constraint(equalTo: candidateView.bottomAnchor, constant: -12).isActive = true

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        buttonContainer.topAnchor.constraint(equalTo: candidateView.bottomAnchor).isActive = true
        buttonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        buttonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        buttonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        let okButton = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.backgroundColor = .white
        okButton.layer.cornerRadius = 75 / 2
        okButton.tintColor = UIColor(red: 0/255, green: 172/255, blue: 24/255, alpha: 1)
        okButton.layer.addDropShadow()
        buttonContainer.addSubview(okButton)
        okButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor).isActive = true
        okButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor).isActive = true
        okButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        okButton.heightAnchor.constraint(equalToConstant: 75).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(candidateConfirmed))
        okButton.addGestureRecognizer(tap)
        okButton.isUserInteractionEnabled = true

        return view
    }

    func configureFormView() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.roundCorners(corners: [.topLeft, .topRight], radius: 8)
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        formBottomConstraint = container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        formBottomConstraint.isActive = true
        container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.5).isActive = true
        formContainerView = container

        formNameLabel = UILabel()
        formNameLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        formNameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(formNameLabel)
        formNameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16).isActive = true
        formNameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 16).isActive = true
        formNameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16).isActive = true

        let divider = UIView()
        divider.backgroundColor = .lightGray
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)
        divider.topAnchor.constraint(equalTo: formNameLabel.bottomAnchor, constant: 16).isActive = true
        divider.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        divider.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let scoreLabel = UILabel()
        scoreLabel.text = "Score:"
        scoreLabel.font = UIFont.systemFont(ofSize: 16)
        scoreLabel.textColor = .darkGray
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scoreLabel)
        scoreLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 32).isActive = true
        scoreLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16).isActive = true
        scoreLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16).isActive = true

        scoreValueLabel = UILabel()
        scoreValueLabel.text = "0 / 10"
        scoreValueLabel.textAlignment = .center
        scoreValueLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        scoreValueLabel.textColor = .black
        scoreValueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scoreValueLabel)
        scoreValueLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4).isActive = true
        scoreValueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16).isActive = true
        scoreValueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16).isActive = true

        slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 10
        slider.value = 0
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .primaryActionTriggered)
        container.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.topAnchor.constraint(equalTo: scoreValueLabel.bottomAnchor, constant: 32).isActive = true
        slider.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16).isActive = true

        let stepper = UIStepper()
        stepper.minimumValue = -1
        stepper.maximumValue = 1
        stepper.wraps = true
        stepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .primaryActionTriggered)
        container.addSubview(stepper)
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.centerYAnchor.constraint(equalTo: slider.centerYAnchor).isActive = true
        stepper.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 8).isActive = true
        stepper.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16).isActive = true

        let doneContainer = UIView()
        container.addSubview(doneContainer)
        doneContainer.translatesAutoresizingMaskIntoConstraints = false
        doneContainer.topAnchor.constraint(equalTo: stepper.bottomAnchor).isActive = true
        doneContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16).isActive = true
        doneContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        doneContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        let doneButton = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            self?.state.step = .scanning
        })
        doneButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        doneButton.tintColor = UIColor(red: 0/255, green: 172/255, blue: 24/255, alpha: 1)
        doneButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 50), forImageIn: .normal)
        doneContainer.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.centerYAnchor.constraint(equalTo: doneContainer.centerYAnchor).isActive = true
        doneButton.centerXAnchor.constraint(equalTo: doneContainer.centerXAnchor).isActive = true

        return container
    }

    @objc func sliderValueChanged(_ slider: UISlider) {
        state.score = Int(slider.value)
    }

    @objc func stepperValueChanged(_ stepper: UIStepper) {
        state.score = max(0, state.score + Int(stepper.value))
        stepper.value = 0
    }

    @objc func candidateConfirmed() {
        guard case .found(let user) = state.step else { return }
        state.step = .form(user)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        formContainerView.roundCorners(corners: [.topLeft, .topRight], radius: 8)
    }

    func recognizeText(cgImage: CGImage) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observerations = request.results as? [VNRecognizedTextObservation] else { return }
            for observervation in observerations {
                guard let bestCandidate = observervation.topCandidates(1).first else {
                    continue
                }
                print("Found this candidate: \(bestCandidate.string)")
                if let user = users.first(where: { bestCandidate.string.contains($0.name) }) {
                    self?.state.step = .found(user)
                }
            }
        }
        request.customWords = users.map(\.name)
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard case .scanning = state.step else { return }
        guard lastCaptureDate == nil || Date().timeIntervalSince(lastCaptureDate!) > captureInterval else {
            return
        }

        lastCaptureDate = Date()

        let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        print("captured image \(image), size: \(image.size), orientatiion: \(image.imageOrientation)")
        guard let cgImage = image.cgImage else { return }
        recognizeText(cgImage: cgImage)
    }

    func imageFromSampleBuffer(sampleBuffer:CMSampleBuffer!) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmapInfo:CGBitmapInfo = [.byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        let quartzImage = context.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)

        let image = UIImage(cgImage: quartzImage!)
        return image
    }
}

extension CALayer {
    fileprivate func addDropShadow() {
        shadowOffset = CGSize(width: 0, height: 4.0)
        shadowColor =  UIColor(white: 0, alpha: 1).cgColor
        shadowOpacity = 0.35
        shadowRadius = 8
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
