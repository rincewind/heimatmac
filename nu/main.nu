;; main.nu
;;

;; HeimatMac. Easy membership management.
;; Copyright (c) 2008 Peter Quade

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

(load "bridgesupport")
(import AddressBook) ;; AddressBook framework
(load "AddressBook")

(import WebKit)
(load "WebKit")
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

(function printTable (collection createLine) 
  (set result ((NSMutableString alloc) init))
  (NSLog "printing #{(collection count)} objects")
  (result appendString: <<+END
<html>
<head>
<style type="text/css">
h1 { background-color: red; font-size: 12pt;}
table {width: 100%;}
</style>
</head>
<body>
<h1>Heimatverein Fr&ouml;mern</h1>
<h2>#{((NSDate date) description)}</h1>
<table>
<tbody>
END)
  (collection each: (do (item)
		      (result appendString: (createLine item))))
  (result appendString: <<+END
</tbody>
</table>
<small>Created with HeimatMac v0.0001</small>
</body>
</html>
END)
  result)


(((NSUserDefaults alloc) init) setInteger: 0 forKey: "com.apple.CoreData.SQLDebug")

;; Additional utilities for managed objects
(class NSManagedObject is NSObject
     ;; Create an object for a specified entity.
     (imethod (id) createObjectWithEntity:(id) entityName is
          (NSEntityDescription
                              insertNewObjectForEntityForName:entityName
                              inManagedObjectContext:(self managedObjectContext)))
     
     ;; Get all objects of receivers entity.
     (imethod (id) objects is
          (set f ((NSFetchRequest alloc) init))
          (f setEntity:(NSEntityDescription entityForName: ((self class) name) inManagedObjectContext: (self  managedObjectContext)))
          (((self managedObjectContext)) executeFetchRequest:f error:nil))
     
     (imethod (id) managedObjectModel is
          (((NSApplication sharedApplication) delegate) managedObjectModel))
     
     
     (imethod (id) namedFetchRequest:(id)name substitutionVariables:(id)vars is
          ((self managedObjectModel) fetchRequestFromTemplateWithName: name substitutionVariables: vars)))

(class HMMembershipType is NSManagedObject)

(class HMMembership is NSManagedObject
       (ivar (id) startDate (id) endDate (BOOL) isCash (id) membershiptype)
       
       (- (id) orderedPersons is
	  (((self persons) allObjects) sortedArrayUsingBlock: (do (lhs rhs) (cond
									     ((== (lhs position) (rhs position)) 0)
									     ((< (lhs position) (rhs position)) -1)
									     ((> (lhs position) (rhs position)) 1)))))

       (- (id) firstPerson is
	  (let ((orderedPersons (self orderedPersons)))
	    (if (and orderedPersons (> (orderedPersons count) 0))
		(orderedPersons objectAtIndex: 0)
		(else nil))))

       (- (id) title is 
	  (let ((ps (self persons)))
	    (if ps
		(let ((persons (ps allObjects)))
		  (case (persons count)
		    (0 "Unbekanntes Mitglied")
		    (1 (let  ((person (persons objectAtIndex: 0) ))
			 "#{(person firstname)} #{(person lastname)}"))
		    (2 
		     (set p1 (persons objectAtIndex: 0))
		     (set p2 (persons objectAtIndex: 1))
		     (if ((p1 lastname) isEqualToString: (p2 lastname))
			 "#{(p1 firstname)} und #{(p2 firstname)} #{(p1 lastname)}"))
		    (else "Familie #{((((self persons) allObjects) objectAtIndex: 0) lastname)}"))))))

       (- (id) street is 
	  (or ((self firstPerson) street) "n/a"))

       (- (id) place is
	  (or ((self firstPerson) place) "n/a"))

       (- (BOOL) isActive is
	  (let ((now (NSDate date)))
	    (if (and (eq @startDate (now earlierDate: @startDate))
		     (or (not @endDate)
			 (eq @endDate (now laterDate: @endDate))))
		YES
		(else NO))))

       

       (- (void) awakeFromInsert is
	  (super awakeFromInsert)
	  (if (not @membershiptype) 
	      (NSLog "foo")
	      (set @membershiptype ((self objectsWithEntity: "HMMembershipType") objectAtIndex: 0))))

       (- (void) awakeFromFetch is
	  (super awakeFromFetch)))


       


       


