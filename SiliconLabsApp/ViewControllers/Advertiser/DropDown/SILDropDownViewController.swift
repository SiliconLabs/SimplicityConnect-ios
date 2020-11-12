//
//  SILDropDownViewController.swift
//  BlueGecko
//
//  Created by Michał Lenart on 13/10/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

import UIKit

protocol SILDropDownViewControllerDelegate: class {
    func dropDownDidSelect(value: String)
    func dropDownBackgroundTapped()
}

class SILDropDownViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet var backgroundView: SILPassthroughView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var backgroundGestureRecognizer: UITapGestureRecognizer!
    
    weak var delegate: SILDropDownViewControllerDelegate?
    var sourceView: UIView!
    var passthroughViews: [UIView] = []
    
    private var dataSource: [String] = []
    private var keyboardFrame = CGRect.zero
    private var isKeyboardPresent = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupLogic()
        
        updatePosition()
    }
    
    private func setupViews() {
        tableView.layer.cornerRadius = 4.0
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.16
        containerView.layer.shadowOffset = CGSize(width: 3, height: 3)
        containerView.layer.shadowRadius = 6.0
    }
    
    private func setupLogic() {
        backgroundView.passthroughViews = passthroughViews
        
        backgroundGestureRecognizer.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePosition()
    }
    
    func update(values: [String]) {
        dataSource = values
        tableView?.reloadData()
        updatePosition()
    }
    
    func updatePosition() {
        guard isViewLoaded else {
            return
        }
        
        let sourceOrigin = sourceView.convert(CGPoint.zero, to: nil)
        let startX = sourceOrigin.x
        let startY = sourceOrigin.y + sourceView.bounds.height + 2
        let width = sourceView.bounds.width
        
        let maxHeight = isKeyboardPresent
            ? keyboardFrame.origin.y - startY - 16
            : view.frame.height - startY - 16
        
        let height = min(maxHeight, tableView.contentSize.height)
        
        self.leftConstraint.constant = startX;
        self.topConstraint.constant = startY
        self.widthConstraint.constant = width
        self.heightConstraint.constant = height
    }
    
    // MARK: Background gesture recognizer
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == backgroundView
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        delegate?.dropDownBackgroundTapped()
    }
    
    // MARK: Keyboard visibility changed
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let frame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            isKeyboardPresent = true
            keyboardFrame = frame.cgRectValue
            updatePosition()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        isKeyboardPresent = false
        updatePosition()
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SILDropDownCellView") as! SILDropDownCellView
        cell.title.text = dataSource[indexPath.row]
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let value = dataSource[indexPath.row]
        delegate?.dropDownDidSelect(value: value)
    }
}
