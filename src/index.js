/**
 * Created by tdzl2003 on 4/13/16.
 */

import {NativeModules, NativeAppEventEmitter} from 'react-native';
import {EventEmitter} from 'fbemitter';

const RongIMLib = NativeModules.RongIMLib;

const eventEmitter = new EventEmitter();
Object.assign(exports, RongIMLib);

exports.eventEmitter = eventEmitter;
exports.addListener = eventEmitter.addListener.bind(eventEmitter);
exports.once = eventEmitter.once.bind(eventEmitter);
exports.removeAllListeners = eventEmitter.removeAllListeners.bind(eventEmitter);
exports.removeCurrentListener = eventEmitter.removeCurrentListener.bind(eventEmitter);

NativeAppEventEmitter.addListener('rongIMMsgRecved', msg => {
  eventEmitter.emit('msgRecved', msg);
});
