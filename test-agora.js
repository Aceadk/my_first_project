// Quick test without file dependencies
const { RtcTokenBuilder, RtcRole } = require('./functions/node_modules/agora-access-token');

// PUT YOUR CREDENTIALS HERE
const APP_ID = '3cb5440131af4513a46b6a8135afc7a7';
const APP_CERT = '2b13eeb301944b2a8e9349688b5f8063';

if (APP_ID === 'YOUR_APP_ID') {
  console.log('❌ Please edit test-agora.js and add your credentials');
  console.log('Get them from: https://console.agora.io/');
  process.exit(1);
}

const token = RtcTokenBuilder.buildTokenWithUid(
  APP_ID,
  APP_CERT,
  'test-channel',
  123,
  RtcRole.PUBLISHER,
  Math.floor(Date.now() / 1000) + 3600
);

console.log('✅ Success!');
console.log('App ID:', APP_ID);
console.log('Token:', token.substring(0, 50) + '...');
console.log('\nAdd to AgoraConfig.dart:');
console.log(`static const String appId = '${APP_ID}';`);
