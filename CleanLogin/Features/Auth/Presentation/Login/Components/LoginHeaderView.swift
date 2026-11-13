//
//  LoginHeaderView.swift
//  CleanLogin
//
//  Created by Administrator on 2/11/26.
//
import UIKit

final class LoginHeaderView: UIView {
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "TingTingLogo")
        imageView.tintColor = .white
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    private let logoContainer: UIView = {
        let view = UIView()
        //        view.backgroundColor = UIColor(
        //            red: 0.16,
        //            green: 0.43,
        //            blue: 0.96,
        //            alpha: 1
        //        )
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "TingTing"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(
            red: 0.05,
            green: 0.09,
            blue: 0.20,
            alpha: 1
        )
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Học tiếng Trung dễ dàng mỗi ngày"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            logoContainer,
            titleLabel,
            subtitleLabel
        ])
        
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        
        addSubview(stack)
        logoContainer.addSubview(logoImageView)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        stack.setCustomSpacing(14, after: logoContainer)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            logoContainer.widthAnchor.constraint(equalToConstant: 80),
            logoContainer.heightAnchor.constraint(equalToConstant: 80),
            
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
}
