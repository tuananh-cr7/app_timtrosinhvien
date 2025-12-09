// Script: tools/set_admin_claim.js
// Cách dùng:
//   1) Đặt file này trong thư mục tools/.
//   2) Cài firebase-admin:  npm install firebase-admin
//   3) Đặt biến môi trường GOOGLE_APPLICATION_CREDENTIALS trỏ tới service account JSON,
//      hoặc sửa initApp dùng service account trực tiếp.
//   4) Chạy:  node tools/set_admin_claim.js <UID> [role]
//      Mặc định role = 'admin', claim admin=true.

const admin = require('firebase-admin');

// Nếu bạn đã set GOOGLE_APPLICATION_CREDENTIALS bên ngoài, initApp() sẽ tự dùng.
// Hoặc dùng service account JSON trực tiếp (mở comment dưới và sửa đường dẫn):
// const serviceAccount = require('./service-account.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    console.error('Usage: node tools/set_admin_claim.js <UID> [role]');
    process.exit(1);
  }
  const uid = args[0];
  const role = args[1] || 'admin';
  const claims = { admin: true, role };

  try {
    await admin.auth().setCustomUserClaims(uid, claims);
    console.log(`✅ Set claims for UID=${uid}:`, claims);
    console.log('Đăng nhập lại tài khoản để token có claim mới.');
    process.exit(0);
  } catch (e) {
    console.error('❌ Error:', e);
    process.exit(1);
  }
}

main();


