//
//  main.m
//  ThisWayIsUp
//
//  Created by Philippe Hausler on 11/1/12.
//  Copyright (c) 2012 Apportable. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SpinAppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
#ifdef ANDROID
        [UIScreen mainScreen].currentMode = [UIScreenMode emulatedMode:UIScreenBestEmulatedMode];
#endif
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SpinAppDelegate class]));
    }
}
