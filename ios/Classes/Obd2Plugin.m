#import "Obd2Plugin.h"
#if __has_include(<obd2_plugin/obd2_plugin-Swift.h>)
#import <obd2_plugin/obd2_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "obd2_plugin-Swift.h"
#endif

@implementation Obd2Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftObd2Plugin registerWithRegistrar:registrar];
}
@end
