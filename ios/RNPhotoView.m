#import "RNPhotoView.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTImageSource.h>
#import <React/RCTUtils.h>
#import <React/UIView+React.h>
#import <React/RCTImageLoader.h>

@interface RNPhotoView()

#pragma mark - View

@property (nonatomic, strong) MWTapDetectingImageView *photoImageView;
@property (nonatomic, strong) MWTapDetectingView *tapView;
@property (nonatomic, strong) UIImageView *loadingImageView;

#pragma mark - Data

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *loadingImage;

@end

@implementation RNPhotoView
{
    __weak RCTBridge *_bridge;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
    if ((self = [super init])) {
        _bridge = bridge;
        [self initView];
    }
    return self;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleDoubleTap:(CGPoint)touchPoint {
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

#pragma mark - MWTapDetectingImageViewDelegate

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:imageView].x;
    CGFloat touchY = [touch locationInView:imageView].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;

    if (_onPhotoViewerTap) {
        _onPhotoViewerTap(@{
                            @"point": @{
                                    @"x": @(touchX),
                                    @"y": @(touchY),
                                    },
                            @"target": self.reactTag
                            });
    }
}

- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

#pragma mark - MWTapDetectingViewDelegate

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;

    if (_onPhotoViewerViewTap) {
        _onPhotoViewerViewTap(@{
                                @"point": @{
                                        @"x": @(touchX),
                                        @"y": @(touchY),
                                        },
                                @"target": self.reactTag,
                                });
    }
}

- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}

#pragma mark - Setup

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView) {
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat xScale = boundsSize.width / imageSize.width;
        CGFloat yScale = boundsSize.height / imageSize.height;
        zoomScale = [self.initialScaleMode isEqualToString: @"cover"] ? MAX(xScale, yScale) : MIN(xScale, yScale);
        zoomScale = MAX(MIN(self.maxZoomScale, zoomScale), self.minimumZoomScale);
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {

    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;

    // Bail if no image
    if (_photoImageView.image == nil) return;

    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);

    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;

    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise

    // use minimum (if initialScaleMode is 'contain') or maximum (if initialScaleMode is 'cover') of these to allow the image to become fully visible
    CGFloat minScale = [self.initialScaleMode isEqualToString:@"cover"] ? MAX(xScale, yScale) : MIN(xScale, yScale);

    /**
     [attention]
     original maximumZoomScale and minimumZoomScale is scaled to image,
     but we need scaled to scrollView,
     so has the next convert
     */
    CGFloat maxScale = minScale * _maxZoomScale;
    minScale = minScale * _minZoomScale;

    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;

    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];

    // Centralise
    CGFloat xOffset = MAX(imageSize.width * self.zoomScale - boundsSize.width, 0);
    CGFloat yOffset = MAX(imageSize.height * self.zoomScale - boundsSize.width, 0);
    self.contentOffset = CGPointMake(xOffset / 2.0, yOffset / 2.0);

    // Layout
    [self setNeedsLayout];

}

#pragma mark - Layout

- (void)layoutSubviews {

    // Update tap view frame
    _tapView.frame = self.bounds;

    // Super
    [super layoutSubviews];

    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;

    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }

    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }

    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
        _photoImageView.frame = frameToCenter;
    if (self.onPhotoViewerScale) {
        self.onPhotoViewerScale(@{
                                    @"contentSize": @{
                                      @"width": @(self.contentSize.width),
                                      @"height": @(self.contentSize.height)
                                    },
                                    @"contentOffset": @{
                                      @"x": @(self.contentOffset.x),
                                      @"y": @(self.contentOffset.y)
                                    },
                                    @"target": self.reactTag
                                });
    }
}

#pragma mark - Image

// Get and display image
- (void)displayWithImage:(UIImage*)image {
    if (image && !_photoImageView.image) {

        // Reset
//        self.maximumZoomScale = 1;
//        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);

        // Set image
        _photoImageView.image = image;
        _photoImageView.hidden = NO;

        // Setup photo frame
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = image.size;
        _photoImageView.frame = photoImageViewFrame;
        self.contentSize = photoImageViewFrame.size;

        // Set zoom to minimum zoom
        [self setMaxMinZoomScalesForCurrentBounds];
        [self setNeedsLayout];
    }
}

#pragma mark - Setter

