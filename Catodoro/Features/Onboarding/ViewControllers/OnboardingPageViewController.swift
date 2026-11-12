//
//  OnboardingPageViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Holds the onboarding steps side by side, like a paged `TabView`, with
/// page dots underneath. Steps slide in as each one finishes.
///
/// Swiping between pages is off: each step needs an answer before the next,
/// so only `showPage(at:)` moves forward.
final class OnboardingPageViewController: BaseViewController {
    private let pages: [UIViewController]
    private let pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                          navigationOrientation: .horizontal)
    private let pageControl = UIPageControl()
    private(set) var currentIndex = 0

    init(pages: [UIViewController]) {
        precondition(!pages.isEmpty, AppStrings.Diagnostics.onboardingNeedsSteps)
        self.pages = pages
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func constructView() {
        super.constructView()
        // No dataSource → no swipe gesture.
        pageViewController.setViewControllers([pages[currentIndex]], direction: .forward, animated: false)

        pageControl.numberOfPages = pages.count
        pageControl.currentPage = currentIndex
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPageIndicatorTintColor = CatTheme.accent(.neonBlue)
        pageControl.pageIndicatorTintColor = CatTheme.separator
    }

    override func constructSubviews() {
        super.constructSubviews()
        addChild(pageViewController)
        view.addAutolayoutSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        view.addAutolayoutSubview(pageControl)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.space8)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    /// Slides to the step at `index`. Out-of-range indexes and the current page are ignored.
    func showPage(at index: Int, animated: Bool = true) {
        guard pages.indices.contains(index), index != currentIndex else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        currentIndex = index
        pageControl.currentPage = index
        pageViewController.setViewControllers([pages[index]], direction: direction, animated: animated)
        UIAccessibility.post(notification: .screenChanged, argument: pages[index].view)
    }
}

#if DEBUG
extension OnboardingPageViewController {
    var testHooks: TestHooks { .init(target: self) }

    struct TestHooks {
        let target: OnboardingPageViewController

        var pages: [UIViewController] { target.pages }
        var visiblePage: UIViewController? { target.pageViewController.viewControllers?.first }
        var pageControl: UIPageControl { target.pageControl }
        var hasSwipeDataSource: Bool { target.pageViewController.dataSource != nil }
    }
}
#endif
