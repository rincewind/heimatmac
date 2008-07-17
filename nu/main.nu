;; main.nu
;; Entry point for a Nu program.
;;
;; Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.


(load "bridgesupport")
(import AddressBook) ;; AddressBook framework
(load "AddressBook")
;;(puts ((BridgeSupport "constants") description))
;;(puts ((BridgeSupport  "frameworks") description))
;;(puts ((BridgeSupport  "functions") description))
;;(puts ((BridgeSupport  "enums") description))

(load "nu")      	;; essentials
(load "cocoa")		;; wrapped frameworks
(load "menu")		;; menu generation
(load "console")	;; interactive console



(set SHOW_CONSOLE_AT_STARTUP nil)

(class ABPerson
     (- firstName is
        (self valueForProperty: kABLastNameProperty)))

(class MainWindowController is NSWindowController
     (ivar (id) tableview)
     (- init is
        (self initWithWindowNibName:"MainWindow")
       ;; ((self people) each: (do (peep) (NSLog "#{(peep firstName)}")))
        ((self window) makeKeyAndOrderFront:self)
        self)
     
     (- (id) people is
        ;;        (((ABAddressBook sharedAddressBook) people) each: (do (peep) (puts (peep firstName))))
        ((((ABAddressBook sharedAddressBook) people) retain) autorelease)))

(class ApplicationDelegate is NSObject
     
     (- (void) applicationDidFinishLaunching: (id) sender is
        (set $console ((NuConsoleWindowController alloc) init))
        (if SHOW_CONSOLE_AT_STARTUP ($console toggleConsole:self))
        (set $mainwindowcontroller ((MainWindowController alloc) init))
        ))


((NSApplication sharedApplication) setDelegate:(set $delegate ((ApplicationDelegate alloc) init)))
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)
(NSApplicationMain 0 nil)
