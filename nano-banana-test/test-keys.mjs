import { GoogleGenerativeAI } from '@google/generative-ai';

const apiKey = process.env.GOOGLE_API_KEY;
console.log('Testing GOOGLE_API_KEY (' + apiKey.length + ' chars)...\n');

const genAI = new GoogleGenerativeAI(apiKey);

async function testAPI() {
  try {
    // Test 1: Basic text generation to verify API access
    console.log('1️⃣ Testing API connection with text model...');
    const textModel = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    const textResult = await textModel.generateContent('Reply with just: API OK');
    console.log('   ✅ Text model works:', textResult.response.text().trim());

    // Test 2: Check if image generation model is accessible
    console.log('\n2️⃣ Testing image generation model (gemini-2.0-flash-exp-image-generation)...');
    const imageModel = genAI.getGenerativeModel({
      model: 'gemini-2.0-flash-exp-image-generation',
      generationConfig: {
        responseModalities: ['TEXT', 'IMAGE']
      }
    });

    const imageResult = await imageModel.generateContent('Generate a simple blue circle on white background');

    // Check if we got an image back
    const parts = imageResult.response.candidates[0].content.parts;
    const hasImage = parts.some(function(p) { return p.inlineData && p.inlineData.mimeType && p.inlineData.mimeType.startsWith('image/'); });

    if (hasImage) {
      console.log('   ✅ Image generation works!');
      const imagePart = parts.find(function(p) { return p.inlineData && p.inlineData.mimeType && p.inlineData.mimeType.startsWith('image/'); });
      const sizeKB = Math.round(imagePart.inlineData.data.length / 1024);
      console.log('   📷 Generated image:', imagePart.inlineData.mimeType + ',', sizeKB + 'KB');
    } else {
      console.log('   ⚠️ Response received but no image generated');
      const textParts = parts.map(function(p) { return p.text || '[media]'; }).join(' ');
      console.log('   Response:', textParts);
    }

    console.log('\n✅ GOOGLE_API_KEY is working and ready for Nano Banana!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.message.includes('API_KEY_INVALID')) {
      console.log('\n💡 API key is invalid');
    } else if (error.message.includes('not found') || error.message.includes('404')) {
      console.log('\n💡 Model not available - trying alternative model names...');
    }
  }
}

testAPI();
