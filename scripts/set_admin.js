/**
 * Script cục bộ để cấp / gỡ quyền admin (hoặc super_admin) cho user
 * Không cần Cloud Functions, chạy bằng Node với service account.
 *
 * Cách dùng:
 *   node scripts/set_admin.js <UID> admin       # cấp role admin
 *   node scripts/set_admin.js <UID> super_admin # cấp role super_admin
 *   node scripts/set_admin.js <UID> none        # gỡ quyền (về user)
 *
 * Yêu cầu:
 * - Có file service account JSON (ví dụ đặt tại scripts/service-account.json)
 * - Đã cài node_modules firebase-admin: npm install firebase-admin
 */

const path = require('path');
const admin = require('firebase-admin');

// Sửa lại đường dẫn nếu bạn đặt file khác tên/vị trí
const serviceAccount = require(path.join(__dirname, 'service-account.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const uid = process.argv[2];
const roleArg = (process.argv[3] || '').toLowerCase();

if (!uid || !roleArg || !['admin', 'super_admin', 'none'].includes(roleArg)) {
  console.error('Usage: node scripts/set_admin.js <UID> <admin|super_admin|none>');
  process.exit(1);
}

const claims =
  roleArg === 'none'
    ? {}
    : { role: roleArg }; // giữ đơn giản: role: 'admin' hoặc 'super_admin'

(async () => {
  try {
    await admin.auth().setCustomUserClaims(uid, claims);
    // Cập nhật Firestore để UI hiển thị role dễ hơn
    const db = admin.firestore();
    await db.collection('users').doc(uid).set(
      { role: roleArg === 'none' ? 'user' : roleArg },
      { merge: true }
    );
    console.log(`✅ Done. uid=${uid}, role=${roleArg === 'none' ? 'user' : roleArg}`);
    console.log('👉 Người dùng cần đăng nhập lại để token cập nhật claims.');
  } catch (err) {
    console.error('❌ Error:', err);
    process.exit(1);
  }
  process.exit(0);
})();

