/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
var {
  AppRegistry,
  StyleSheet,
  Text,
  Image,
  TextInput,
  PanResponder,
  TouchableOpacity,
  View,
} = React;

var createReactIOSNativeComponentClass = require('createReactIOSNativeComponentClass');
var DeviceEventEmitter = require('RCTDeviceEventEmitter');
var Dimensions = require('Dimensions');

var CameraType = {
  CAMERA_FRONT: 0,
  CAMERA_BACK: 1,
};
var FlashType = {
  FLASH_AUTO: 0,
  FLASH_ON: 1,
  FLASH_OFF: 2,
};

var SCREEN_WIDTH = Dimensions.get('window').width;
var HEADER = '#3b5998';
var BGWASH = 'rgba(255,255,255,0.8)';
var DISABLED_WASH = 'rgba(255,255,255,0.25)';
var TEXT_BG = 'rgba(51, 102, 204,0.8)';

var CAMERA_REF = 'cameraview';

var MyCameraView = createReactIOSNativeComponentClass({
  validAttributes: { cameraType: 'camera-back' },
  uiViewClassName: 'MyCameraView',
});

var MyCameraViewMananger = require('NativeModules').MyCameraViewManager;

var SnapChatProject = React.createClass({

  _panResponder: {},
  _previousLeft: 0,
  _previousTop: 0,
  _textStyles: {},
  MAX_TOP:(SCREEN_WIDTH - 28)/2,
  textView: (null : ?React.Element),

  getInitialState: function() {
      return {
        cameraType: CameraType.CAMERA_FRONT,
        hasFlash: false,
        flashType: FlashType.FLASH_AUTO,
        takenPhotoURI: null,
        showTextInput: false,
      };
  },

  componentWillMount: function() {
    this._panResponder = PanResponder.create({
      onStartShouldSetPanResponder: this._handleStartShouldSetPanResponder,
      onMoveShouldSetPanResponder: this._handleMoveShouldSetPanResponder,
      onPanResponderGrant: this._handlePanResponderGrant,
      onPanResponderMove: this._handlePanResponderMove,
      onPanResponderRelease: this._handlePanResponderEnd,
      onPanResponderTerminate: this._handlePanResponderEnd,
    });
  },

  componentDidMount: function() {
    MyCameraViewMananger.checkFlashLightSupport(
      this.state.cameraType,
      this._onHasFlashSuccess
    );
    DeviceEventEmitter.addListener(
      'takePhotoFinishData',
      this._onTakePhotoSuccess
    );
  },
  _onTakePhotoSuccess: function(data) {
    console.log('data data = ' + data.name);
    this.setState({
      'takenPhotoURI': data.name,
    });
  },
  _onHasFlashSuccess: function(hasFlash) {
    this.setState({
      'hasFlash': hasFlash,
    });
  },

  render: function() {
    if (this.state.takenPhotoURI){
      return this.renderEditPhotoUI();
    } 
      
    return this.renderTakePhotoUI();    
  },

  renderEditPhotoUI: function() {
    var photoImage = this.renderPhoto();

    var topBar = this.renderTopBar(this.resetUIToRetakePhoto, 'Re-take', this.addText, 'Add Text');
    var bottomBar = this.renderBottomBar(this.sharePhoto, require('image!send_btn'));

    return (
      <View style={styles.container}>
        {topBar}
        {photoImage}
        {bottomBar}
      </View>
    );
  },

  renderTakePhotoUI: function() {
    var flipCameraText = (this.state.cameraType == CameraType.CAMERA_FRONT) ? 'Front Camera' : 'Back Camera';
    var flashToggleText = this.getFlashButtonText(this.state.flashType);
    var topBar = this.renderTopBar(this.flipCamera, flipCameraText, null, null);
    if (this.state.hasFlash == true){
      topBar = this.renderTopBar(this.flipCamera, flipCameraText, this.flashToggle, flashToggleText);
    }

    var bottomBar = this.renderBottomBar(this.takePhoto, require('image!takephoto_btn'));
    var cameraView = <MyCameraView ref={CAMERA_REF} style={styles.cameraContainer}/>;

    return (
      <View style={styles.container}>
        {topBar}
        {cameraView}
        {bottomBar}
      </View>
    );
  },

  renderPhoto: function(){
    var inputText;
    var text;

    if (this.state.showTextInput) inputText = this.renderTextInput();
    else {
      if (this.state.inputText){
        text = (<Text ref={(text) => { this.textView = text; }} 
                      style={styles.text} 
                      {...this._panResponder.panHandlers}>{this.state.inputText}</Text>);

        this._previousLeft = 0;
        this._previousTop = 0;
        this._textStyles = {
          left: this._previousLeft,
          top: this._previousTop,
        };
      }
    }
    
    return(
      <Image source={{uri: this.state.takenPhotoURI, isStatic: true}}
             style={styles.thumbnail}> 
        {inputText}
        {text}
      </Image>
    );
  },

  renderTextInput: function() {
    var content = '';
    if (this.state.inputText) content = this.state.inputText;

    return (<TextInput 
                style={styles.input}
                value = {content}
                autoFocus = {true}
                onChangeText = {(text) => this.setState({'inputText': text}) }
                onEndEditing = {() => this.setState({'showTextInput': false}) } >
              </TextInput>);

    this.setState({
      'showTextInput': true,
    });
  },

  renderTopBar: function(action1, text1, action2, text2) {
    var button1, button2;

    if (action1 && text1) button1 = this.renderUtilButton(action1, text1);
    if (action2 && text2) button2 = this.renderUtilButton(action2, text2);

    // return camera type and flash type buttons
    return (
      <View style={[styles.topBarRow]}>
        {button1}
        {button2}
      </View>
    );
  },

  renderBottomBar: function(action, buttonImage) {
    var button = this.renderUtilImageButton(action, buttonImage);

    return (
      <View style={styles.bottomBarRow}>
        {button}
      </View>
    );
  },

  renderUtilButton: function(action, text){
    return (
      <TouchableOpacity onPress={action}>
        <View style={styles.navButton}>
          <Text>
             {text}
          </Text>
        </View>
      </TouchableOpacity>
    );
  },

  renderUtilImageButton: function(action, buttonImage){
    return (
      <TouchableOpacity onPress={action}>
        <Image
          style={styles.imageButton}
          source={buttonImage}
        />
      </TouchableOpacity>
      );
  },

  getCameraViewHandle: function(): any {
    return this.refs[CAMERA_REF].getNodeHandle();
  },

  flipCamera: function() {
    var newCameraType = CameraType.CAMERA_BACK;
    if (this.state.cameraType == CameraType.CAMERA_BACK) newCameraType = CameraType.CAMERA_FRONT;
    MyCameraViewMananger.toggleCamera(newCameraType, this.getCameraViewHandle());
    this.setState({
      'cameraType': newCameraType ,
    });
    MyCameraViewMananger.checkFlashLightSupport(
      this.state.cameraType,
      this._onHasFlashSuccess
    );
  },

  flashToggle: function() {
    var newFlashType = this.getNextFlashType(this.state.flashType);
    MyCameraViewMananger.toggleFlash(newFlashType, this.getCameraViewHandle());
    this.setState({
      'flashType': newFlashType,
    });
  },

  takePhoto: function() {
    MyCameraViewMananger.takePhoto(this.getCameraViewHandle());
  },

  resetUIToRetakePhoto: function() {
    // reset state values to null
    this.setState({
      'takenPhotoURI': null,
      'showTextInput': false,
      'inputText': null,
    });
  },

  addText: function(){
    this.setState({
      'showTextInput': true,
    });
  },
  
  sharePhoto: function(){
    MyCameraViewMananger.sharePhoto(this.state.inputText, this.getTextPositionY());
  },

  _updatePosition: function() {
    //console.log('MAX_TOP ' + this.MAX_TOP + 'top ' + this._textStyles.top);
    this.textView && this.textView.setNativeProps(this._textStyles);
  },

  _handleStartShouldSetPanResponder: function(e: Object, gestureState: Object): boolean {
    // Should we become active when the user presses down on the circle?
    return true;
  },

  _handleMoveShouldSetPanResponder: function(e: Object, gestureState: Object): boolean {
    // Should we become active when the user moves a touch over the circle?
    return true;
  },

  _handlePanResponderGrant: function(e: Object, gestureState: Object) {
    
  },
  _handlePanResponderMove: function(e: Object, gestureState: Object) {
    // limit the movement inside image boundsthis._textStyles.left = 0;
    var newTopPos = this._previousTop + gestureState.dy;
    if (Math.abs(newTopPos) <= this.MAX_TOP){
      this._textStyles.top = this._previousTop + gestureState.dy;
    } else {
      this._textStyles.top = this.MAX_TOP;
      if (newTopPos < 0) this._textStyles.top = -this.MAX_TOP;
    }
    
    this._updatePosition();
  },
  _handlePanResponderEnd: function(e: Object, gestureState: Object) {
    //this._previousLeft += gestureState.dx;
    this._previousTop += gestureState.dy;
  },

  getTextPositionY: function(){
    var posY;
    console.log('this._textStyles.top = ' + this._textStyles.top);
    if (this._textStyles.top < 0) posY = this.MAX_TOP - Math.abs(this._textStyles.top);
    else posY = this.MAX_TOP + this._textStyles.top;

    // original image 640 x 640. calculate ratio value and multiply
    var ratio = 640 / SCREEN_WIDTH;
    return posY * ratio;
  },

  getFlashButtonText: function(flashType){
    switch (flashType) {
      case FlashType.FLASH_AUTO:
          return 'Flash: AUTO';
          break;
      case FlashType.FLASH_ON:
          return 'Flash: ON';
          break;
      case FlashType.FLASH_OFF:
          return 'Flash: OFF';
          break;
    }
  },

  getNextFlashType: function(flashType){
    switch (flashType) {
      case FlashType.FLASH_AUTO:
          return FlashType.FLASH_ON;
          break;
      case FlashType.FLASH_ON:
          return FlashType.FLASH_OFF;
          break;
      case FlashType.FLASH_OFF:
          return FlashType.FLASH_AUTO;
          break;
    }
  },

});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    top: 20,
    backgroundColor: HEADER,
  },
  topBarRow: {
    flexDirection: 'row',
    padding: 8,
  },
  bottomBarRow: {
    flexDirection: 'row',
    padding: 8,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: BGWASH,
  },
  cameraContainer: {
    width: SCREEN_WIDTH,
    height: SCREEN_WIDTH,
  },
  navButton: {
    width: 100,
    padding: 3,
    marginRight: 3,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: BGWASH,
    borderColor: 'transparent',
    borderRadius: 3,
  },
  imageButton: {
    width: 50,
    height: 50,
  },
  thumbnail: {
    height: SCREEN_WIDTH,
    width: SCREEN_WIDTH,
    resizeMode: Image.resizeMode.contain,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'white',
  },
  input: {
    height: 28,
    width: SCREEN_WIDTH,
    backgroundColor: TEXT_BG,
    fontSize: 20,
    textAlign: 'center',
    color: 'white',
  },
  text: {
    width: SCREEN_WIDTH,
    height: 28,
    fontSize: 20,
    textAlign: 'center',
    containerBackgroundColor: TEXT_BG,
    color: 'white',
  }
});

AppRegistry.registerComponent('SnapChatProject', () => SnapChatProject);
