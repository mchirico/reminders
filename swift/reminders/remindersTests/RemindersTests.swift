import XCTest
import EventKit
@testable import Reminders

// ref: https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations/testing_asynchronous_operations_with_expectations

class MocEKEventStore: EKEventStore {
  var error: Error?
  var reminders = [EKReminder]()
  var events = [EKEvent]()
  var pred = NSPredicate()
  var accessRequested = false
  var countDefaultCalendarForNewReminders = 0
  open override func requestAccess(to entityType: EKEntityType,
                                   completion: @escaping
    EKEventStoreRequestAccessCompletionHandler) {
    self.accessRequested = true
    completion( true, error)
  }
  open override func save(_ reminder: EKReminder, commit: Bool) throws {
    print("SAVE: \(reminder)")
    reminders.append(reminder)
  }
  open override func save(_ event: EKEvent, span: EKSpan, commit: Bool) throws {
    events.append(event)
  }
  open override func fetchReminders(matching predicate: NSPredicate,
                                    completion:
    @escaping ([EKReminder]?) -> Void) -> Any {
    completion(reminders)
    return "return"
  }
  open override func defaultCalendarForNewReminders() -> EKCalendar? {
    self.countDefaultCalendarForNewReminders += 1
    return super.defaultCalendarForNewReminders()
  }
  open override func predicateForReminders(in calendars: [EKCalendar]?) -> NSPredicate {
    return pred
  }
  open override func remove(_ reminder: EKReminder, commit: Bool) throws {
    reminders = reminders.filter {$0.title != reminder.title}
  }
  
  open override func remove(_ event: EKEvent, span: EKSpan) throws {
    events = events.filter {$0.title != event.title}
  }
  
  open override func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate {
    return pred
  }
  
  open override func events(matching predicate: NSPredicate) -> [EKEvent] {
    return events
  }
}

