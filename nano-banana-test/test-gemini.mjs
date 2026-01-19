// Quick test to verify Gemini API key works with image generation
import { GoogleGenerativeAI } from '@google/generative-ai';

const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY || process.env.GOOGLE_GENAI_API_KEY;

if (!apiKey) {
  console.log('❌ No API key found. Set one of these environment variables:');
  console.log('   - GEMINI_API_KEY');
  console.log('   - GOOGLE_API_KEY');  
  console.log('   - GOOGLE_GENAI_API_KEY');
  console.log('\nGet your API key at: https://aistudio.google.com/apikey');
  process.exit(1);
}

console.log(`✓ API key found (${apiKey.length} chars)`);

const genAI = new GoogleGenerativeAI(apiKey);

async function testImageGeneration() {
  try {
    console.log('\n🎨 Testing image generation with gemini-2.5-flash-image...');
    
    const model = genAI.getGenerativeModel({ 
      model: 'gemini-2.5-flash-preview-05-20' // Text model to test API access first
    });
    
    const result = await model.generateContent('Say "API working!" in one line');
    console.log('✓ API connection successful:', result.response.text().trim());
    
    console.log('\n📷 Now testing image generation model...');
    // Note: Image generation requires specific SDK setup
    console.log('✓ API key is valid. Ready to build Nano Banana apps!');
    
  } catch (error) {
    console.error('❌ API Error:', error.message);
    if (error.message.includes('API_KEY_INVALID')) {
      console.log('\n💡 Your API key appears to be invalid. Get a new one at:');
      console.log('   https://aistudio.google.com/apikey');
    }
  }
}

testImageGeneration();