(class HMPayment is NSManagedObject)

(class HMPerson is NSManagedObject

       (- (id) primaryInMultiValue: (int) propconst is
	  (set multivalue ((self person) valueForProperty: propconst))
	  (set ident (multivalue primaryIdentifier))
	  (multivalue valueForIdentifier: ident))

       (- (id) setValue: (id) value toPrimaryInMultiValue: (int) propconst withLabel:(id) label is
	  (set multivalue ((self person) valueForProperty: propconst))
	  (if multivalue
	      (set multivalue (multivalue mutableCopy))
	      (set ident (multivalue primaryIdentifier))
	      (multivalue replaceValueAtIndex: (multivalue indexForIdentifier: ident) withValue: value)
	      (else 
		(set multivalue ((ABMutableMultiValue alloc) init))
		(multivalue setPrimaryIdentifier: (multivalue addValue: value withLabel: label))))

	  ((self person) setValue: multivalue forProperty: propconst))


       (- (id) addressElementWithKey: (id) key is
	  ((self primaryInMultiValue: kABAddressProperty) objectForKey: key))

       (- (id) setValue: (id) value toAddressElementWithKey:(id)key is
	  (set address (self primaryInMultiValue: kABAddressProperty))
	  (if address
	      (set address (address mutableCopy))
	      (else (set address (NSMutableDictionary dictionary))))
	  (address setObject: value forKey: key)
	  (self setValue: address toPrimaryInMultiValue: kABAddressProperty withLabel: kABAddressHomeLabel))
	  

       (- (id) firstname is 
	  ((self person) valueForProperty: kABFirstNameProperty))

       (- (void) setFirstname: (id) aName is
	  ((self person) setValue: aName forProperty: kABFirstNameProperty))


       (- (id) lastname is 
	  ((self person) valueForProperty: kABLastNameProperty))

       (- (void) setLastname: (id) aName is
	  ((self person) setValue: aName forProperty: kABLastNameProperty))


       (- (id) street is 
	  (self addressElementWithKey: kABAddressStreetKey))

       (- (void) setStreet: (id) newStreet is
	  (self setValue: newStreet toAddressElementWithKey: kABAddressStreetKey))


       (- (id) place is
	  (self addressElementWithKey: kABAddressCityKey))

       (- (void) setPlace: (id) newValue is
	  (self setValue: newValue toAddressElementWithKey: kABAddressCityKey))


       (- (id) postalcode is
	  (self addressElementWithKey: kABAddressZIPKey))

       (- (void) setPostalcode: (id) newValue is
	  (self setValue: newValue toAddressElementWithKey: kABAddressZIPKey))


       (- (id) birthday is 
	  ((self person) valueForProperty: kABBirthdayProperty))

       (- (void) setBirthday: (id) newValue is
	  ((self person) setValue: newValue forProperty: kABBirthdayProperty))

       (- (id) email is  
	  (self primaryInMultiValue: kABEmailProperty))

       (- (void) setEmail: (id) newValue is
	  (self setValue: newValue toPrimaryInMultiValue: kABEmailProperty withLabel: kABEmailHomeLabel))


       (- (id) person is 
	  (self willAccessValueForKey: "person")
	  (set person (self primitivePerson))
	  (self didAccessValueForKey: "person")
	  (if (person) person
	      (else (self loadPersonWithUUID: (self uuid)))))
	      

       (- (void) awakeFromInsert is
	  (super awakeFromInsert)
	  (self createPerson)
	  (NSLog "#{(self membership)}"))
	  
       (- (void) awakeFromFetch is
	  (super awakeFromFetch)
	  (set uuid (self uuid))
	  (if uuid
	      (self loadPersonWithUUID: uuid)
	      (else (self createPerson))))

       (- (void) createPerson is
	  (let ((person ((ABPerson alloc) initWithAddressBook: (ABAddressBook sharedAddressBook))))
	    (self setValue: (person uniqueId) forKey: "uuid")
	    (self setPrimitivePerson: person)
	    (self setValue: 0 forKey: "position")))
	  

       (- (void) loadPersonWithUUID:(id)uuid is
	  (self setPrimitivePerson: ((ABAddressBook sharedAddressBook) recordForUniqueId: uuid))))



