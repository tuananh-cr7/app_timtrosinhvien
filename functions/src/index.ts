import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Khởi tạo Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Lấy tất cả FCM tokens của một user
 */
async function getUserFCMTokens(userId: string): Promise<string[]> {
  try {
    const tokensSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('fcmTokens')
      .get();

    const tokens: string[] = [];
    tokensSnapshot.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      const tokenData = doc.data();
      if (tokenData.token) {
        tokens.push(tokenData.token);
      }
    });

    return tokens;
  } catch (error) {
    console.error(`Error getting FCM tokens for user ${userId}:`, error);
    return [];
  }
}

/**
 * Gửi notification đến một user
 */
async function sendNotificationToUser(
  userId: string,
  notification: {
    title: string;
    body: string;
    data?: { [key: string]: string };
  }
): Promise<void> {
  const tokens = await getUserFCMTokens(userId);

  if (tokens.length === 0) {
    console.log(`No FCM tokens found for user ${userId}`);
    return;
  }

  const message: admin.messaging.MulticastMessage = {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: notification.data || {},
    tokens: tokens,
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(`Successfully sent notification to ${response.successCount} devices`);
    
    if (response.failureCount > 0) {
      console.log(`Failed to send to ${response.failureCount} devices`);
      // Xóa invalid tokens
      response.responses.forEach((resp: admin.messaging.SendResponse, idx: number) => {
        if (!resp.success && resp.error) {
          const errorCode = resp.error.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            // Token không hợp lệ, xóa khỏi Firestore
            const invalidToken = tokens[idx];
            removeInvalidToken(userId, invalidToken).catch(console.error);
          }
        }
      });
    }
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

/**
 * Xóa invalid token khỏi Firestore
 */
async function removeInvalidToken(userId: string, token: string): Promise<void> {
  try {
    const tokensSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('fcmTokens')
      .where('token', '==', token)
      .get();

    const batch = db.batch();
    tokensSnapshot.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`Removed invalid token for user ${userId}`);
  } catch (error) {
    console.error(`Error removing invalid token:`, error);
  }
}

/**
 * Tạo notification document trong Firestore
 */
