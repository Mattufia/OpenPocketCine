import Foundation
import OpenPocketViewCore
import XCTest
import os

@testable import OpenPocketCine

@MainActor
final class MediaCacheSchedulingTests: XCTestCase {
    func testCacheDeletionLeavesMainActorAvailableAndPreservesNewDownloads() async throws {
        let manager = ProbedCacheFileManager()
        defer { try? FileManager.default.removeItem(at: manager.support) }
        let cache = CameraMedia(fileManager: manager)
        let root = cache.cacheRoot(cameraID: "test")
        let file = MediaFile(path: "DCIM/DJI_001/DJI_TEST.MP4", thumbPath: "thumb.scr")
        cache.persistCatalog([file], cameraID: "test")
        cache.rememberShotColor(.dLog2, path: file.path, cameraID: "test")
        let oldDownload = root.appendingPathComponent("old.mp4")
        try Data([1]).write(to: oldDownload)
        let newDownload = root.appendingPathComponent("new.mp4")
        let wroteReplacement = expectation(
            description: "Main actor can write during recursive deletion")
        manager.beforeRemoval = {
            let heartbeat = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                do { try Data([2]).write(to: newDownload) } catch {
                    XCTFail("Replacement cache must remain writable: \(error)")
                }
                wroteReplacement.fulfill()
                heartbeat.signal()
            }
            _ = heartbeat.wait(timeout: .now() + 1)
        }
        try await cache.clearCache(cameraID: "test", preservingCatalog: true)
        await fulfillment(of: [wroteReplacement], timeout: 2)
        XCTAssertEqual(manager.removedOnMain, false)
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldDownload.path))
        XCTAssertEqual(try Data(contentsOf: newDownload), Data([2]))
        let reloaded = CameraMedia(fileManager: manager)
        XCTAssertEqual(reloaded.loadCatalog(cameraID: "test"), [file])
        XCTAssertEqual(reloaded.shotColor(for: file.path, cameraID: "test"), .dLog2)
    }

    func testDeletionCannotSweepACacheAwaitingCatalogPreservation() async throws {
        let manager = ProbedCacheFileManager()
        defer { try? FileManager.default.removeItem(at: manager.support) }
        let cache = CameraMedia(fileManager: manager)
        let root = cache.cacheRoot(cameraID: "test")
        let preparing = root.deletingLastPathComponent()
            .appendingPathComponent(".retiring-test-unfinished")
        try FileManager.default.createDirectory(at: preparing, withIntermediateDirectories: true)
        let catalog = preparing.appendingPathComponent("index.json")
        try Data([1, 2, 3]).write(to: catalog)
        let file = MediaFile(path: "old.mp4", thumbPath: "old.scr")
        try cache.writeAtomically(Data([4]), to: cache.fileCacheURL(cameraID: "test", file: file))
        try await cache.clearCache(cameraID: "test", preservingCatalog: false)
        XCTAssertEqual(try Data(contentsOf: catalog), Data([1, 2, 3]))
        let bytes = await cache.cacheByteCount(cameraID: "test")
        XCTAssertEqual(bytes, 3, "Protected data is retained and counted")
    }

    func testFailedDeletionRemainsCountedAndCanBeRetried() async throws {
        let manager = ProbedCacheFileManager()
        defer { try? FileManager.default.removeItem(at: manager.support) }
        let cache = CameraMedia(fileManager: manager)
        let file = MediaFile(path: "retry.mp4", thumbPath: "retry.scr")
        try cache.writeAtomically(
            Data([1, 2, 3]), to: cache.fileCacheURL(cameraID: "test", file: file))
        manager.beforeRemoval = { throw CocoaError(.fileWriteNoPermission) }
        do {
            try await cache.clearCache(cameraID: "test", preservingCatalog: false)
            XCTFail("The failed deletion must be reported")
        } catch {}
        let retained = await cache.cacheByteCount(cameraID: "test")
        XCTAssertEqual(retained, 3)
        manager.beforeRemoval = nil
        try await cache.clearCache(cameraID: "test", preservingCatalog: false)
        let cleared = await cache.cacheByteCount(cameraID: "test")
        XCTAssertEqual(cleared, 0)
    }

    func testCacheSnapshotReadsOffMainAndRefreshesAfterDeletion() async throws {
        let manager = ProbedCacheFileManager()
        defer { try? FileManager.default.removeItem(at: manager.support) }
        let cache = CameraMedia(fileManager: manager)
        var original = MediaFile(path: "DCIM/DJI_001/DJI_ORIGINAL.MP4", thumbPath: "original.scr")
        original.sizeBytes = 100
        let proxy = MediaFile(path: "DCIM/DJI_001/DJI_PROXY.MP4", thumbPath: "proxy.scr")
        var short = MediaFile(path: "DCIM/DJI_001/DJI_SHORT.MP4", thumbPath: "short.scr")
        short.sizeBytes = 100
        try cache.writeAtomically(
            Data(repeating: 1, count: 100), to: cache.fileCacheURL(cameraID: "test", file: original)
        )
        try cache.writeAtomically(Data([1]), to: cache.fileCacheURL(cameraID: "test", file: short))
        try cache.writeAtomically(
            Data([1]), to: cache.thumbnailCacheURL(cameraID: "test", file: short))
        let proxyPath = try XCTUnwrap(MediaHTTP.proxyPaths(proxy).first)
        try cache.writeAtomically(
            Data([1]), to: cache.playbackCacheURL(cameraID: "test", file: proxy, path: proxyPath))
        let files = [original, proxy, short]
        let snapshot = await cache.cacheEntries(cameraID: "test", files: files)
        XCTAssertEqual(manager.attributesReadOnMain, false)
        XCTAssertEqual(snapshot[original.path]?.grade, .original)
        XCTAssertEqual(snapshot[proxy.path]?.grade, .proxy)
        XCTAssertEqual(snapshot[short.path]?.grade, MediaCacheGrade.none)
        XCTAssertNotNil(snapshot[short.path]?.thumbnailURL)
        XCTAssertNil(snapshot[short.path]?.originalURL)
        let bytes = await cache.cacheByteCount(cameraID: "test")
        XCTAssertEqual(bytes, 103)
        try await cache.clearCache(cameraID: "test", preservingCatalog: false)
        let empty = await cache.cacheEntries(cameraID: "test", files: files)
        XCTAssertTrue(empty.values.allSatisfy { $0.grade == .none && $0.thumbnailURL == nil })
    }
}

private final class ProbedCacheFileManager: FileManager, @unchecked Sendable {
    let support = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let removal = OSAllocatedUnfairLock<Bool?>(initialState: nil)
    private let reads = OSAllocatedUnfairLock(initialState: false)
    var removedOnMain: Bool? { removal.withLock { $0 } }
    var attributesReadOnMain: Bool { reads.withLock { $0 } }
    // Configured before launching deletion and immutable until it completes.
    var beforeRemoval: (@Sendable () throws -> Void)?

    override func urls(for directory: SearchPathDirectory, in domainMask: SearchPathDomainMask)
        -> [URL]
    {
        [support]
    }

    override func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        reads.withLock { $0 = $0 || Thread.isMainThread }
        return try super.attributesOfItem(atPath: path)
    }

    override func removeItem(at URL: URL) throws {
        removal.withLock { $0 = Thread.isMainThread }
        try beforeRemoval?()
        try super.removeItem(at: URL)
    }
}
