//
//  myBiographyTests.swift
//  myBiographyTests
//
//  Created by zhangqiao on 2025/7/16.
//

import CoreData
import Testing
@testable import myBiography

struct myBiographyTests {

    @MainActor
    @Test func testPreviewSeedData() async throws {
        let preview = PersistenceController.preview
        let context = preview.container.viewContext
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Item")
        let items = try context.fetch(fetch)
        #expect(items.count == 10)
    }

}
