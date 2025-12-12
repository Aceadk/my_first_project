// functions/src/simpleTokenGenerator.js
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
// Use your actual credentials here
const APP_ID = '3cb5440131af4513a46b6a8135afc7a7';
const APP_CERTIFICATE = '2b13eeb301944b2a8e9349688b5f8063';

function generateTestToken(channelName, userId = 0) {
  // Validate inputs
  if (!APP_ID || APP_ID === 'abc123def456ghi789jkl012') {
    throw new Error('APP_ID is not set. Get it from Agora Console and replace in this file.');
  }
  
  if (!APP_CERTIFICATE || APP_CERTIFICATE === 'xyz789abc456def123ghi890') {
    throw new Error('APP_CERTIFICATE is not set. Get it from Agora Console and replace in this file.');
  }
  
  if (!channelName) {
    throw new Error('channelName is required');
  }
  
  // Token valid for 1 hour
  const expirationTimeInSeconds = 3600;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
  
  // Build token with uid
  const token = RtcTokenBuilder.buildTokenWithUid(
    APP_ID,
    APP_CERTIFICATE,
    channelName,
    userId,
    RtcRole.PUBLISHER,
    privilegeExpiredTs
  );
  
  return {
    token,
    appId: APP_ID,
    channelName,
    uid: userId,
    expiration: privilegeExpiredTs,
    generatedAt: new Date().toISOString()
  };
}

// For testing - run directly with: node src/simpleTokenGenerator.js
if (require.main === module) {
  try {
    console.log('🔧 Testing Agora Token Generator...\n');
    
    // Test with a sample channel
    const testToken = generateTestToken('test-dating-call-123', 1001);
    
    console.log('✅ Token generated successfully!');
    console.log('📱 App ID:', testToken.appId);
    console.log('🔑 Token (first 30 chars):', testToken.token.substring(0, 30) + '...');
    console.log('📺 Channel:', testToken.channelName);
    console.log('👤 User ID:', testToken.uid);
    console.log('⏰ Expires at:', new Date(testToken.expiration * 1000).toLocaleString());
    console.log('🕒 Generated at:', testToken.generatedAt);
    
    console.log('\n📋 Copy these to test in your Flutter app:');
    console.log('App ID:', testToken.appId);
    console.log('Token:', testToken.token);
    console.log('Channel:', testToken.channelName);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('\n⚠️  Make sure to:');
    console.log('1. Get your APP_ID from Agora Console');
    console.log('2. Get your APP_CERTIFICATE from Agora Console');
    console.log('3. Replace the placeholder values in this file');
    console.log('4. Run: npm install agora-access-token');
  }
}

module.exports = { generateTestToken };
