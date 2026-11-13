import UIKit
import PhotosUI

final class EditProfileViewController: UIViewController, PHPickerViewControllerDelegate, UITextFieldDelegate {
    var onSave: ((ProfileEditDraft) -> Void)?
    
    private let viewModel: EditProfileViewModel
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let birthdayField = UITextField()
    private let addressField = UITextField()
    private let genderButton = UIButton(type: .custom)
    private let genderValueLabel = UILabel()
    private let avatarLabel = UILabel()
    private let avatarImage = UIImageView()
    convenience init(draft: ProfileEditDraft) {
        self.init(viewModel: EditProfileViewModel(draft: draft))
    }

    init(viewModel: EditProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use init(draft:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        navigationItem.title = "Chỉnh sửa thông tin"
        navigationItem.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: AppColors.text,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain,
            target: self, action: #selector(close)
        )
        navigationItem.leftBarButtonItem?.tintColor = AppColors.text
        setupLayout()
        setupBackground()
        configureInputs()
    }
    
    private func setupLayout() {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        for child in [scrollView, stack] {
            child.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -36),
            stack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        
        let header = makeAvatarHeader()
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(24, after: header)
        stack.addArrangedSubview(FormFieldView(title: "Họ và tên", control: nameField))
        stack.addArrangedSubview(FormFieldView(title: "Email", control: emailField))
        stack.addArrangedSubview(FormFieldView(title: "Số điện thoại", control: phoneField))
        let pair = UIStackView(arrangedSubviews: [
            FormFieldView(title: "Ngày sinh", control: birthdayField),
            FormFieldView(title: "Giới tính", control: genderButton)
        ])
        pair.spacing = 16
        pair.distribution = .fillEqually
        stack.addArrangedSubview(pair)
        let address = FormFieldView(title: "Địa chỉ", control: addressField)
        stack.addArrangedSubview(address)
        stack.setCustomSpacing(32, after: address)
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Lưu thay đổi", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        saveButton.backgroundColor = AppColors.primary
        saveButton.layer.cornerRadius = 10
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        stack.addArrangedSubview(saveButton)
    }
    private func setupBackground() {
        let backgroundView = UIImageView(image: UIImage(named: "backgroundMobile"))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.clipsToBounds = true
        backgroundView.isAccessibilityElement = false
        view.insertSubview(backgroundView, at: 0)
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.65)
        overlayView.isUserInteractionEnabled = false
        overlayView.isAccessibilityElement = false
        view.insertSubview(overlayView, aboveSubview: backgroundView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    private func makeAvatarHeader() -> UIView {
        let header = UIStackView()
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 8
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.text = viewModel.initials
        avatarLabel.textAlignment = .center
        avatarLabel.font = .systemFont(ofSize: 34, weight: .bold)
        avatarLabel.textColor = AppColors.text
        avatarLabel.backgroundColor = AppColors.avatarBackground
        avatarImage.image = viewModel.avatar
        avatarImage.contentMode = .scaleAspectFill
        for child in [avatarLabel, avatarImage] {
            child.translatesAutoresizingMaskIntoConstraints = false
            child.layer.cornerRadius = 48
            child.clipsToBounds = true
            container.addSubview(child)
            NSLayoutConstraint.activate([
                child.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                child.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                child.widthAnchor.constraint(equalToConstant: 96),
                child.heightAnchor.constraint(equalToConstant: 96)
            ])
        }
        let camera = UIButton(type: .custom)
        camera.translatesAutoresizingMaskIntoConstraints = false
        let cameraImage = UIImage(
            systemName: "camera.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        )
        camera.setImage(cameraImage, for: .normal)
        camera.contentHorizontalAlignment = .center
        camera.contentVerticalAlignment = .center
        camera.imageView?.contentMode = .scaleAspectFit
        camera.tintColor = .white
        camera.backgroundColor = AppColors.primary
        camera.layer.cornerRadius = 15
        camera.layer.borderWidth = 2
        camera.layer.borderColor = AppColors.background.cgColor
        camera.accessibilityLabel = "Đổi ảnh đại diện"
        camera.addTarget(self, action: #selector(choosePhoto), for: .touchUpInside)
        container.addSubview(camera)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 96),
            container.heightAnchor.constraint(equalToConstant: 96),
            camera.widthAnchor.constraint(equalToConstant: 30),
            camera.heightAnchor.constraint(equalToConstant: 30),
            camera.trailingAnchor.constraint(equalTo: avatarLabel.trailingAnchor),
            camera.bottomAnchor.constraint(equalTo: avatarLabel.bottomAnchor)
        ])
        let change = UIButton(type: .system)
        change.setTitle("Đổi ảnh đại diện", for: .normal)
        change.setTitleColor(AppColors.primary, for: .normal)
        change.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        change.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        change.addTarget(self, action: #selector(choosePhoto), for: .touchUpInside)
        header.addArrangedSubview(container)
        header.addArrangedSubview(change)
        return header
    }
    
    private func configureInputs() {
        for field in [nameField, emailField, phoneField, birthdayField, addressField] {
            field.returnKeyType = .done
            field.delegate = self
        }
        nameField.text = viewModel.fullName
        nameField.textContentType = .name
        nameField.autocapitalizationType = .words
        emailField.text = viewModel.email
        emailField.textContentType = .emailAddress
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        phoneField.text = viewModel.phone
        phoneField.textContentType = .telephoneNumber
        phoneField.keyboardType = .phonePad
        addressField.text = viewModel.address
        addressField.textContentType = .fullStreetAddress
        
        birthdayField.delegate = self
        birthdayField.inputAccessoryView = nil
        birthdayField.placeholder = "dd/MM/yyyy"
        birthdayField.text = viewModel.birthdayText
        let icon = UIImageView(image: UIImage(systemName: "calendar"))
        icon.tintColor = AppColors.secondaryText
        icon.contentMode = .scaleAspectFit
        // Reserve separate space for the icon and the trailing inset.
        let accessory = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 24))
        icon.frame = CGRect(x: 6, y: 2, width: 20, height: 20)
        accessory.addSubview(icon)
        birthdayField.rightView = accessory
        birthdayField.font = .systemFont(ofSize: 16)
        birthdayField.adjustsFontSizeToFitWidth = true
        birthdayField.minimumFontSize = 14
        birthdayField.rightViewMode = .always
        
