//
//  TextFieldTableViewCell.swift
//  SiliconLabsApp
//
//  Created by Max Litteral on 7/25/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

import UIKit

protocol TextFieldTableViewCellDelegate: class {
    func textFieldDidEndEditing(_ textField: UITextField)
}

@objc(SILTextFieldTableViewCell)
final class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    // MARK: - Properties

    static let cellIdentifier = "TextFieldTableViewCell"

    private struct Constants {
        static let placeholderFont = UIFont.helveticaNeue(size: 14) ?? UIFont.systemFont(ofSize: 14)
        static let placeholderColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:0.54)
        static let textFieldFont = UIFont.helveticaNeue(size: 16)
        static let textFieldTextColor = UIColor(red:0.31, green:0.31, blue:0.31, alpha:1.00)
    }

    weak var delegate: TextFieldTableViewCellDelegate? = nil

    var placeholder: String? {
        get {
            return textField.attributedPlaceholder?.string
        }
        set {
            let attributes: [String : Any] = [
                NSFontAttributeName : Constants.placeholderFont,
                NSForegroundColorAttributeName : Constants.placeholderColor
            ]
            if let newValue = newValue {
                textField.attributedPlaceholder = NSAttributedString(string: newValue, attributes: attributes)
            } else {
                textField.attributedPlaceholder = nil
            }
        }
    }

    var textFieldText: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
        }
    }

    private var textField = SearchIconTextField()
    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .sil_lineGrey()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textField.text = nil
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textFieldDidEndEditing(textField)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }

    // MARK: Setup

    private func setup() {
        setupTextField()
        setupTextFieldUnderline()
        setupDivider()

        contentView.backgroundColor = .white
    }

    private func setupTextField() {
        textField.delegate = self
        textField.font = Constants.textFieldFont
        textField.textColor = Constants.textFieldTextColor
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
        contentView.addSubview(textField)

        textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }

    private func setupTextFieldUnderline() {
        let underline = UIView()
        underline.backgroundColor = .sil_lineGrey()
        underline.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(underline)

        underline.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        underline.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        underline.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 5).isActive = true
        underline.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private func setupDivider() {
        addSubview(divider)

        divider.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        divider.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        divider.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        divider.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
}

private final class SearchIconTextField: UITextField {

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var bounds = bounds
        bounds.size.width = bounds.height + 8
        return bounds
    }

    // MARK: - Setup

    private func setup() {
        setupLeftView()
    }

    private func setupLeftView() {
        let searchIconView = UIImageView(image: #imageLiteral(resourceName: "icSearchName"))
        searchIconView.contentMode = .center
        searchIconView.translatesAutoresizingMaskIntoConstraints = false

        let leftView = UIView()
        leftView.addSubview(searchIconView)

        self.leftView = leftView
        self.leftViewMode = .unlessEditing

        searchIconView.leadingAnchor.constraint(equalTo: leftView.leadingAnchor).isActive = true
        searchIconView.widthAnchor.constraint(equalTo: searchIconView.heightAnchor).isActive = true
        searchIconView.topAnchor.constraint(equalTo: leftView.topAnchor).isActive = true
        searchIconView.bottomAnchor.constraint(equalTo: leftView.bottomAnchor).isActive = true
    }
}
