import XCTest
@testable import Journal
import CoreData

class FileTests: XCTestCase {

    override func setUp() {
        super.setUp()
        PersistenceController.preview.addInitialSubstances()
    }

    override func tearDown() {
        PersistenceController.preview.deleteAllSubstances()
        super.tearDown()
    }

    func testHasOneFile() throws {
        let fetchRequest = SubstancesFile.fetchRequest()
        let files = try PersistenceController.preview.viewContext.fetch(fetchRequest)
        XCTAssertEqual(files.count, 1)
    }

}
