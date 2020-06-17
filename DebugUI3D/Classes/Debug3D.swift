import CoreImage
import QuartzCore

struct ViewImageHolder {
    var image: UIImage
    var deep: Float
    var rect: CGRect
    var view: UIView? = nil
}

public class Debug3DManager: UIWindow {
    static public let share: Debug3DManager = Debug3DManager()
    let button = UIButton(type: .custom)
    init() {
        super.init(frame: CGRect(x: 40, y: 40, width: 40, height: 40))
        
        backgroundColor = UIColor.clear
        windowLevel = UIWindowLevelStatusBar + 100.0
        button.showsTouchWhenHighlighted = true
        button.frame = CGRect(x: 5, y: 5, width: 30, height: 30)
        button.layer.backgroundColor = UIColor.blue.cgColor
        button.layer.cornerRadius = 15
        button.layer.shadowOpacity = 0.6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didTap(gesture:)))
        button.addGestureRecognizer(panGesture)
        button.addTarget(Debug3DView.share, action: #selector(Debug3DView.share.showWidnow), for: .touchUpInside)
        addSubview(button)
    }
    var oleFrame: CGRect = CGRect.zero
    @objc
    func didTap(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            oleFrame = self.frame
        }
        let change = gesture.translation(in: self)
        var newFrame = oleFrame
        newFrame.origin.x += change.x
        newFrame.origin.y += change.y
        self.frame = newFrame
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class Debug3DView: UIWindow {
    lazy var manager: Debug3DManager = {
       return Debug3DManager.share
    }()
    static public let share: Debug3DView = Debug3DView()
    
    var isAnimatimg: Bool = false
    var holders: [ViewImageHolder] = []
    
    var rotateX: Float = 0
    var rotateY: Float = 0
    var dist: Float = 0
    
    private var oldPan: CGPoint = .zero
    private var oldDist: Float = .zero
    init() {
        super.init(frame: .infinite)
        
        backgroundColor = UIColor.clear
        frame = UIScreen.main.bounds
        windowLevel = UIWindowLevelStatusBar + 99.0
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didTap(panGesture:)))
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didDrag(dragGesture:)))
        addGestureRecognizer(panGesture)
        addGestureRecognizer(pinchGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public
extension Debug3DView {
    static func show() {
        DebugUI3D.Debug3DView.share.isHidden = true
        DebugUI3D.Debug3DManager.share.isHidden = false
    }
    
    static func dismiss() {
        
    }
    
    @objc
    func showWidnow() {
        if isAnimatimg {
            return
        }
        
        if isHidden {
            isHidden = false
            frame = UIScreen.main.bounds
            startShow()
            UIView.animate(withDuration: 0.4) {
                self.backgroundColor = UIColor.gray
            }
        } else {
            startHide()
            UIView.animate(withDuration: 0.4) {
                self.backgroundColor = UIColor.clear
            }
        }
    }
}

extension Debug3DView {
    @objc
    func didTap(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            oldPan = CGPoint.init(x: Double(rotateX), y: Double(-rotateY))
        }
        let change = panGesture.translation(in: self)
        rotateY = Float(oldPan.x + change.x)
        rotateX = Float(-oldPan.y - change.y)
        anime(time: 0.1)
    }
    
    @objc
    func didDrag(dragGesture: UIPinchGestureRecognizer) {
        if dragGesture.state == .began {
            oldDist = dist
        }
        dist = oldDist + Float((dragGesture.scale - CGFloat(1)))
        dist = dist < -5 ? -5 : dist > 0.5 ? 0.5 : dist
        anime(time: 0.1)
    }
}

extension Debug3DView {
    func startShow() {
        subviews.forEach({
            $0.removeFromSuperview()
        })
        
        holders.removeAll()
        
        rotateX = 0
        rotateY = 0
        
        UIApplication.shared.windows.enumerated().forEach({
            if $0.element == Debug3DManager.share {
                return
            }
            dumpView(view: $0.element, deep: Float($0.offset) * 5.0, originDelta: .zero, holders: &holders)
        })
        
        holders.enumerated().forEach({
            let imgV = UIImageView(image: $0.element.image)
            imgV.frame = $0.element.rect
            addSubview(imgV)
            var tValue = $0.element
            tValue.view = imgV
            holders[$0.offset] = tValue
            let r = imgV.frame
            let scr = UIScreen.main.bounds
            imgV.layer.anchorPoint = CGPoint(x: (scr.size.width/2-imgV.frame.origin.x)/imgV.frame.size.width,
                                             y: (scr.size.height/2-imgV.frame.origin.y)/imgV.frame.size.height)
            imgV.layer.anchorPointZ = CGFloat((-$0.element.deep + 3) * 50)
            imgV.frame = r
            imgV.layer.opacity = 0.9
            imgV.layer.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        })
        anime(time: 0.3)
    }
    