- (void)setSource:(NSDictionary *)source {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        if ([_source isEqualToDictionary:source]) {
            return;
        }
        NSString *uri = source[@"uri"];
        if (!uri) {
            return;
        }
        _source = source;
        NSURL *imageURL = [NSURL URLWithString:uri];

        if (![[uri substringToIndex:4] isEqualToString:@"http"]) {
            @try {
                UIImage *image = RCTImageFromLocalAssetURL(imageURL);
                if (image) { // if local image
                    __weak RNPhotoView *weakSelf = self;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf setImage:image];
                    });
                    if (_onPhotoViewerLoad) {
                        _onPhotoViewerLoad(nil);
                    }
                    if (_onPhotoViewerLoadEnd) {
                        _onPhotoViewerLoadEnd(nil);
                    }
                    return;
                }
            }
            @catch (NSException *exception) {
                NSLog(@"%@", exception.reason);
            }
        }

        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];

        if (source[@"headers"]) {
            NSMutableURLRequest *mutableRequest = [request mutableCopy];

            NSDictionary *headers = source[@"headers"];
            NSEnumerator *enumerator = [headers keyEnumerator];
            id key;
            while((key = [enumerator nextObject]))
                [mutableRequest addValue:[headers objectForKey:key] forHTTPHeaderField:key];
            request = [mutableRequest copy];
        }

        __weak RNPhotoView *weakSelf = self;
        if (_onPhotoViewerLoadStart) {
            _onPhotoViewerLoadStart(nil);
        }

        // use default values from [imageLoader loadImageWithURLRequest:request callback:callback] method
        [_bridge.imageLoader loadImageWithURLRequest:request
                                        size:CGSizeZero
                                       scale:1
                                     clipped:YES
                                  resizeMode:RCTResizeModeStretch
                               progressBlock:^(int64_t progress, int64_t total) {
                                   if (_onPhotoViewerProgress) {
                                       _onPhotoViewerProgress(@{
                                           @"loaded": @((double)progress),
                                           @"total": @((double)total),
                                       });
                                   }
                               }
                            partialLoadBlock:nil
                             completionBlock:^(NSError *error, UIImage *image) {
                                                if (image) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [weakSelf setImage:image];
                                                    });
                                                    if (_onPhotoViewerLoad) {
                                                        _onPhotoViewerLoad(nil);
                                                    }
                                                } else {
                                                    if (_onPhotoViewerError) {
                                                        _onPhotoViewerError(nil);
                                                    }
                                                }
                                                if (_onPhotoViewerLoadEnd) {
                                                    _onPhotoViewerLoadEnd(nil);
                                                }
                                            }];
    });
}

- (void)setLoadingIndicatorSrc:(NSString *)loadingIndicatorSrc {
    if (!loadingIndicatorSrc) {
        return;
    }
    if ([_loadingIndicatorSrc isEqualToString:loadingIndicatorSrc]) {
        return;
    }
    _loadingIndicatorSrc = loadingIndicatorSrc;
    NSURL *imageURL = [NSURL URLWithString:_loadingIndicatorSrc];
    UIImage *image = RCTImageFromLocalAssetURL(imageURL);
    if (image) {
        [self setLoadingImage:image];
    }
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self displayWithImage:_image];
}

- (void)setLoadingImage:(UIImage *)loadingImage {
    _loadingImage = loadingImage;
    if (_loadingImageView) {
        [_loadingImageView setImage:_loadingImage];
    } else {
        _loadingImageView = [[UIImageView alloc] initWithImage:_loadingImage];
        _loadingImageView.center = self.center;
        _loadingImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _loadingImageView.backgroundColor = [UIColor clearColor];
        [_tapView addSubview:_loadingImageView];
    }
}

- (void)setScale:(NSInteger)scale {
    _scale = scale;
    [self setZoomScale:_scale];
}

- (void)setInitialScaleMode:(NSString *)initialScaleMode {
    NSString *containMode = @"contain";
    NSString *coverMode = @"cover";
    if (!initialScaleMode || !([initialScaleMode isEqualToString:containMode] || [initialScaleMode isEqualToString:coverMode])) {
        return;
    }
    _initialScaleMode = initialScaleMode;
}

#pragma mark - Private

- (void)initView {
    _minZoomScale = 1.0;
    _maxZoomScale = 5.0;

    // Setup
    self.backgroundColor = [UIColor clearColor];
    self.delegate = self;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.showsVerticalScrollIndicator = YES;
    self.showsHorizontalScrollIndicator = YES;

    // Tap view for background
    _tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
    _tapView.tapDelegate = self;
    _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tapView.backgroundColor = [UIColor clearColor];
    [self addSubview:_tapView];

    // Image view
    _photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:self.bounds];
    _photoImageView.backgroundColor = [UIColor clearColor];
    _photoImageView.contentMode = UIViewContentModeCenter;
    _photoImageView.tapDelegate = self;
    [self addSubview:_photoImageView];
}

@end
