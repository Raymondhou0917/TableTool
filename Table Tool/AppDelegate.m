//
//  AppDelegate.m
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // The original custom table cells and toolbar artwork were designed for Aqua.
    NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    NSMenu *applicationMenu = NSApp.mainMenu.itemArray.firstObject.submenu;
    NSMenuItem *languageItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Language", nil) action:nil keyEquivalent:@""];
    languageItem.submenu = [[NSMenu alloc] initWithTitle:languageItem.title];
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSArray *savedLanguages = [[NSUserDefaults.standardUserDefaults persistentDomainForName:bundleID] objectForKey:@"AppleLanguages"];
    NSString *selectedLanguage = savedLanguages.firstObject ?: @"system";
    NSArray *choices = @[
        @[NSLocalizedString(@"System Default", nil), @"system"],
        @[@"English", @"en"],
        @[@"繁體中文", @"zh-Hant"]
    ];
    for (NSArray *choice in choices) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:choice[0] action:@selector(chooseLanguage:) keyEquivalent:@""];
        item.target = self;
        item.representedObject = choice[1];
        item.state = [choice[1] isEqualToString:selectedLanguage] ? NSControlStateValueOn : NSControlStateValueOff;
        [languageItem.submenu addItem:item];
    }
    [applicationMenu insertItem:languageItem atIndex:MIN(2, applicationMenu.numberOfItems)];
}

- (void)chooseLanguage:(NSMenuItem *)sender {
    if (sender.state == NSControlStateValueOn) return;
    NSString *language = sender.representedObject;
    if ([language isEqualToString:@"system"]) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"AppleLanguages"];
    } else {
        [NSUserDefaults.standardUserDefaults setObject:@[language] forKey:@"AppleLanguages"];
    }
    for (NSMenuItem *item in sender.menu.itemArray) {
        item.state = item == sender ? NSControlStateValueOn : NSControlStateValueOff;
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Language saved", nil);
    alert.informativeText = NSLocalizedString(@"Reopen Table Tool Native to apply the language. Save your open documents before quitting.", nil);
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alert runModal];
}

@end
