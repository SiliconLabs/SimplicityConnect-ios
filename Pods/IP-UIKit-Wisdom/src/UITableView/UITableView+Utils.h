
@import UIKit;

@interface UITableView (Utils)

/**
 *  Adjust UITableView to remove separator insets. Note that this must be called on both the
 *  table view and the cell's awakeFromNib.
 */
- (void)ip_setZeroSeparatorInsets;

/**
 *  Adjust UITableView scroll inset to account for a bottom view, like a tab bar.
 */
- (void)ip_adjustInsetsForBottomLayoutGuideHeight:(UIViewController * _Nonnull)controller;

@end

@interface UITableViewCell (Utils)

/**
 *  Adjust UITableViewCell to remove separator insets. Note that this must be called on both the
 *  table view and the cell's awakeFromNib.
 */
- (void)ip_setZeroSeparatorInsets;

/**
 *  Traverses the view hierarchy to find the table view that contains this table view cell.
 */
- (UITableView * _Nullable)ip_owningTableView;

@end
