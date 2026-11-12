import UIKit
import PhotosUI

/// A local editing draft. Persist through a repository when an update API is available.
struct ProfileEditDraft {
    let user: ProfileUser
    var birthday: Date?
    var gender: String?
    var avatar: UIImage?
}

final class EditProfileViewController: UIViewController, PHPickerViewControllerDelegate {
    var onSave: ((ProfileEditDraft) -> Void)?

    private let draft: ProfileEditDraft
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let birthdayField = UITextField()
    private let addressField = UITextField()
    private let genderButton = UIButton(type: .custom)
    private let genderValueLabel = UILabel()
    private let avatarLabel = UILabel()
    private let avatarImage = UIImageView()
    private let datePicker = UIDatePicker()
    private var selectedBirthday: Date?
    private var selectedGender: String?
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    init(draft: ProfileEditDraft) {
        self.draft = draft
        selectedBirthday = draft.birthday
        selectedGender = draft.gender
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
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: AppColors.text,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain,
            target: self, action: #selector(close)
        )
        navigationItem.leftBarButtonItem?.tintColor = AppColors.text
        setupLayout()
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
        stack.addArrangedSubview(makeField("Họ và tên", control: nameField))
        stack.addArrangedSubview(makeField("Email", control: emailField))
        stack.addArrangedSubview(makeField("Số điện thoại", control: phoneField))
        let pair = UIStackView(arrangedSubviews: [
            makeField("Ngày sinh", control: birthdayField),
            makeField("Giới tính", control: genderButton)
        ])
        pair.spacing = 16
        pair.distribution = .fillEqually
        stack.addArrangedSubview(pair)
        let address = makeField("Địa chỉ", control: addressField)
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

    private func makeAvatarHeader() -> UIView {
        let header = UIStackView()
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 8
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.text = draft.user.initials
        avatarLabel.textAlignment = .center
        avatarLabel.font = .systemFont(ofSize: 34, weight: .bold)
        avatarLabel.textColor = AppColors.text
        avatarLabel.backgroundColor = AppColors.avatarBackground
        avatarImage.image = draft.avatar
        avatarImage.contentMode = .scaleAspectFill
        for child in [avatarLabel, avatarImage] {
            child.translatesAutoresizingMaskIntoConstraints = false
            child.layer.cornerRadius = 48
            child.clipsToBounds = true
            container.addSubview(child)
            NSLayoutConstraint.activate([
                child.topAnchor.constraint(equalTo: container.topAnchor),
                child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                child.widthAnchor.constraint(equalToConstant: 96),
                child.heightAnchor.constraint(equalToConstant: 96)
            ])
        }
        let camera = UIButton(type: .system)
        camera.translatesAutoresizingMaskIntoConstraints = false
        camera.setImage(UIImage(systemName: "camera.fill"), for: .normal)
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
            camera.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            camera.bottomAnchor.constraint(equalTo: container.bottomAnchor)
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

    private func makeField(_ title: String, control: UIView) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(white: 0.25, alpha: 1)
        control.accessibilityLabel = title
        control.backgroundColor = .white
        control.layer.cornerRadius = 9
        control.layer.borderWidth = 1
        control.layer.borderColor = UIColor(red: 0.84, green: 0.85, blue: 0.89, alpha: 1).cgColor
        control.heightAnchor.constraint(equalToConstant: 52).isActive = true
        if let field = control as? UITextField {
            field.font = .systemFont(ofSize: 16)
            field.textColor = AppColors.text
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
            field.leftViewMode = .always
            field.placeholder = title
            field.rightViewMode = .never
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.items = [
                UIBarButtonItem(systemItem: .flexibleSpace),
                UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(endEditing))
            ]
            field.inputAccessoryView = toolbar
        }
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }

    private func configureInputs() {
        nameField.text = draft.user.fullName
        nameField.textContentType = .name
        nameField.autocapitalizationType = .words
        emailField.text = draft.user.email
        emailField.textContentType = .emailAddress
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        phoneField.text = draft.user.phone
        phoneField.textContentType = .telephoneNumber
        phoneField.keyboardType = .phonePad
        addressField.text = draft.user.address
        addressField.textContentType = .fullStreetAddress

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "vi_VN")
        datePicker.maximumDate = Date()
        datePicker.date = selectedBirthday ?? Date()
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        birthdayField.inputView = datePicker
        birthdayField.placeholder = "dd/MM/yyyy"
        birthdayField.text = selectedBirthday.map { dateFormatter.string(from: $0) }
        birthdayField.addTarget(self, action: #selector(dateChanged), for: .editingDidBegin)
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

        genderValueLabel.text = selectedGender ?? "Chọn"
        genderValueLabel.font = .systemFont(ofSize: 16)
        genderValueLabel.textColor = AppColors.text
        genderButton.accessibilityValue = selectedGender ?? "Chọn"
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
                self?.selectedGender = gender
                self?.genderValueLabel.text = gender
                self?.genderButton.accessibilityValue = gender
            }
        })
    }

    @objc private func dateChanged() {
        selectedBirthday = datePicker.date
        birthdayField.text = dateFormatter.string(from: datePicker.date)
    }

    @objc private func endEditing() {
        view.endEditing(true)
    }

    @objc private func close() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func save() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, email.contains("@"), email.split(separator: "@").count == 2 else {
            showError("Vui lòng nhập họ tên và email hợp lệ.")
            return
        }
        let user = ProfileUser(
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
