import React from "react";
import PropTypes, { any } from "prop-types";
import {
  requireNativeComponent,
  Image,
  StyleSheet,
  View,
  ViewPropTypes
} from "react-native";

export default class PhotoView extends React.PureComponent {
  static propTypes = {
    source: PropTypes.oneOfType([
      PropTypes.shape({
        uri: PropTypes.string
      }),
      PropTypes.number
    ]).isRequired,
    initialScaleMode: PropTypes.oneOf(["contain", "cover"]),
    onScale: PropTypes.func,
    initialLayout: PropTypes.object,
    showsHorizontalScrollIndicator: PropTypes.bool,
    showsVerticalScrollIndicator: PropTypes.bool,
    ...ViewPropTypes
  };

  render() {
    const {
      onScale,
      source: _source,
      loadingIndicatorSource: _loadingIndicatorSource,
      style: _style,
      ...props
    } = this.props;

    const source = Image.resolveAssetSource(_source);
    const loadingIndicatorSource = Image.resolveAssetSource(
      _loadingIndicatorSource
    );

    if (source && source.uri === "") {
      console.warn("source.uri should not be an empty string");
    }

    if (props.src) {
      console.warn(
        "The <PhotoView> component requires a `source` property rather than `src`."
      );
    }

    if (source && source.uri) {
      const { width, height, ...src } = source;
      const style = StyleSheet.flatten([{ width, height }, _style]);

      const nativeProps = {
        onPhotoViewerScale: onScale,
        ...props,
        style,
        src,
        loadingIndicatorSrc:
          (loadingIndicatorSource && loadingIndicatorSource.uri) || null
      };

      return <RNPhotoView {...nativeProps} />;
    }
    return null;
  }
}

const cfg = {
  nativeOnly: {
    onPhotoViewerScale: true,
    src: true,
    loadingIndicatorSrc: true
  }
};

const RNPhotoView = requireNativeComponent("RNPhotoView", PhotoView, cfg);
