package io.rong.imlib.ipc;

import android.net.Uri;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.w3c.dom.Text;

import java.util.List;

import io.rong.imlib.RongIMClient;
import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Message;
import io.rong.imlib.model.MessageContent;
import io.rong.message.CommandNotificationMessage;
import io.rong.message.ImageMessage;
import io.rong.message.TextMessage;
import io.rong.message.VoiceMessage;

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
        } else if (content instanceof VoiceMessage) {
            VoiceMessage voiceContent = (VoiceMessage)content;
            ret.putString("type", "voice");
            ret.putString("uri", voiceContent.getUri().toString());
            ret.putInt("duration", voiceContent.getDuration());
            ret.putString("extra", voiceContent.getExtra());
        } else if (content instanceof ImageMessage){
            ImageMessage imageContent = (ImageMessage)content;
            ret.putString("type", "image");
            if (imageContent.getLocalUri() != null) {
                ret.putString("imageUrl", imageContent.getLocalUri().toString());
            }
            ret.putString("thumb", imageContent.getThumUri().toString());
            ret.putString("extra", imageContent.getExtra());
        } else if (content instanceof CommandNotificationMessage) {
            CommandNotificationMessage notifyContent = (CommandNotificationMessage)content;
            ret.putString("type", "notify");
            ret.putString("name", notifyContent.getName());
            ret.putString("data", notifyContent.getData());
        } else {
            ret.putString("type", "unknown");
        }
        return ret;
    }

    public static WritableArray convertMessageList(List<Message> messages) {
        WritableArray ret = Arguments.createArray();

        if (messages != null) {
            for (Message msg : messages) {
                ret.pushMap(convertMessage(msg));
            }
        }
        return ret;
    }

    public static WritableArray convertConversationList(List<Conversation> conversations) {
        WritableArray ret = Arguments.createArray();
        if (conversations != null) {
            for (Conversation conv : conversations) {
                ret.pushMap(convertConversation(conv));
            }
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
            if (map.hasKey("extra")) {
                ret.setExtra(map.getString("extra"));
            }
            return ret;
        } else if (type.equals("voice")) {
            VoiceMessage ret = VoiceMessage.obtain(Uri.parse(map.getString("uri")), map.getInt("duration"));
//            ret.setBase64(map.getString("base64"));
            if (map.hasKey("extra")) {
                ret.setExtra(map.getString("extra"));
            }
            return ret;
        } else if (type.equals("image")) {
            String uri = map.getString("imageUrl");
            ImageMessage ret = ImageMessage.obtain(Uri.parse(uri), Uri.parse(uri), map.hasKey("full") && map.getBoolean("full"));
            if (map.hasKey("extra")) {
                ret.setExtra(map.getString("extra"));
            }
            return ret;
        } else if (type.equals("notify")) {
            CommandNotificationMessage ret = CommandNotificationMessage.obtain(map.getString("name"), map.getString("data"));
            return ret;
        }
        return TextMessage.obtain("[未知消息]");
    }
}