class ReminderLibTests: XCTestCase {
  let rLib = Reminder(eventStore: MocEKEventStore())
  //let rLib = Reminder() // Uncomment for live testing
  let testTitle = "Bozo Entry"
  override func setUp() {
    let expectation = self.expectation(description: "Add Cal Event")
    let dateString0 = "2018-11-5 9:56:25pm"
    let dateString1 = "2018-11-5 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    rLib.addCalEvent(title: self.testTitle,
                     notes: "Notes on Bozo",
                     startDate: startDate!,
                     endDate: endDate!) { (handler) in
                      print(handler)
                      print("\n\n............****\n\n")
                      XCTAssert(handler.status == "Saved Event", "Event not saved")
                      expectation.fulfill()
    }
    waitForExpectations(timeout: 5, handler: nil)
  }
  override func tearDown() {
    let expectation = self.expectation(description: "Get Events")
    let dateString0 = "2018-11-3 9:56:25pm"
    let dateString1 = "2018-11-14 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    rLib.removeEvent(title: self.testTitle,
                     startDate: startDate!,
                     endDate: endDate!) { handler in
                      print("\(String(describing: handler))")
                      expectation.fulfill()
    }
    waitForExpectations(timeout: 5, handler: nil)
  }
  // Take out, but neat example
  // Ref: https://www.swiftbysundell.com/posts/mocking-in-swift
  //      https://www.swiftbysundell.com/posts/refactoring-swift-code-for-testability
  func testCalculatingFinalPriceWithCoupon() {
    let products = [
      Product(name: "A", cost: 30),
      Product(name: "B", cost: 80)
    ]
    let coupon = Coupon(
      code: "swiftbysundell",
      discountPercentage: 30
    )
    let price = PriceCalculator.calculateFinalPrice(
      for: products,
      applying: coupon
    )
    XCTAssertEqual(price, 77)
  }

  func testCalculatingFinalPriceWithoutCoupon() {
    let products = [
      Product(name: "A", cost: 30),
      Product(name: "B", cost: 80)
    ]
    let price = PriceCalculator.calculateFinalPrice(
      for: products,
      applying: nil
    )
    // We hard code the expected value here, rather than dynamically
    // calculating it. That way we can avoid calculation mistakes
    // and be more confident in our tests.
    XCTAssertEqual(price, 110)
  }
  
  func testMoc() {
    let mocEKEventStore = MocEKEventStore()
    let rLib = Reminder(eventStore: mocEKEventStore)
    let expectationAddR = self.expectation(description: "add reminder")
    rLib.addReminderHack(title: "junk",
                         notes: "Notes",
                         priority: 3,
                         alarmTime: Date()) { (rfc) in
      XCTAssert(rfc.granted == "granted true")
      print("status: \(String(describing: rfc.status))")
      expectationAddR.fulfill()
    }
    print("moc: \(mocEKEventStore.reminders[0].calendarItemIdentifier)")
    wait(for: [expectationAddR], timeout: 3.0)
    XCTAssert(mocEKEventStore.events.count == 0)
    XCTAssert(mocEKEventStore.reminders.count == 1)

    let expectation = self.expectation(description: "remove no match")
    rLib.removeReminders(title: "WAT",
                         startDate: Date(),
                         endDate: Date()) { (rfc) in
      print("rfc in test: \(rfc)")
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 3.0)
    // Reminder should not be found
    XCTAssert(mocEKEventStore.events.count == 0)
    XCTAssert(mocEKEventStore.reminders.count == 1)

    let expectation2 = self.expectation(description: "remove match")
    rLib.removeReminders(title: "junk",
                         startDate: Date(),
                         endDate: Date()) { (rfc) in
      print("rfc in test: \(rfc)")
      expectation2.fulfill()
    }
    wait(for: [expectation2], timeout: 3.0)
    // Reminder should be removed
    XCTAssert(mocEKEventStore.events.count == 0)
    XCTAssert(mocEKEventStore.reminders.count == 0)
  
    let expectation3 = self.expectation(description: "add cal event")
    rLib.addCalEvent(title: "Cal0",
                     notes: "Notes for Cal",
                     startDate: Date(),
                     endDate: Date()) { (_) in
      expectation3.fulfill()
    }
    wait(for: [expectation3], timeout: 4.0)
    XCTAssert(mocEKEventStore.events.count == 1)
    XCTAssert(mocEKEventStore.reminders.count == 0)
    let expectation4 = self.expectation(description: "remove cal event")
    rLib.removeEvent(title: "Cal0",
                     startDate: Date(),
                     endDate: Date()) { (_) in
      expectation4.fulfill()
    }
    wait(for: [expectation4], timeout: 4.0)
    XCTAssert(mocEKEventStore.events.count == 0)
    XCTAssert(mocEKEventStore.reminders.count == 0)
  }

  func prEvents(rfc: Reminder.ResultFromCall) {
    print("....\n\n")
    var foundDaylightSavingsEntry = false
    if let events = rfc.event {
      print("\n\n")
      for index in events {
        print("title: \(String(describing: index.title!))")
        print("date: \(String(describing: index.startDate!))")

        if index.title!.range(of: "Daylight Saving Time End") != nil {
          foundDaylightSavingsEntry = true
        }
      }
      XCTAssert(foundDaylightSavingsEntry == true, "Can't find end Daylight Saving Time End")
      return

    }
    print("NO GOOD....\n\n")
    XCTFail("No good")

  }

  func testFunctions() {

    let expectation = self.expectation(description: "Add reminder")
    var alarmTime = Date().addingTimeInterval(1*60*24*3)

    rLib.addReminder(title: "Bozo call home", notes: "Notes for Bozo",
                     priority: 1, alarmTime: alarmTime) { (rfc) in
                      XCTAssert(rfc.status == "Reminder saved",
                                "Reminder not saved")
                      expectation.fulfill()

    }

    wait(for: [expectation], timeout: 3.0)

    // Now get our reminder
    let startDate = Date().addingTimeInterval(60*24*2)
    let endDate = Date().addingTimeInterval(1*60*24*4)
    let expectation2 = self.expectation(description: "Query reminders")

    rLib.getReminders(startDate: startDate,
                      endDate: endDate) { (rfc) in
      var correctTitle = false
      for index in rfc.reminder! {
        if let title = index.title {
          if title == "Bozo call home" {
            correctTitle = true
          }
        }
        XCTAssert(correctTitle, "Couldn't find reminder")
      }
      expectation2.fulfill()
    }
    wait(for: [expectation2], timeout: 3.0)

    // Now update it
    let expectation3 = self.expectation(description: "Update reminder")
    alarmTime = Date().addingTimeInterval(1*60*24*5)
    rLib.updateReminders(title: "Bozo call home",
                         newTitle: "Bozo call dog",
                         newNotes: "new Notes",
                         newPriority: 3, newAlarmTime: alarmTime,
                         startDate: startDate,
                         endDate: endDate) { (_) in
      expectation3.fulfill()

    }
    wait(for: [expectation3], timeout: 3.0)
    
    // Delete
    let expectation4 = self.expectation(description: "Remove reminders")
    
    rLib.removeReminders(title: "Bozo call dog",
                         startDate: startDate,
                         endDate: endDate) { (rfc) in
      var correctTitle = false
      var modifiedTitle = true
      for index in rfc.reminder! {
        if let title = index.title {
          if title == "Bozo call dog" {
            correctTitle = true
          }
          if title == "Bozo call home" {
            modifiedTitle = false
          }
        }
        XCTAssert(correctTitle, "reminder didn't get delete")
        XCTAssert(modifiedTitle, "reminder didn't get modified")
      }
      expectation4.fulfill()
    }
    wait(for: [expectation4], timeout: 3.0)
  }

  func testRemoveEvent() {
    
    let expectation = self.expectation(description: "Get Events")
    
    let dateString0 = "2018-11-3 9:56:25pm"
    let dateString1 = "2018-11-4 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    rLib.removeEvent(title: "Test123-reminderLib",
                     startDate: startDate!,
                     endDate: endDate!) { handler in
                      print("\(String(describing: handler))")
                      expectation.fulfill()
                      
    }
    waitForExpectations(timeout: 5, handler: nil)
  }
  
  func testAddCalEvent() {
    
    let expectation = self.expectation(description: "Add Cal Event")
    
    let dateString0 = "2018-11-5 9:56:25pm"
    let dateString1 = "2018-11-5 11:21:25pm"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ssa" //Input Format
    dateFormatter.timeZone = TimeZone.current
    let startDate = dateFormatter.date(from: dateString0)
    let endDate = dateFormatter.date(from: dateString1)
    
    rLib.addCalEvent(title: self.testTitle,
                     notes: "Notes on Bozo",
                     startDate: startDate!,
                     endDate: endDate!) { (handler) in
                      print(handler)
                      XCTAssert(handler.status == "Saved Event", "Event not saved")
                      expectation.fulfill()
    }
    waitForExpectations(timeout: 5, handler: nil)
    
  }
  
  func testGetSumMulOf() {
    let expectation = self.expectation(description: "Sum up values")
    getSumMulOf(array: [16, 756, 442, 6, 23]) { (result) in
      print(result)
      XCTAssert(result[0] == 1243, "Sum should equal 1243")
      XCTAssert(result[1] == 737807616, "Sum should equal 737807616")
      expectation.fulfill()
      return result[0]+result[1]
    }
    waitForExpectations(timeout: 3, handler: nil)
  }
  
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
