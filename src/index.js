/**
 * Created by tdzl2003 on 4/13/16.
 */

import {NativeModules, DeviceEventEmitter} from 'react-native';
import EventEmitter from 'react-native/Libraries/vendor/emitter/EventEmitter';

const RongIMLib = NativeModules.RongIMLib;

for (var k in NativeModules){
  console.log(k);
}

const eventEmitter = new EventEmitter();
Object.assign(exports, RongIMLib);

exports.eventEmitter = eventEmitter;
exports.addListener = eventEmitter.addListener.bind(eventEmitter);
exports.once = eventEmitter.once.bind(eventEmitter);
exports.removeAllListeners = eventEmitter.removeAllListeners.bind(eventEmitter);
exports.removeCurrentListener = eventEmitter.removeCurrentListener.bind(eventEmitter);

DeviceEventEmitter.addListener('rongIMMsgRecved', msg => {
  if (__DEV__){
    console.log(msg);
  }
  eventEmitter.emit('msgRecved', msg);
});
