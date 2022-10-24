//
//  UIButton+TapTap.m
//  UIButtonWithTapTap
//
//  Created by meterwhite on 2022/9/30.
//

#import "UIButton+TapTap.h"

#pragma mark - TapTapModel

@interface TapTapModel : NSObject

@property (nullable,nonatomic,copy) void(^whenTapTap)(UIButton *button);

@property (nullable,nonatomic,weak) UIButton *owner;

@property (nonatomic) NSTimeInterval interval;

@property (nullable,nonatomic,strong) NSDate *tapDate;

@property (nonatomic) SEL action;

@property (nonatomic,weak) id target;

/// 0 => None
/// 1 => one tape
/// 2 => double tape
@property (nonatomic) NSInteger state;

@end

@implementation TapTapModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _interval   = 2.f;
        _tapDate    = nil;
        _owner      = nil;
        _whenTapTap = nil;
        _state      = TapTapButtonStateNone;
    }
    return self;
}

- (void)buttonTaped:(UIButton *)sender {
    if(!self.tapDate) {
        [self setTapDate:[NSDate date]];
        [self setState:TapTapButtonStateTap];
        [self.owner setSelected:YES];
    } else {
        [self setTapDate:nil];
        [self setState:TapTapButtonStateTapTap];
        [self.owner setSelected:NO];
        if(self.whenTapTap) {
            self.whenTapTap(sender);
        }
        if(self.target && self.action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.target performSelector:self.action withObject:self.owner];
#pragma clang diagnostic pop
        }
    }
}

- (void)willRemove {
    if (!self.owner) {
        return;
    }
    // Recover button state
    if([[self.owner allTargets] containsObject:self]) {
        [self.owner removeTarget:self action:@selector(buttonTaped:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.owner.isSelected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.owner setSelected:NO];
            self.owner = nil;
        });
    } else {
        self.owner = nil;
    }
}

- (void)dealloc {
    [self willRemove];
}

@end

#pragma mark - TapTapManager

@interface TapTapManager : NSObject

@property (nullable,nonatomic,strong) NSMapTable<UIButton *, TapTapModel *> *mapItemModel;

@property (nullable,nonatomic,strong) NSTimer *looper;

@property (nullable,nonatomic,strong) NSLock *lock;

@end

@implementation TapTapManager


- (instancetype)init {
    self = [super init];
    if (self) {
        _mapItemModel = [NSMapTable weakToStrongObjectsMapTable];
        _lock = [NSLock new];
    }
    return self;
}

+ (instancetype)shared {
    static TapTapManager *_value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _value = [TapTapManager new];
        
    });
    return _value;
}

/// nil , wakeUp
- (void)loopWork:(id)option {
    if([self.lock tryLock]){
        if(option == nil) {
            NSArray *allKeys = NSAllMapTableKeys(self.mapItemModel); // NSAllMapTableKeys() will resizs map table.
            if(allKeys.count == 0) {
                [self deleteLoop];
                [self.mapItemModel removeAllObjects]; // Clean menmory of weak item.
            }
        } else if ([option isEqualToString:@"WAKE_UP"]) {
            if(!self.looper.isValid && self.mapItemModel.count > 0) {
                [self createLoop];
            }
        }
        [[self.mapItemModel objectEnumerator].allObjects enumerateObjectsUsingBlock:^(TapTapModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *bt = [self itemForStateModel:model];
            if(model.tapDate && bt) {
                if([[model.tapDate dateByAddingTimeInterval:model.interval] compare:[NSDate date]] <= NSOrderedSame) {
                    // Recover
                    [model setTapDate:nil];
                    [model setState:TapTapButtonStateNone];
                    if (bt.isSelected) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [bt setSelected:NO];
                        });
                    }
                }
            }
        }];
        [self.lock unlock];
    }
}

- (TapTapModel *)stateModelForItem:(id)key {
    return [self.mapItemModel objectForKey:key];
}

- (void)addStateModelToItem:(id)key {
    if (!key) {
        return;
    }
    [self removeStateModelForItem:key]; // Remove old model first
    TapTapModel *model = [TapTapModel new];
    model.owner = key;
    [key addTarget:model action:@selector(buttonTaped:) forControlEvents:(UIControlEventTouchUpInside)];
    {
        [self.lock lock];
        [self.mapItemModel setObject:model forKey:key];
        [self.lock unlock];
    }
    if(![TapTapManager shared].looper.isValid){
        [[TapTapManager shared] loopWork:@"WAKE_UP"]; // update immediately
    }
}

- (void)removeStateModelForItem:(id)key {
    if (!key) {
        return;
    }
    {
        [self.lock lock];
        TapTapModel *model = [self stateModelForItem:key];
        if (!model) {
            [self.lock unlock];
            return;
        } else {
            [model willRemove];
        }
        [self.mapItemModel removeObjectForKey:key];
        [self.lock unlock];
    }
}

- (UIButton *)itemForStateModel:(TapTapModel *)model {
    if (!model) {
        return nil;
    }
    UIButton *owner = model.owner;
    TapTapModel *latestModel = [self.mapItemModel objectForKey:owner];
    if(latestModel == model) {
        return owner;
    } else {
        /// Invalid model
        return nil;
    }
}

- (void)createLoop {
    if(self.looper) {
        [self deleteLoop];
    }
    self.looper = [NSTimer timerWithTimeInterval:1.f/24.f repeats:YES block:^(NSTimer * _Nonnull timer) {
        [[TapTapManager shared] loopWork:nil];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.looper forMode:NSRunLoopCommonModes];
}

- (void)deleteLoop {
    [self.looper invalidate];
    self.looper = nil;
}

@end

#pragma mark - UIButton(TapTap)

@implementation UIButton(TapTap)

- (instancetype)tt_refreshState {
    [self refreshStateModel];
    return self;
}

- (TapTapButtonState)tt_state {
    TapTapModel *model = [[TapTapManager shared] stateModelForItem:self];
    return model.state;
}

- (void)setTt_enable:(BOOL)tt_enable {
    if(tt_enable) {
        [self refreshStateModel];
    } else {
        [self removeStateModel];
    }
}

- (BOOL)tt_enable {
    TapTapModel *model = [[TapTapManager shared] stateModelForItem:self];
    return model ? YES : NO;
}

- (NSTimeInterval)tt_interval {
    TapTapModel *model = [[TapTapManager shared] stateModelForItem:self];
    return [model interval];
}

- (void)setTt_interval:(NSTimeInterval)tt_interval {
    if(!self.tt_enable) {
        [self refreshStateModel];
    }
    TapTapModel *model = [[TapTapManager shared] stateModelForItem:self];
    model.interval = tt_interval;
}

- (instancetype)tt_whenTapTaped:(void (^)(UIButton * _Nonnull sender))done {
    TapTapModel *model = [[TapTapManager shared] stateModelForItem:self];
    model.whenTapTap = done;
    return self;
}

- (instancetype)tt_addTarget:(id)target action:(SEL)action {
    TapTapModel *model = [[TapTapManager shared] stateModelForItem:self];
    model.target = target;
    model.action = action;
    return self;
}

- (void)refreshStateModel {
    [[TapTapManager shared] addStateModelToItem:self];
}

- (void)removeStateModel {
    [[TapTapManager shared] removeStateModelForItem:self];
}

@end
