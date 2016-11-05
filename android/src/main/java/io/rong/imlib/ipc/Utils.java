package io.rong.imlib.ipc;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.RectF;
import android.net.Uri;
import android.support.annotation.Nullable;

import com.facebook.common.executors.UiThreadImmediateExecutorService;
import com.facebook.common.references.CloseableReference;
import com.facebook.datasource.DataSource;
import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.imagepipeline.common.ResizeOptions;
import com.facebook.imagepipeline.core.ImagePipeline;
import com.facebook.imagepipeline.datasource.BaseBitmapDataSubscriber;
import com.facebook.imagepipeline.image.CloseableImage;
import com.facebook.imagepipeline.request.ImageRequest;
import com.facebook.imagepipeline.request.ImageRequestBuilder;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.w3c.dom.Text;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
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
        ret.putBoolean("isTop", conv.isTop());
        ret.putString("type", conv.getConversationType().getName());
        ret.putString("targetId", conv.getTargetId());
        ret.putString("senderUserId", conv.getSenderUserId());
        ret.putInt("unreadCount", conv.getUnreadMessageCount());
        ret.putDouble("sentTime", conv.getSentTime());
        ret.putDouble("receivedTime", conv.getReceivedTime());
        ret.putDouble("latestMessageId", conv.getLatestMessageId());

        ret.putString("conversationTitle", conv.getConversationTitle());
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

    public static String convertMessageContentToString(MessageContent content) {
        if (content instanceof TextMessage) {
            TextMessage textContent = (TextMessage)content;
            return textContent.getContent();
        } else if (content instanceof VoiceMessage) {
            VoiceMessage voiceContent = (VoiceMessage)content;
            return "[语音消息]";
        } else if (content instanceof ImageMessage){
            ImageMessage imageContent = (ImageMessage)content;
            return "[图片]";
        } else if (content instanceof CommandNotificationMessage) {
            return "[通知]";
        } else {
            return "[新消息]";
        }
    }

    public interface ImageCallback {
        void invoke(@Nullable Bitmap bitmap);
    }

    public static void getImage(Uri uri, ResizeOptions resizeOptions, final ImageCallback imageCallback) {
        BaseBitmapDataSubscriber dataSubscriber = new BaseBitmapDataSubscriber() {
            @Override
            protected void onNewResultImpl(Bitmap bitmap) {
                bitmap = bitmap.copy(bitmap.getConfig(), true);
                imageCallback.invoke(bitmap);
            }

            @Override
            protected void onFailureImpl(DataSource<CloseableReference<CloseableImage>> dataSource) {
                imageCallback.invoke(null);
            }
        };

        ImageRequestBuilder builder = ImageRequestBuilder.newBuilderWithSource(uri);
        if (resizeOptions != null) {
            builder = builder.setResizeOptions(resizeOptions);
        }
        ImageRequest imageRequest = builder.build();

        ImagePipeline imagePipeline = Fresco.getImagePipeline();
        DataSource<CloseableReference<CloseableImage>> dataSource = imagePipeline.fetchDecodedImage(imageRequest, null);
        dataSource.subscribe(dataSubscriber, UiThreadImmediateExecutorService.getInstance());
    }

    public static MessageContent convertImageMessageContent(Context context, Bitmap bmpSource) throws IOException {
        File imageFileSource = new File(context.getCacheDir(), "source.jpg");
        File imageFileThumb = new File(context.getCacheDir(), "thumb.jpg");

        FileOutputStream fosSource = new FileOutputStream(imageFileSource);

        // 保存原图。
        bmpSource.compress(Bitmap.CompressFormat.JPEG, 100, fosSource);

        // 创建缩略图变换矩阵。
        Matrix m = new Matrix();
        m.setRectToRect(new RectF(0, 0, bmpSource.getWidth(), bmpSource.getHeight()), new RectF(0, 0, 160, 160), Matrix.ScaleToFit.CENTER);

        // 生成缩略图。
        Bitmap bmpThumb = Bitmap.createBitmap(bmpSource, 0, 0, bmpSource.getWidth(), bmpSource.getHeight(), m, true);

        imageFileThumb.createNewFile();

        FileOutputStream fosThumb = new FileOutputStream(imageFileThumb);
        bmpThumb.compress(Bitmap.CompressFormat.JPEG, 60, fosThumb);

        ImageMessage imgMsg = ImageMessage.obtain(Uri.fromFile(imageFileThumb), Uri.fromFile(imageFileSource));

        return imgMsg;
    }
}