        genderValueLabel.text = viewModel.gender ?? "Chọn"
        genderValueLabel.font = .systemFont(ofSize: 16)
        genderValueLabel.textColor = AppColors.text
        genderButton.accessibilityValue = viewModel.gender ?? "Chọn"
        let chevron = UIImageView(image: UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        ))
        chevron.tintColor = AppColors.secondaryText
        chevron.contentMode = .scaleAspectFit
        for child in [genderValueLabel, chevron] {
            child.translatesAutoresizingMaskIntoConstraints = false
            child.isUserInteractionEnabled = false
            child.isAccessibilityElement = false
            genderButton.addSubview(child)
        }
        NSLayoutConstraint.activate([
            genderValueLabel.leadingAnchor.constraint(equalTo: genderButton.leadingAnchor, constant: 14),
            genderValueLabel.centerYAnchor.constraint(equalTo: genderButton.centerYAnchor),
            genderValueLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -10),
            chevron.trailingAnchor.constraint(equalTo: genderButton.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: genderButton.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 20),
            chevron.heightAnchor.constraint(equalToConstant: 20)
        ])
        genderButton.showsMenuAsPrimaryAction = true
        genderButton.menu = UIMenu(children: ["Nam", "Nữ", "Khác"].map { gender in
            UIAction(title: gender) { [weak self] _ in
                self?.viewModel.gender = gender
                self?.genderValueLabel.text = gender
                self?.genderButton.accessibilityValue = gender
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard textField === birthdayField else { return true }
        showBirthdaySheet()
        return false
    }
    
    private func showBirthdaySheet() {
        DatePickerSheet.present(
            from: self,
            title: "Ngày sinh",
            selectedDate: viewModel.birthday,
            maximumDate: Date()
        ) { [weak self] date in
            guard let self else { return }
            self.viewModel.birthday = date
            self.birthdayField.text = self.viewModel.birthdayText
        }
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
    
    @objc private func close() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func save() {
        viewModel.fullName = nameField.text ?? ""
        viewModel.email = emailField.text ?? ""
        viewModel.phone = phoneField.text ?? ""
        viewModel.address = addressField.text ?? ""

        do {
            let draft = try viewModel.makeDraft()
            onSave?(draft)
            close()
        } catch {
            showError(error.localizedDescription)
        }
        let user = EditableProfile(
            fullName: name, email: email,
            phone: (phoneField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            address: (addressField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave?(ProfileEditDraft(user: user, birthday: selectedBirthday, gender: selectedGender, avatar: avatarImage.image))
        close()
    }
    

    @objc private func choosePhoto() {
        view.endEditing(true)
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            let image = object as? UIImage
            Task { @MainActor [weak self] in
                if let image {
                    self?.viewModel.avatar = image
                    self?.avatarImage.image = image
                } else {
                    self?.showError("Không thể tải ảnh. Vui lòng chọn ảnh khác.")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Kiểm tra thông tin", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default))
        present(alert, animated: true)
    }
}
