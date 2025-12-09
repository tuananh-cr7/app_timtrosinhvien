const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Callable: chỉ admin hiện tại mới được cấp/thu hồi quyền admin cho user khác.
exports.setAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Chỉ admin mới được cấp/thu hồi quyền admin.'
    );
  }

  const targetUid = data.uid;
  const enable = data.enable === true;

  if (!targetUid || typeof targetUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'uid không hợp lệ');
  }

  // Gán/bỏ custom claim admin
  await admin.auth().setCustomUserClaims(targetUid, enable ? { admin: true } : {});

  // Cập nhật role trong Firestore (tham khảo UI hiển thị)
  await admin
    .firestore()
    .collection('users')
    .doc(targetUid)
    .set(
      {
        role: enable ? 'admin' : 'user',
        roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  return { ok: true, uid: targetUid, admin: enable };
});
