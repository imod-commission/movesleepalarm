#import "MoveSleepAlarmRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>

// 写入文件的日志函数
static void logToFile(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *logPath = @"/tmp/MoveSleepAlarm.log";
    FILE *file = fopen([logPath UTF8String], "a");
    if (file) {
        fprintf(file, "[Prefs] %s\n", [message UTF8String]);
        fclose(file);
    }
}

@implementation MoveSleepAlarmRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray new];
        
        PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"MoveSleepAlarm"];
        [group setProperty:@"输入 Y 轴偏移量，实时生效。正数向下，负数向上（例如 -50）。" forKey:@"footerText"];
        [specifiers addObject:group];
        
        PSSpecifier *textField = [PSSpecifier preferenceSpecifierNamed:@"Y轴偏移量"
                                                                target:self
                                                                   set:@selector(setPreferenceValue:specifier:)
                                                                   get:@selector(readPreferenceValue:)
                                                                detail:nil
                                                                  cell:PSEditTextCell
                                                                  edit:nil];
        [textField setProperty:@"yOffset" forKey:@"key"];
        [textField setProperty:@"com.imodcommission.movesleepalarm" forKey:@"defaults"];
        [textField setProperty:@"0" forKey:@"placeholder"];
        [textField setProperty:@(UIKeyboardTypeNumbersAndPunctuation) forKey:@"keyboardType"];
        [specifiers addObject:textField];
        
        _specifiers = specifiers;
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    logToFile(@"收到输入: %@, 类型: %@", value, [value class]);
    
    if ([value isKindOfClass:[NSString class]]) {
        CGFloat floatValue = [value floatValue];
        value = @(floatValue);
    }
    
    [super setPreferenceValue:value specifier:specifier];
    logToFile(@"保存到 %@, 值为: %@", specifier.properties[@"defaults"], value);
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.imodcommission.movesleepalarm/ReloadPrefs"),
                                         NULL, NULL, YES);
    logToFile(@"已发送刷新通知");
}

@end