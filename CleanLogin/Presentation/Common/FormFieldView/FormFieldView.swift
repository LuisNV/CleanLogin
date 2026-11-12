import UIKit

/// Nhãn và khung nhập liệu dùng chung cho text field hoặc control tùy chỉnh.
/// Màn hình gọi quản lý dữ liệu, delegate, bàn phím và thao tác của control.
final class FormFieldView: UIView {
    let control: UIControl
    private let titleLabel = UILabel()

    init(title: String, control: UIControl, height: CGFloat = 52) {
        self.control = control
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor(white: 0.25, alpha: 1)
        control.accessibilityLabel = title
        control.backgroundColor = .white
        control.layer.cornerRadius = 9
        control.layer.borderWidth = 1
        control.layer.borderColor = UIColor(red: 0.84, green: 0.85, blue: 0.89, alpha: 1).cgColor
        control.heightAnchor.constraint(equalToConstant: height).isActive = true

        if let field = control as? UITextField {
            field.font = .systemFont(ofSize: 16)
            field.textColor = AppColors.text
            if field.leftView == nil {
                field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
                field.leftViewMode = .always
            }
            if field.placeholder == nil {
                field.placeholder = title
            }
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, control])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(title:control:height:)")
    }
}