    func startHide() {
        isAnimatimg = true
        UIView.animate(withDuration: 0.3, animations: {
            self.holders.forEach({
                $0.view?.layer.transform = CATransform3DIdentity
            })
        }) { (on) in
            UIView.animate(withDuration: 0.3, animations: {
                self.isHidden = true
            }) { (on) in
                self.holders.forEach({
                    $0.view?.removeFromSuperview()
                })
                self.holders.removeAll()
                self.isAnimatimg = false
            }
        }
    }
    
    func dumpSubViews(_ view: UIView) -> [UIView] {
        if view.subviews.count == 0 {
            return []
        }
        var res: [UIView] = [view]
        view.subviews.forEach({
            res += dumpSubViews($0)
        })
        return res
    }
    
    func dumpView(view: UIView, deep: Float, originDelta: CGPoint, holders: inout [ViewImageHolder]) {
        var notHiddens: [UIView] = []
        view.subviews.forEach({
//            print($0)
            if (!$0.isHidden) {
                notHiddens.append($0)
                $0.isHidden = true
            }
        })
        notHiddens.forEach({
            $0.isHidden = false
        })
        if let image = renderImage(view: view),
            let holderImage = renderImageForAntialiasing(image: image) {
            var rect = holderFrame(delta: originDelta)
            rect.origin.x -= 1
            rect.origin.y -= 1
            rect.size.width += 2
            rect.size.height += 2
            let holder = ViewImageHolder(image: holderImage,
                                         deep: deep,
                                         rect: rect)
            holders.append(holder)
        }
        
        let subDelta = view.holderFrame(delta: originDelta).origin
        view.subviews.enumerated().forEach({
            print($0.element)
            dumpView(view: $0.element, deep: deep + 1 + Float($0.offset) / 10.0, originDelta: subDelta, holders: &holders)
        })
    }
    
    func anime(time: Float) {
        var trans = CATransform3DIdentity
        var t = CATransform3DIdentity
        t.m34 = -0.001
        trans = CATransform3DMakeTranslation(0, 0, CGFloat(dist * 1000))
        trans = CATransform3DConcat(CATransform3DMakeRotation(CGFloat(rotateX.to_radians()), 1, 0, 0), trans)
        trans = CATransform3DConcat(CATransform3DMakeRotation(CGFloat(rotateY.to_radians()), 0, 1, 0), trans)
        trans = CATransform3DConcat(CATransform3DMakeRotation(CGFloat(0), 0, 0, 1), trans)
        trans = CATransform3DConcat(trans, t)
        isAnimatimg = true
        
        UIView.animate(withDuration: TimeInterval(time), animations: {
            self.holders.forEach({
                $0.view?.layer.transform = trans
            })
        }) { (on) in
            self.isAnimatimg = false
        }
    }
}

// Image processing tool
extension Debug3DView {
    func renderImage(view: UIView) -> UIImage? {
        renderImage(view: view, frame: view.bounds)
    }
    
    func renderImage(view: UIView, frame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.translateBy(x: -frame.origin.x, y: -frame.origin.y)
        view.layer.render(in: context)
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return renderedImage
    }
    
    func renderImageForAntialiasing(image: UIImage) -> UIImage? {
        renderImageForAntialiasing(image: image, insets: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1))
    }
    
    func renderImageForAntialiasing(image: UIImage, insets: UIEdgeInsets) -> UIImage? {
        let imageSizeWithBorder = CGSize(width: image.size.width + insets.left + insets.right,
                                         height: image.size.height + insets.top + insets.bottom)
        UIGraphicsBeginImageContextWithOptions(imageSizeWithBorder,
                                               UIEdgeInsetsEqualToEdgeInsets(insets, .zero), 0)
        image.draw(in: CGRect.init(origin: CGPoint.init(x: insets.left, y: insets.top), size: image.size))
        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return renderedImage
        
    }
}

extension UIView {
    func holderFrame() -> CGRect {
        return CGRect(x: center.x - bounds.size.width/2,
                      y: center.x - bounds.size.height/2,
                      width: bounds.width,
                      height: bounds.height)
    }
    func holderFrame(delta: CGPoint) -> CGRect {
        return CGRect(x: center.x - bounds.size.width/2 + delta.x,
                      y: center.x - bounds.size.height/2 + delta.y,
                      width: bounds.width,
                      height: bounds.height)
    }
}

extension Float {
    func to_radians() -> Float {
        return self * .pi / 180
    }
}
