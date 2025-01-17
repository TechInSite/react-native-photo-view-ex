package io.amarcruz.photoview;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.UIManagerModule;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.events.EventDispatcher;

import android.graphics.RectF;
import android.net.Uri;
import android.widget.ImageView;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import java.util.Map;

/**-+
 * @author alwx (https://github.com/alwx)
 * @version 1.0
 */
public class PhotoViewManager extends SimpleViewManager<PhotoView> {
    private static final String REACT_CLASS = "PhotoViewAndroid";
    private ThemedReactContext mCurrentReactContext;

    @Override
    @Nonnull
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    @Nonnull
    protected PhotoView createViewInstance(@Nonnull ThemedReactContext reactContext) {
        PhotoView photoView = new PhotoView(reactContext);
        mCurrentReactContext = reactContext;
        // photoView.setScaleType(ImageView.ScaleType.CENTER_CROP);

        final EventDispatcher eventDispatcher = reactContext.getNativeModule(UIManagerModule.class).getEventDispatcher();
        photoView.setOnMatrixChangeListener(new OnMatrixChangedListener() {
            @Override
            public void onMatrixChanged(RectF rect) {
                float pixelDensity = reactContext.getResources().getDisplayMetrics().density;
                double width = (rect.right - rect.left) / pixelDensity;
                double height = (rect.bottom - rect.top) / pixelDensity;
                double x = -(rect.left) / pixelDensity ;
                double y = -(rect.top) / pixelDensity ;
                WritableMap sizeMap = Arguments.createMap();
                sizeMap.putDouble("width", width);
                sizeMap.putDouble("height", height);
                WritableMap offsetMap = Arguments.createMap();
                offsetMap.putDouble("x", x);
                offsetMap.putDouble("y", y);
                WritableMap changeMap = Arguments.createMap();
                changeMap.putMap("contentSize", sizeMap);
                changeMap.putMap("contentOffset", offsetMap);
                eventDispatcher.dispatchEvent(
                        new ImageEvent(photoView.getId(), ImageEvent.ON_SCALE).setExtras(changeMap)
                );
            }
        });

        photoView.setOnPhotoTapListener(new OnPhotoTapListener() {
            @Override
            public void onPhotoTap(ImageView view, float x, float y) {
                WritableMap coordinatesMap = Arguments.createMap();
                coordinatesMap.putDouble("x", x);
                coordinatesMap.putDouble("y", y);

                eventDispatcher.dispatchEvent(
                    new ImageEvent(photoView.getId(), ImageEvent.ON_TAP).setExtras(coordinatesMap)
                );
            }
        });

        return photoView;
    }

    @ReactProp(name = "src")
    public void setSource(PhotoView view, @Nullable ReadableMap source) {
        Uri uri = Uri.parse(source.getString("uri"));
        view.setImageURI(uri);
    }

   @ReactProp(name = "initialScaleMode")
   public void setInitialScaleMode(PhotoView view, String mode) {
       if (mode.equals("cover")) {
           view.setScaleType(ImageView.ScaleType.CENTER_CROP);
       } else {
           view.setScaleType(ImageView.ScaleType.FIT_CENTER);
       }
   }

   @ReactProp(name = "initialLayout")
   public void setInitialLayout(PhotoView view, @Nullable ReadableMap initialLayout) {

        if (initialLayout == null) {
            return;
        }

        Double x = initialLayout.getDouble("x");
        Double y = initialLayout.getDouble("y");
        Double width = initialLayout.getDouble("width");
        Double height = initialLayout.getDouble("height");

        float pixelDensity = this.mCurrentReactContext.getResources().getDisplayMetrics().density;
        float right = (x.floatValue() + width.floatValue()) * pixelDensity;
        float bottom = (y.floatValue() + height.floatValue()) * pixelDensity;
        float left = x.floatValue() * pixelDensity;
        float top = y.floatValue() * pixelDensity;

        RectF rect = new RectF(left, top, right, bottom);

        view.setInitialLayout(rect);
    }


    @Override
    public @Nullable
    Map<String, Object> getExportedCustomDirectEventTypeConstants() {
        return MapBuilder.of(
                ImageEvent.eventNameForType(ImageEvent.ON_SCALE), MapBuilder.of("registrationName", "onPhotoViewerScale"),
                ImageEvent.eventNameForType(ImageEvent.ON_TAP), MapBuilder.of("registrationName", "onPhotoViewerTap")
        );
    }
}
