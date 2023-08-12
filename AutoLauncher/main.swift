//
//  main.swift
//  AutoLauncher
//
//  Created by Daniel Agapov on 2023-08-12.
//

import Foundation

import Cocoa

let delegate = AutoLauncherAppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
