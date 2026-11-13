import UIKit

/// Bộ chọn ngày dùng chung. Chỉ trả kết quả khi người dùng bấm Chọn;
/// bấm Hủy hoặc kéo đóng sheet không thay đổi giá trị của màn hình gọi.
@MainActor
enum DatePickerSheet {
    static func present(
        from presenter: UIViewController,
        title: String = "Chọn ngày",
        selectedDate: Date? = nil,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        locale: Locale = Locale(identifier: "vi_VN"),
        onSelect: @escaping (Date) -> Void
    ) {
        guard presenter.presentedViewController == nil else { return }
        if let minimumDate, let maximumDate {
            precondition(minimumDate <= maximumDate, "minimumDate must not exceed maximumDate")
        }
        presenter.view.endEditing(true)
        let content = DatePickerSheetViewController(
            title: title,
            selectedDate: selectedDate ?? Date(),
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            locale: locale,
            onSelect: onSelect
        )
        let navigation = UINavigationController(rootViewController: content)
        navigation.modalPresentationStyle = .pageSheet
        if let sheet = navigation.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let compact = UISheetPresentationController.Detent.Identifier("datePickerCompact")
                sheet.detents = [.custom(identifier: compact) { context in
                    min(300, context.maximumDetentValue)
                }]
                sheet.selectedDetentIdentifier = compact
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        presenter.present(navigation, animated: true)
    }
}

private final class DatePickerSheetViewController: UIViewController {
    private let datePicker = UIDatePicker()
    private let onSelect: (Date) -> Void

    init(
        title: String,
        selectedDate: Date,
        minimumDate: Date?,
        maximumDate: Date?,
        locale: Locale,
        onSelect: @escaping (Date) -> Void
    ) {
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        self.title = title
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = locale
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate
        var initialDate = selectedDate
        if let minimumDate { initialDate = max(initialDate, minimumDate) }
        if let maximumDate { initialDate = min(initialDate, maximumDate) }
        datePicker.date = initialDate
    }

    required init?(coder: NSCoder) {
        fatalError("Use the custom initializer")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Hủy", style: .plain, target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Chọn", style: .plain, target: self, action: #selector(confirm)
        )
        for item in [navigationItem.leftBarButtonItem, navigationItem.rightBarButtonItem] {
            item?.tintColor = AppColors.primary
            if #available(iOS 26.0, *) {
                item?.hidesSharedBackground = true
            }
        }

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            datePicker.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            datePicker.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func confirm() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        let date = datePicker.date
        let completion = onSelect
        dismiss(animated: true) {
            completion(date)
        }
    }
}
