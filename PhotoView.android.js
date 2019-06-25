import React from 'react'
import PropTypes from 'prop-types'
import { requireNativeComponent, Image, StyleSheet, ViewPropTypes } from 'react-native'

export default class PhotoView extends React.PureComponent {

  static propTypes = {
    source: PropTypes.oneOfType([
      PropTypes.shape({
        uri: PropTypes.string,
      }),
      PropTypes.number,
    ]).isRequired,
    initialScaleMode: PropTypes.oneOf(['contain', 'cover']),
    onScale: PropTypes.func,
    ...ViewPropTypes,
  };

  render() {
    const {
      onScale,
      source: _source,
      style: _style,
      ...props
    } = this.props

    const source = Image.resolveAssetSource(_source)

    if (source && source.uri === '') {
      console.warn('source.uri should not be an empty string')
    }

    if (props.src) {
      console.warn('The <PhotoView> component requires a `source` property rather than `src`.')
    }

    if (source && source.uri) {
      const { width, height, ...src } = source
      const style = StyleSheet.flatten([{ width, height }, _style])

      const nativeProps = {
        onPhotoViewerScale: onScale,
        ...props,
        style,
        src,
      }

      return <PhotoViewAndroid {...nativeProps} />
    }

    return null
  }
}

const cfg = {
  nativeOnly: {
    onPhotoViewerScale: true,
    src: true,
  },
}

const PhotoViewAndroid = requireNativeComponent('PhotoViewAndroid', PhotoView, cfg)
