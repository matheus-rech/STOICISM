// Test OpenRouter API key
const apiKey = process.env.OPENROUTER_API_KEY;
console.log('Testing OPENROUTER_API_KEY (' + apiKey.length + ' chars)...\n');

async function testOpenRouter() {
  try {
    console.log('1️⃣ Testing OpenRouter API connection...');

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + apiKey,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://localhost:3000',
        'X-Title': 'Nano Banana Test'
      },
      body: JSON.stringify({
        model: 'google/gemini-2.0-flash-exp:free',
        messages: [{ role: 'user', content: 'Reply with just: API OK' }],
        max_tokens: 10
      })
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error('HTTP ' + response.status + ': ' + error);
    }

    const data = await response.json();
    console.log('   ✅ OpenRouter works:', data.choices[0].message.content.trim());

    console.log('\n2️⃣ Checking available image models...');
    const modelsResponse = await fetch('https://openrouter.ai/api/v1/models', {
      headers: { 'Authorization': 'Bearer ' + apiKey }
    });
    const models = await modelsResponse.json();
    const imageModels = models.data.filter(function(m) {
      return m.id.includes('image') || m.id.includes('flux') || m.id.includes('dall');
    });

    if (imageModels.length > 0) {
      console.log('   Found ' + imageModels.length + ' image-related models:');
      imageModels.slice(0, 5).forEach(function(m) {
        console.log('   - ' + m.id);
      });
    } else {
      console.log('   ⚠️ No dedicated image generation models found via OpenRouter');
    }

    console.log('\n✅ OPENROUTER_API_KEY is working!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testOpenRouter();
