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
       
       (- (id) title is "No Title")
       (- (id) street is "The Street")
       (- (id) place is "12345 the place")

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
	      (set @membershiptype ((self objectsWithEntity: "HMMembershipType") objectAtIndex: 0)))))

       


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
	  (self createPerson))
	  
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


(class MainWindowController is NSWindowController
     (ivar (id) sourcelist (id) sourceListEntries (id) memberview (id) memberlist)

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

     (- (id) managedObjectModel is (@coredatasession managedObjectModel))
     (- (id) managedObjectContext is (@coredatasession managedObjectContext))

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
	    (simpletype setValue: "Standard Membership" forKey: "name") ;; i18n
	    (simpletype setValue: 10 forKey: "monthlyFee")
	    
	    (@coredatasession save)))
	    
	
	

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
