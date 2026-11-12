//
//  OnboardingPageViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

@MainActor
final class OnboardingPageViewControllerTests: XCTestCase {
    private func makePages(_ count: Int = 2) -> (OnboardingPageViewController, [UIViewController]) {
        let pages = (0..<count).map { _ in UIViewController() }
        let controller = OnboardingPageViewController(pages: pages)
        controller.loadViewIfNeeded()
        return (controller, pages)
    }

    func test_load_expectFirstPageAndDots() {
        let (controller, pages) = makePages(3)

        XCTAssertEqual(controller.currentIndex, 0)
        XCTAssertTrue(controller.testHooks.visiblePage === pages[0])
        XCTAssertEqual(controller.testHooks.pageControl.numberOfPages, 3)
        XCTAssertEqual(controller.testHooks.pageControl.currentPage, 0)
    }

    func test_swiping_expectDisabled() {
        let (controller, _) = makePages()

        XCTAssertFalse(controller.testHooks.hasSwipeDataSource)
        XCTAssertFalse(controller.testHooks.pageControl.isUserInteractionEnabled)
    }

    func test_showPage_expectPageAndDotsMove() {
        let (controller, pages) = makePages()

        controller.showPage(at: 1, animated: false)

        XCTAssertEqual(controller.currentIndex, 1)
        XCTAssertTrue(controller.testHooks.visiblePage === pages[1])
        XCTAssertEqual(controller.testHooks.pageControl.currentPage, 1)
    }

    func test_showPage_outOfRange_expectIgnored() {
        let (controller, pages) = makePages()

        controller.showPage(at: 5, animated: false)
        controller.showPage(at: -1, animated: false)

        XCTAssertEqual(controller.currentIndex, 0)
        XCTAssertTrue(controller.testHooks.visiblePage === pages[0])
    }

    func test_singlePage_expectDotsHidden() {
        let (controller, _) = makePages(1)

        XCTAssertTrue(controller.testHooks.pageControl.hidesForSinglePage)
    }

    func test_pagesAreChildrenOfContainer() {
        let (controller, pages) = makePages()

        XCTAssertTrue(pages[0].parent is UIPageViewController)
        XCTAssertTrue(pages[0].parent?.parent === controller)
    }
}
