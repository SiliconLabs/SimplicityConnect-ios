//
//  Created by merowing on 22/04/2014.
//
//
//

@import UIKit;
@import Foundation;

#ifndef IBInspectable
  #define IBInspectable
#endif

@interface KZBehaviour : UIControl

//! object that this controller life will be bound to
@property(nonatomic, weak) IBOutlet id owner;

- (void)kzc_bindLifetimeToObject:(id)object;
- (void)kzc_releaseLifetimeFromObject:(id)object;
@end