(class HMNote is NSManagedObject)

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


(class HMReportDesign is NSManagedObject)

(class HMMemberList is NSManagedObject)
(class HMStaticMemberList is HMMemberList)
(class HMSmartMemberList is HMMemberList)


(class HMMainWindowController is NSWindowController
     (ivar (id) sourcelist (id) sourceListEntries
	   (id) memberview (id) memberlist 
	   (id) membersctl (id) personsctl
	   (id) sheetcontroller)
     
     (- (void) addPerson: (id) sender is
	(let ((count ((@personsctl arrangedObjects) count))
	      (member ((@membersctl selectedObjects) objectAtIndex: 0)))
	  (if (> count 0)
	      (set newposition (+ count 1))
	      (set person (HMPerson createObject))
	      (set otherPerson (member firstPerson))

	      (person setPosition: newposition)
	      (person setLastname: (otherPerson lastname))
	      (person setStreet: (otherPerson street))
	      (person setPlace: (otherPerson place))
	      (person setPostalcode: (otherPerson postalcode))
	      (person setEmail: (otherPerson email))
	      ((member persons) addObject: person)
	      (person setMembership: member)
	      (else (@personsctl add: sender)))))
	    

     (- (void) printMembers: (id) sender is
	(set printview ((WebView alloc) initWithFrame: '(0 0 1000 1000)))
	((printview mainFrame) loadHTMLString: (printTable (@membersctl arrangedObjects) 
							   (do (item) "<tr><td>#{(item title)}</td><td>#{(item street)}</td><td>#{(item place)}</td></tr>") )
	 baseURL: (NSURL URLWithString: "http://www.pqua.de/"))

	(set printinfo (NSPrintInfo sharedPrintInfo))
	(printinfo  setVerticallyCentered: NO)
	(printinfo setHorizontalPagination: NSFitPagination)
	((NSPrintOperation printOperationWithView:printview printInfo:printinfo) runOperation))

     (- init is
	(set self (self initWithWindowNibName:"MainWindow"))
	((self window) makeKeyAndOrderFront:self)

	(set @sourceListEntries 
	     (NSArray arrayWithList: (list 
				      (SourceListItem groupWithTitle: "BANANEN" subitems: 
						      (array 
						       (SourceListItem itemWithTitle: "Gelb" subitems: (array)) 
						       (SourceListItem itemWithTitle: "Krumm" subitems: (array)))) 
				      (SourceListItem groupWithTitle: "KIRSCHEN" subitems: 
						      (array (SourceListItem itemWithTitle: "Suess" subitems: (array)))))))
     

        self)

     (- (void) initAddressbook is
	(NSLog "show: #{((NSUserDefaults standardUserDefaults) integerForKey: $UseAddressbookGroup)}")
	(set showsheet 
	     (case ((NSUserDefaults standardUserDefaults) integerForKey: $UseAddressbookGroup)
	       (1 (progn
		    (set ab (ABAddressBook sharedAddressBook))
		    (set group  ((NSUserDefaults standardUserDefaults) stringForKey: $AddressbookGroupName))
		    (set searchelement (ABGroup searchElementForProperty: kABGroupNameProperty 
						label: nil 
						key: nil 
						value: group 
						comparison: kABEqual))
		    (set groups (ab recordsMatchingSearchElement: searchelement))
		    (not (groups count))))
	       ($UseAddressbookGroupMarker t)
	       (else nil)))
	     
	(if showsheet
	    (if (not @sheetcontroller)
		(set @sheetcontroller ((HMGruppeSheetController alloc) init)))
	    (@sheetcontroller beginSheet: (self window))))


	 

     (- (BOOL) outlineView: (id) sender isGroupItem: (id) item is
	((item representedObject) isGroup))

    ;; (- (void) outlineView: (id) sender willDisplayCell:(id)cell forTableColumn:(id)tableColumn item:(id)item is)

     
     (- (BOOL)outlineView:(id)outlineView shouldSelectItem:(id)item is

	;; don't allow special group nodes to be selected
	(if ((item representedObject) isGroup) NO (else YES)))

     (- (void) windowDidBecomeMain:(id) notification is
	(self initAddressbook))


;;     (- (void) awakeFromNib is
	;;(super awakeFromNib)
	;;(set col (@sourcelist tableColumnWithIdentifier: @"MainColumn"))
	;;(set $cell ((TextImageCell alloc) init)) ;; we need to keep the cell around somewhere
	;;(col setDataCell: $cell)
;;	)
     )

(set $AddressbookGroupName "addressbookgroupName")
(set $UseAddressbookGroup "useAddressbookGroup")
(set $UseAddressbookGroupMarker 12)

(class HMGruppeSheetController is NSObject
       (ivar (id) sheet (id) defaultsController)

       (- (void) closeSheet: (id) sender is 
	  (NSLog "closing sheet")
	  (NSApp endSheet: @sheet))
	  
       (- (id) addressbookGroups is
	  (array "foo" "bar")
	  )

       (- (BOOL) willAddGroup is
	  YES)

       (- (id) init is
	  (set self (super init))
	  (NSBundle loadNibNamed: "AddressbookGroup" owner: self)
	  (NSLog "#{@defaultsController}")
	  self)

       (- (void) beginSheet: (id) sender is 
	  (NSLog "#{@sheet} #{sender}")
	  (NSApp beginSheet: @sheet
		 modalForWindow: sender
		 modalDelegate: self 
		 didEndSelector: "didEndSheet:returnCode:contextInfo:"
		 contextInfo: nil))
	  

       (- (void)didEndSheet:(id)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo is
	  (@sheet orderOut: self)))
	  

       

(class ApplicationDelegate is NSObject
     (ivar (id) coredatasession)
     (ivar-accessors)

     (- (id) applicationSupportFolder is
	(set paths (NSSearchPathForDirectoriesInDomains NSApplicationSupportDirectory NSUserDomainMask YES))
	(set basePath (if (paths count) (paths objectAtIndex: 0) (else (NSTemporaryDirectory))))
	(basePath stringByAppendingPathComponent: "HeimatMac"))

     (- (id) managedObjectModel is (@coredatasession managedObjectModel))
     (- (id) managedObjectContext is (@coredatasession managedObjectContext))

     (- (void) initDefaults is
	(set ud (NSUserDefaults standardUserDefaults))
	(ud registerDefaults: (dict $AddressbookGroupName "Heimat" $UseAddressbookGroup $UseAddressbookGroupMarker)))
	
	

     (- (void) initDatabase is
	(NSLog "initializing database")
	(set simpletype (@coredatasession createObjectWithEntity: "HMMembershipType"))
	(simpletype setValue: "Standard Mitgliedschaft" forKey: "name") ;; i18n
	(simpletype setValue: 10 forKey: "monthlyFee")
	(@coredatasession save))



	

     (- (void) applicationDidFinishLaunching: (id) sender is
	(self initDefaults)

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


	;;(set $console ((NuConsoleWindowController alloc) init))
	;;(if SHOW_CONSOLE_AT_STARTUP ($console toggleConsole:self))

	(set $mainwindowcontroller ((HMMainWindowController alloc) init))


	(if dbNeedsInit
	    (self initDatabase)))
	    
	
	

     (- (id) windowWillReturnUndoManager: (id) window is
	((@coredatasession managedObjectContext) undoManager))

     (- (int) applicationShouldTerminate: (id) sender is
	((ABAddressBook sharedAddressBook) save)
	(@coredatasession save))


     (- (void) dealloc is
	(@coredatasession dealloc)
	(super dealloc)))




((NSApplication sharedApplication) setDelegate:(set $delegate ((ApplicationDelegate alloc) init)))
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)
(NSApplicationMain 0 nil)
