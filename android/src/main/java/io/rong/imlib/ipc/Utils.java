package io.rong.imlib.ipc;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.w3c.dom.Text;

import java.util.List;

import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Message;
import io.rong.imlib.model.MessageContent;
import io.rong.message.TextMessage;

/**
 * Created by tdzl2003 on 4/13/16.
 */
public class Utils {

    public static WritableMap convertMessage(Message message) {
        WritableMap ret = Arguments.createMap();
        ret.putString("senderId", message.getSenderUserId());
        ret.putString("targetId", message.getTargetId());
        ret.putString("conversationType", message.getConversationType().getName());
        ret.putString("extra", message.getExtra());
        ret.putInt("messageId", message.getMessageId());
        ret.putDouble("receivedTime", message.getReceivedTime());
        ret.putDouble("sentTime", message.getSentTime());
        ret.putMap("content", convertMessageContent(message.getContent()));
        return ret;
    }


    private static WritableMap convertMessageContent(MessageContent content) {
        WritableMap ret = Arguments.createMap();
        if (content instanceof TextMessage) {
            TextMessage textContent = (TextMessage)content;
            ret.putString("type", "text");
            ret.putString("content", textContent.getContent());
            ret.putString("extra", textContent.getExtra());
        } else {
            ret.putString("type", "unknown");
        }
        return ret;
    }

    public static WritableArray convertMessageList(List<Message> messages) {
        WritableArray ret = Arguments.createArray();
        for (Message msg : messages) {
            ret.pushMap(convertMessage(msg));
        }
        return ret;
    }

    public static WritableArray convertConversationList(List<Conversation> conversations) {
        WritableArray ret = Arguments.createArray();
        for (Conversation conv : conversations) {
            ret.pushMap(convertConversation(conv));
        }
        return ret;
    }

    private static WritableMap convertConversation(Conversation conv) {
        WritableMap ret = Arguments.createMap();
        ret.putString("title", conv.getConversationTitle());
        ret.putString("type", conv.getConversationType().getName());
        ret.putString("targetId", conv.getTargetId());
        ret.putInt("unreadCount", conv.getUnreadMessageCount());
        ret.putMap("lastMessage", convertMessageContent(conv.getLatestMessage()));
        return ret;
    }

    public static MessageContent convertToMessageContent(ReadableMap map) {
        String type = map.getString("type");
        if (type.equals("text")) {
            TextMessage ret =  TextMessage.obtain(map.getString("content"));
            if (map.hasKey("extra")){
                ret.setExtra(map.getString("extra"));
            }
            return ret;
        }
        return TextMessage.obtain("[未知消息]");
    }
}
