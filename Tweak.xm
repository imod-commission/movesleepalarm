#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 日志函数（写入 /var/mobile/Documents/MoveSleepAlarm.log）
static void logToFile(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *logPath = @"/var/mobile/Documents/MoveSleepAlarm.log";
    FILE *file = fopen([logPath UTF8String], "a");
    if (file) {
        fprintf(file, "[SB] %s\n", [message UTF8String]);
        fclose(file);
    }
}

@interface CSAdjunctItemView : UIView
@end

%hook CSAdjunctItemView

// 1. 视图刚创建或移动到窗口时，直接内联应用偏移（不加任何自定义方法）
- (void)didMoveToWindow {
    %orig; // 必须保留，让系统和其他插件先执行
    
    NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.imodcommission.movesleepalarm"];
    CGFloat yOffset = [prefs floatForKey:@"yOffset"];
    
    if (yOffset != 0) {
        self.transform = CGAffineTransformMakeTranslation(0, yOffset);
    } else {
        self.transform = CGAffineTransformIdentity;
    }
    logToFile(@"生命周期: didMoveToWindow, offset = %f", yOffset);
}

// 2. 视图布局时，同样内联应用
- (void)layoutSubviews {
    %orig;
    
    NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.imodcommission.movesleepalarm"];
    CGFloat yOffset = [prefs floatForKey:@"yOffset"];
    
    if (yOffset != 0) {
        self.transform = CGAffineTransformMakeTranslation(0, yOffset);
    } else {
        self.transform = CGAffineTransformIdentity;
    }
    logToFile(@"生命周期: layoutSubviews, offset = %f", yOffset);
}

%end

// 收到偏好通知时，遍历窗口查找目标视图，直接应用 transform
static void applyOffsetInView(UIView *view) {
    if ([view isKindOfClass:NSClassFromString(@"CSAdjunctItemView")]) {
        NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.imodcommission.movesleepalarm"];
        CGFloat yOffset = [prefs floatForKey:@"yOffset"];
        
        view.transform = CGAffineTransformMakeTranslation(0, yOffset);
        [view setNeedsLayout];
        [view layoutIfNeeded];
        logToFile(@"通知触发: 找到视图，强制应用 offset = %f", yOffset);
    }
    for (UIView *subview in view.subviews) {
        applyOffsetInView(subview);
    }
}

static void reloadPrefs() {
    logToFile(@"收到 Darwin 通知!");
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                applyOffsetInView(window);
            }
        }
    }
}

%ctor {
    logToFile(@"========== 插件重新加载 ==========");
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)reloadPrefs,
                                    CFSTR("com.imodcommission.movesleepalarm/ReloadPrefs"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}