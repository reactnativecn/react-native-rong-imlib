package io.rong.imlib.ipc;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.List;

import io.rong.imlib.RongIMClient;
import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Message;

/**
 * Created by tdzl2003 on 3/31/16.
 */
public class IMLibModule extends ReactContextBaseJavaModule implements RongIMClient.OnReceiveMessageListener {

    static boolean isIMClientInited = false;

    public IMLibModule(ReactApplicationContext reactContext) {
        super(reactContext);

        if (!isIMClientInited) {
            isIMClientInited = true;
            RongIMClient.init(reactContext.getApplicationContext());
        }
    }

    @Override
    public String getName() {
        return "RCTRongIMLib";
    }

    @Override
    public void initialize() {
        RongIMClient.setOnReceiveMessageListener(this);
    }

    @Override
    public void onCatalystInstanceDestroy() {
        RongIMClient.setOnReceiveMessageListener(null);
    }

    private void sendDeviceEvent(String type, Object arg){
        ReactContext context = this.getReactApplicationContext();
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(type, arg);

    }

    @Override
    public boolean onReceived(Message message, int i) {
        sendDeviceEvent("rongIMMsgRecved", Utils.convertMessage(message));
        return false;
    }

    RongIMClient client = null;

    @ReactMethod
    public void connect(String token, final Promise promise){
        if (client != null) {
            promise.reject("AlreadyLogined", "Is already logined.");
            return;
        }
        client = RongIMClient.connect(token, new RongIMClient.ConnectCallback() {
            /**
             * Token 错误，在线上环境下主要是因为 Token 已经过期，您需要向 App Server 重新请求一个新的 Token
             */
            @Override
            public void onTokenIncorrect() {
                promise.reject("TokenIncorrect", "Incorrect token provided.");
            }

            /**
             * 连接融云成功
             * @param userid 当前 token
             */
            @Override
            public void onSuccess(String userid) {
                promise.resolve(userid);
            }

            /**
             * 连接融云失败
             * @param errorCode 错误码，可到官网 查看错误码对应的注释
             */
            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject("" + errorCode.getValue(), errorCode.getMessage());
            }
        });
    }

    @ReactMethod
    public void getConversationList(final Promise promise){
        if (client == null) {
            promise.reject("NotLogined", "Must call connect first.");
            return;
        }
        client.getConversationList(new RongIMClient.ResultCallback<List<Conversation>>(){

            @Override
            public void onSuccess(List<Conversation> conversations) {
                promise.resolve(Utils.convertConversationList(conversations));
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject("" + errorCode.getValue(), errorCode.getMessage());
            }
        });
    }

    @ReactMethod
    public void logout(final Promise promise){
        if (client == null) {
            promise.reject("NotLogined", "Must call connect first.");
            return;
        }
        client.logout();
        client = null;
        promise.resolve(null);
    }

    @ReactMethod
    public void getLatestMessages(String type, String targetId, int count, final Promise promise) {
        if (client == null) {
            promise.reject("NotLogined", "Must call connect first.");
            return;
        }
        client.getLatestMessages(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, count, new RongIMClient.ResultCallback<List<Message>>() {

            @Override
            public void onSuccess(List<Message> messages) {
                promise.resolve(Utils.convertMessageList(messages));
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject("" + errorCode.getValue(), errorCode.getMessage());
            }
        });
    }

    @ReactMethod
    public void sendMessage(String type, String targetId, ReadableMap map, String pushContent, String pushData, final Promise promise) {
        if (client == null) {
            promise.reject("NotLogined", "Must call connect first.");
            return;
        }
        client.sendMessage(Conversation.ConversationType.valueOf(type.toUpperCase()), targetId, Utils.convertToMessageContent(map), pushContent, pushData, new RongIMClient.SendMessageCallback() {
            @Override
            public void onError(Integer messageId, RongIMClient.ErrorCode e) {
                WritableMap ret = Arguments.createMap();
                ret.putInt("messageId", messageId);
                ret.putInt("errCode", e.getValue());
                ret.putString("errMsg", e.getMessage());
                sendDeviceEvent("msgSendFailed", ret);
            }

            @Override
            public void onSuccess(Integer messageId) {
                sendDeviceEvent("msgSendOk", messageId);

            }

        }, new RongIMClient.ResultCallback<Message>() {
            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject("" + errorCode.getValue(), errorCode.getMessage());
            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(Utils.convertMessage(message));
            }

        } );
    }
}
