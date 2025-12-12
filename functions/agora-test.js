// agora-test.js - Simple Agora token test
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

// REPLACE THESE WITH YOUR ACTUAL CREDENTIALS
const APP_ID = 'YOUR_APP_ID_HERE';
const APP_CERT = 'YOUR_APP_CERTIFICATE_HERE';

console.log('Testing Agora Token Generation...\n');

// Check if credentials are still placeholders
if (APP_ID.includes('YOUR_APP_ID') || APP_CERT.includes('YOUR_APP_CERT')) {
  console.error('ERROR: Please replace APP_ID and APP_CERT with your actual credentials');
  console.error('Get them from: https://console.agora.io/');
  process.exit(1);
}

try {
  // Generate a test token
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERT,
    'dating-app-test-channel',
    1001,
    RtcRole.PUBLISHER,
    Math.floor(Date.now() / 1000) + 3600 // 1 hour expiry
  );

  console.log('✅ SUCCESS! Token generated.');
  console.log('App ID:', APP_ID);
  console.log('Token:', token);
  console.log('\nFor Flutter config, use:');
  console.log(`static const String appId = '${APP_ID}';`);
} catch (error) {
  console.error('❌ ERROR:', error.message);
}