async function createNotificationDocument(
  userId: string,
  type: string,
  title: string,
  body: string,
  data?: { [key: string]: any }
): Promise<void> {
  try {
    await db.collection('notifications').add({
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data || {},
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Error creating notification document:', error);
  }
}

// ============================================
// CLOUD FUNCTIONS
// ============================================

/**
 * Trigger khi room được approve hoặc reject
 * Firestore trigger: rooms/{roomId} - onUpdate
 */
export const onRoomStatusChanged = functions.firestore
  .document('rooms/{roomId}')
  .onUpdate(async (change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const roomId = context.params.roomId;

    if (!before || !after) {
      console.log(`Room ${roomId}: Missing data, skipping`);
      return null;
    }

    const beforeStatus = before.status;
    const afterStatus = after.status;
    const ownerId = after.ownerId;

    // Chỉ xử lý khi status thay đổi
    if (beforeStatus === afterStatus || !ownerId) {
      return null;
    }

    // Room được approve
    if (beforeStatus !== 'active' && afterStatus === 'active') {
      const title = 'Tin đăng được duyệt';
      const body = `Phòng trọ "${after.title || 'của bạn'}" đã được duyệt và hiển thị trên ứng dụng.`;

      // Tạo notification document
      await createNotificationDocument(ownerId, 'room_approved', title, body, {
        roomId: roomId,
        roomTitle: after.title || '',
      });

      // Gửi push notification
      await sendNotificationToUser(ownerId, {
        title: title,
        body: body,
        data: {
          type: 'room_approved',
          roomId: roomId,
          roomTitle: after.title || '',
        },
      });

      console.log(`Room ${roomId} approved, notification sent to ${ownerId}`);
    }

    // Room bị reject
    if (beforeStatus !== 'rejected' && afterStatus === 'rejected') {
      const reason = after.rejectionReason || 'Không đáp ứng yêu cầu';
      const title = 'Tin đăng bị từ chối';
      const body = `Phòng trọ "${after.title || 'của bạn'}" đã bị từ chối. Lý do: ${reason}`;

      // Tạo notification document
      await createNotificationDocument(ownerId, 'room_rejected', title, body, {
        roomId: roomId,
        roomTitle: after.title || '',
        reason: reason,
      });

      // Gửi push notification
      await sendNotificationToUser(ownerId, {
        title: title,
        body: body,
        data: {
          type: 'room_rejected',
          roomId: roomId,
          roomTitle: after.title || '',
          reason: reason,
        },
      });

      console.log(`Room ${roomId} rejected, notification sent to ${ownerId}`);
    }

    return null;
  });

/**
 * Trigger khi room price thay đổi
 * Firestore trigger: rooms/{roomId} - onUpdate
 * Chỉ gửi notification cho users đã lưu phòng vào favorites
 */
export const onRoomPriceChanged = functions.firestore
  .document('rooms/{roomId}')
  .onUpdate(async (change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const roomId = context.params.roomId;

    if (!before || !after) {
      console.log(`Room ${roomId}: Missing data, skipping`);
      return null;
    }

    const beforePrice = before.priceMillion;
    const afterPrice = after.priceMillion;

    // Chỉ xử lý khi price thay đổi và room đang active
    if (beforePrice === afterPrice || after.status !== 'active') {
      return null;
    }

    // Tìm tất cả users đã lưu phòng này vào favorites
    try {
      const favoritesSnapshot = await db
        .collection('favorites')
        .where('roomId', '==', roomId)
        .get();

      if (favoritesSnapshot.empty) {
        console.log(`No favorites found for room ${roomId}`);
        return null;
      }

      const priceChange = afterPrice - beforePrice;
      const priceChangePercent = ((priceChange / beforePrice) * 100).toFixed(1);
      const isDecrease = priceChange < 0;

      const title = isDecrease 
        ? 'Giá phòng yêu thích giảm! 🎉'
        : 'Giá phòng yêu thích thay đổi';
      const body = isDecrease
        ? `Phòng "${after.title || ''}" giảm từ ${beforePrice.toFixed(1)} triệu xuống ${afterPrice.toFixed(1)} triệu/tháng (${Math.abs(parseFloat(priceChangePercent))}%)`
        : `Phòng "${after.title || ''}" có giá mới: ${afterPrice.toFixed(1)} triệu/tháng`;

      // Gửi notification cho từng user đã lưu
      const promises = favoritesSnapshot.docs.map(async (doc: admin.firestore.QueryDocumentSnapshot) => {
        const favorite = doc.data();
        const userId = favorite.userId;

        if (!userId) return;

        // Tạo notification document
        await createNotificationDocument(userId, 'room_price_changed', title, body, {
          roomId: roomId,
          roomTitle: after.title || '',
          oldPrice: beforePrice.toString(),
          newPrice: afterPrice.toString(),
          changePercent: priceChangePercent,
        });

        // Gửi push notification
        await sendNotificationToUser(userId, {
          title: title,
          body: body,
          data: {
            type: 'room_price_changed',
            roomId: roomId,
            roomTitle: after.title || '',
            oldPrice: beforePrice.toString(),
            newPrice: afterPrice.toString(),
            changePercent: priceChangePercent,
          },
        });
      });

      await Promise.all(promises);

      // Cập nhật savedPrice trong favorites để track lần sau
      const updatePromises = favoritesSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => {
        return doc.ref.update({
          savedPrice: afterPrice,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await Promise.all(updatePromises);

      console.log(`Price change notification sent to ${favoritesSnapshot.size} users for room ${roomId}`);
    } catch (error) {
      console.error(`Error sending price change notification:`, error);
    }

    return null;
  });

/**
 * Trigger khi có tin nhắn mới
 * Firestore trigger: conversations/{convId}/messages/{msgId} - onCreate
 */
export const onNewMessage = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snap: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    const message = snap.data();
    const conversationId = context.params.convId;

    if (!message) {
      console.log(`Message ${context.params.msgId}: Missing data, skipping`);
      return null;
    }

    const senderId = message.senderId;

    if (!senderId || !message.content) {
      return null;
    }

    try {
      // Lấy thông tin conversation
      const conversationDoc = await db
        .collection('conversations')
        .doc(conversationId)
        .get();

      if (!conversationDoc.exists) {
        console.log(`Conversation ${conversationId} not found`);
        return null;
      }

      const conversation = conversationDoc.data();
      if (!conversation) return null;

      const participantIds = conversation.participantIds || [];
      
      // Tìm user nhận tin nhắn (người không phải sender)
      const recipientId = participantIds.find((id: string) => id !== senderId);

      if (!recipientId) {
        console.log(`No recipient found for conversation ${conversationId}`);
        return null;
      }

      // Lấy thông tin sender
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.data()?.displayName || senderDoc.data()?.name || 'Người dùng';

      // Lấy thông tin room nếu có
      const roomTitle = conversation.roomTitle || 'Phòng trọ';
      const roomId = conversation.roomId || '';

      // Preview tin nhắn (giới hạn 100 ký tự)
      const messagePreview = message.content.length > 100
        ? message.content.substring(0, 100) + '...'
        : message.content;

      const title = `${senderName}`;
      const body = messagePreview;

      // Tạo notification document
      await createNotificationDocument(recipientId, 'new_message', title, body, {
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        roomId: roomId,
        roomTitle: roomTitle,
        messagePreview: messagePreview,
      });

      // Gửi push notification
      await sendNotificationToUser(recipientId, {
        title: title,
        body: body,
        data: {
          type: 'new_message',
          conversationId: conversationId,
          senderId: senderId,
          senderName: senderName,
          roomId: roomId,
          roomTitle: roomTitle,
        },
      });

      // Cập nhật unreadCount trong conversation
      await conversationDoc.ref.update({
        unreadCount: admin.firestore.FieldValue.increment(1),
        lastMessage: messagePreview,
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`New message notification sent to ${recipientId} for conversation ${conversationId}`);
    } catch (error) {
      console.error(`Error sending new message notification:`, error);
    }

    return null;
  });

/**
 * HTTP function để test gửi notification (optional, chỉ dùng cho testing)
 */
export const testNotification = functions.https.onRequest(async (req: functions.https.Request, res: functions.Response) => {
  const { userId, title, body, type, data } = req.body;

  if (!userId || !title || !body) {
    res.status(400).json({ error: 'Missing required fields: userId, title, body' });
    return;
  }

  try {
    await sendNotificationToUser(userId, {
      title: title,
      body: body,
      data: data || { type: type || 'test' },
    });

    res.json({ success: true, message: 'Notification sent' });
  } catch (error) {
    console.error('Error sending test notification:', error);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

