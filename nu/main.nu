;; main.nu
;;
;; Copyright (c) 2008 Peter Quade, based on work from Tim Burks


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
(load "coredata")


(load "textimagecell")

(((NSUserDefaults alloc) init) setInteger: 1 forKey: "com.apple.CoreData.SQLDebug")


(class HMMembership is NSManagedObject
       (ivar (id) startDate (id) endDate)
       (- (id) title is
	  "Unknown Member")
       (- (id) street is
	  "Unknown Street")
       (- (id) place is
	  "Unknown Place")
       (- (BOOL) isActive is
	  (let ((now (NSDate date)))
	    (if (and (eq @startDate (now earlierDate: @startDate))
		     (or (not @endDate)
			 (eq @endDate (now laterDate: @endDate))))
		YES
		(else NO)))))
       

(class HMPayment is NSManagedObject)
(class HMPerson is NSManagedObject)
(class HMMembershipType is NSManagedObject)


(class SourceListItem is NSObject
       (ivar (id) subitems (id) title (BOOL) isGroup (BOOL) isLeaf)
       (ivar-accessors)

       (+ (id) groupWithTitle: (id) title subitems: (id) subitems is
	  ((SourceListItem alloc) initWithTitle: title group: YES subitems: subitems))

       (+ (id) itemWithTitle: (id) title subitems: (id) subitems is
	  ((SourceListItem alloc) initWithTitle: title group: NO subitems: subitems))

       (- (id) initWithTitle: (id) title group: (BOOL) isGroup subitems: (id) subitems is
	  (set self (super init))
	  (if self
	      (set @title title)
	      (set @subitems subitems)
	      (set @isGroup isGroup)
	      (set @isLeaf NO)
	  ;; hack. remove me. isLeaf has to be property, when unset make subitems array containg only self!
	  ;; why is that?
	      (if (== (@subitems count) 0)
		  (set @isLeaf YES)
		  (set @subitems (array self))))	  
	  self)
	  

       (- dealloc is
	  (@subitems release)
	  (@title release)
	  (super dealloc)))



(set SHOW_CONSOLE_AT_STARTUP nil)

(class ABPerson
     (- firstName is
        (self valueForProperty: kABLastNameProperty)))

(class MainWindowController is NSWindowController
     (ivar (id) sourcelist (id) sourceListEntries)

     (- init is
	(set self (super init))
	(if self
	    (self initWithWindowNibName:"MainWindow")
	    ((self window) makeKeyAndOrderFront:self)

	    (set @sourceListEntries 
		 (NSArray arrayWithList: (list 
					  (SourceListItem groupWithTitle: "BANANEN" subitems: 
							  (array 
							   (SourceListItem itemWithTitle: "Gelb" subitems: (array)) 
							   (SourceListItem itemWithTitle: "Krumm" subitems: (array)))) 
					  (SourceListItem groupWithTitle: "KIRSCHEN" subitems: 
							  (array (SourceListItem itemWithTitle: "Suess" subitems: (array))))))))
	   

        self)

	 

     (- (BOOL) outlineView: (id) sender isGroupItem: (id) item is
	((item representedObject) isGroup))

    ;; (- (void) outlineView: (id) sender willDisplayCell:(id)cell forTableColumn:(id)tableColumn item:(id)item is)

     
     (- (BOOL)outlineView:(id)outlineView shouldSelectItem:(id)item is

	;; don't allow special group nodes to be selected
	(if ((item representedObject) isGroup) NO (else YES)))

     (- (void) awakeFromNib is
	;;(set col (@sourcelist tableColumnWithIdentifier: @"MainColumn"))
	;;(set $cell ((TextImageCell alloc) init)) ;; we need to keep the cell around somewhere
	;;(col setDataCell: $cell)
	))



(class ApplicationDelegate is NSObject
     (ivar (id) coredatasession)
     (ivar-accessors)

     (- (id) applicationSupportFolder is
	(NSLog "foo")
	(set paths (NSSearchPathForDirectoriesInDomains NSApplicationSupportDirectory NSUserDomainMask YES))
	(NSLog "bar")

	(set basePath (if (paths count) (paths objectAtIndex: 0) (else (NSTemporaryDirectory))))
	(NSLog "spam")

	(basePath stringByAppendingPathComponent: "HeimatMac"))

     (- (void) applicationDidFinishLaunching: (id) sender is
	(set filemanager (NSFileManager defaultManager))
	(set appsupfo (self applicationSupportFolder))
	(set dbNeedsInit NO)
	(if (not (filemanager fileExistsAtPath: appsupfo isDirectory: nil))
	    (filemanager createDirectoryAtPath: appsupfo attributes: nil)
	    (set dbNeedsInit YES))
	
	(set @coredatasession ((NuCoreDataSession alloc)
			       initWithName: "default" 
			       mom: ((NSBundle mainBundle) pathForResource: "HeimatMac" ofType: "mom")
			       sqliteStore: (appsupfo stringByAppendingPathComponent: "data.sq")))

	(set $console ((NuConsoleWindowController alloc) init))
	(if SHOW_CONSOLE_AT_STARTUP ($console toggleConsole:self))
	(set $mainwindowcontroller ((MainWindowController alloc) init))

	(if dbNeedsInit
	    (NSLog "initializing database")
	    (set simpletype (@coredatasession createObjectWithEntity: "HMMembershipType"))
	    (simpletype setValue: "Standard Membership" forKey: "name") ;; FIXME: i18n
	    (simpletype setValue: 10 forKey: "monthlyFee")
	    
	    (set exampleMember ((@coredatasession createObjectWithEntity: "HMMembership")))
	    (exampleMember setValue: simpletype forKey: "type")))
	    
	
	

     (- (id) windowWillReturnUndoManager: (id) window is
	((@coredatasession managedObjectContext) undoManager))

     (- (int) applicationShouldTerminate: (id) sender is
	(@coredatasession save))


     (- (void) dealloc is
	(@coredatasession dealloc)
	(super dealloc)))




((NSApplication sharedApplication) setDelegate:(set $delegate ((ApplicationDelegate alloc) init)))
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)
(NSApplicationMain 0 nil)
