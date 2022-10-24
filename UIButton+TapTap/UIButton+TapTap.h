//
//  UIButton+TapTap.h
//  UIButtonWithTapTap
//
//  Created by meterwhite on 2022/9/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TapTapButtonStateNone = 0, // Default
    TapTapButtonStateTap,
    TapTapButtonStateTapTap,
} TapTapButtonState;

/// When you click the button for the first time, the button status changes to Selected; Tapping the button again within the default time triggers the event TapTap.
/// If the button is not clicked within the default time, it will revert to Normal.
/// Button status can be obtained through didTapTap: or tt_state.
@interface UIButton(TapTap)

/// XIB supported.
/// Called before selector(addTarget:action:forControlEvents:)
@property IBInspectable BOOL tt_enable;
/// Default value is 2 sec.
@property (nonatomic) NSTimeInterval tt_interval;

@property (nonatomic,readonly) TapTapButtonState tt_state;

/// Called before selector(addTarget:action:forControlEvents:)
/// Called before the UITableViewCell be returnd
- (instancetype)tt_refreshState;

/// Callback
- (instancetype)tt_whenTapTaped:(void(^_Nullable)(UIButton * _Nonnull sender))done;

/// @param target Do not reference
/// @param action - action:(sender)
- (instancetype)tt_addTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
