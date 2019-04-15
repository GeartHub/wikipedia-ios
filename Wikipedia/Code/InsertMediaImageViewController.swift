import UIKit
import SafariServices

protocol InsertMediaImageViewControllerDelegate: AnyObject {
    func insertMediaImageViewController(_ insertMediaImageViewController: InsertMediaImageViewController, didSetSelectedImage image: UIImage?, from searchResult: InsertMediaSearchResult)
}

final class InsertMediaImageViewController: UIViewController {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private let emptyView = InsertMediaImageEmptyView.wmf_viewFromClassNib()!
    private let selectedImageView = InsertMediaSelectedImageView.wmf_viewFromClassNib()!

    weak var delegate: InsertMediaImageViewControllerDelegate?

    private var theme = Theme.standard

    static func fromNib() -> InsertMediaImageViewController {
        return InsertMediaImageViewController(nibName: "InsertMediaImageViewController", bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.wmf_addSubviewWithConstraintsToEdges(emptyView)
    }

    @objc private func startActivityIndicator() {
        cancelPreviousActivityIndicatorSelectors()
        contentView.isHidden = true
        activityIndicatorView.startAnimating()
    }

    @objc private func stopActivityIndicator() {
        cancelPreviousActivityIndicatorSelectors()
        contentView.isHidden = false
        activityIndicatorView.stopAnimating()
    }

    @objc private func cancelPreviousActivityIndicatorSelectors() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startActivityIndicator), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(stopActivityIndicator), object: nil)
    }
}

extension InsertMediaImageViewController: InsertMediaSearchResultsCollectionViewControllerDelegate {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult) {
        perform(#selector(startActivityIndicator), with: nil, afterDelay: 0.3)
        let imageURLWithNewSize = URL(string: WMFChangeImageSourceURLSizePrefix(searchResult.thumbnailURL.absoluteString, Int(view.bounds.width)))
        guard let imageURL = imageURLWithNewSize ?? searchResult.imageInfo?.canonicalFileURL else {
            stopActivityIndicator()
            return
        }
        selectedImageView.configure(with: imageURL, imageInfo: searchResult.imageInfo, theme: theme) { error in
            guard error == nil else {
                self.stopActivityIndicator()
                return
            }
            self.stopActivityIndicator()
            if self.selectedImageView.superview == nil {
                self.emptyView.removeFromSuperview()
                self.selectedImageView.moreInformationAction = { url in
                    self.present(SFSafariViewController(url: url), animated: true)
                }
                self.contentView.wmf_addSubviewWithConstraintsToEdges(self.selectedImageView)
            }
            self.delegate?.insertMediaImageViewController(self, didSetSelectedImage: self.selectedImageView.image, from: searchResult)
        }
    }
}

extension InsertMediaImageViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        contentView.backgroundColor = theme.colors.baseBackground
        emptyView.apply(theme: theme)
        selectedImageView.apply(theme: theme)
        activityIndicatorView.style = theme.isDark ? .white : .gray
    }
}
