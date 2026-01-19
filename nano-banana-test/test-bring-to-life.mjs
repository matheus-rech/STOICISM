/**
 * Test the "bringToLife" pattern with gemini-3-pro-preview
 */
import { GoogleGenAI } from "@google/genai";

const GEMINI_MODEL = 'gemini-3-pro-preview';
const apiKey = process.env.GOOGLE_API_KEY;

console.log('Testing bringToLife pattern with ' + GEMINI_MODEL + '...\n');

const ai = new GoogleGenAI({ apiKey });

const SYSTEM_INSTRUCTION = `You are an expert AI Engineer and Product Designer specializing in "bringing artifacts to life".
Your goal is to take a user's description and generate a fully functional, interactive, single-page HTML/JS/CSS application.

CORE DIRECTIVES:
1. Make it Interactive: The output MUST NOT be static. It needs buttons, sliders, or dynamic visualizations.
2. Self-Contained: Output must be a single HTML file with embedded CSS (<style>) and JavaScript (<script>).
3. Modern Design: Use clean, modern UI with good typography and spacing.

RESPONSE FORMAT:
Return ONLY the raw HTML code. Do not wrap it in markdown code blocks. Start immediately with <!DOCTYPE html>.`;

async function testBringToLife() {
  try {
    // Test 1: Simple text prompt (no image)
    console.log('1️⃣ Testing text-to-code generation...');

    const response = await ai.models.generateContent({
      model: GEMINI_MODEL,
      contents: {
        parts: [{ text: "Create a simple counter app with increment and decrement buttons. Make it look modern with a nice gradient background." }]
      },
      config: {
        systemInstruction: SYSTEM_INSTRUCTION,
        temperature: 0.5,
      },
    });

    let html = response.text || "";

    // Clean up markdown fences if present
    html = html.replace(/^```html\s*/, '').replace(/^```\s*/, '').replace(/```$/, '').trim();

    if (html.startsWith('<!DOCTYPE') || html.startsWith('<html') || html.startsWith('<head')) {
      console.log('   ✅ Generated valid HTML!');
      console.log('   📄 Output length:', html.length, 'chars');
      console.log('   🔍 Preview (first 200 chars):');
      console.log('   ', html.substring(0, 200).replace(/\n/g, '\n   '));

      // Save the output
      const fs = await import('fs');
      fs.writeFileSync('generated-app.html', html);
      console.log('\n   💾 Saved to generated-app.html - open it in a browser!');
    } else {
      console.log('   ⚠️ Response might not be valid HTML');
      console.log('   Response preview:', html.substring(0, 300));
    }

    console.log('\n✅ gemini-3-pro-preview is working for code generation!');

  } catch (error) {
    console.error('❌ Error:', error.message);

    if (error.message.includes('404') || error.message.includes('not found')) {
      console.log('\n💡 Model might not be available. Trying alternative models...');
      await testAlternativeModels();
    }
  }
}

async function testAlternativeModels() {
  const models = [
    'gemini-2.0-flash',
    'gemini-2.0-pro-exp',
    'gemini-1.5-pro',
    'gemini-2.5-pro-preview-05-06'
  ];

  for (const model of models) {
    try {
      console.log('\n   Trying ' + model + '...');
      const response = await ai.models.generateContent({
        model: model,
        contents: {
          parts: [{ text: "Say OK if you can generate code" }]
        }
      });
      console.log('   ✅ ' + model + ' works:', response.text.substring(0, 50));
    } catch (e) {
      console.log('   ❌ ' + model + ' failed:', e.message.substring(0, 50));
    }
  }
}

testBringToLife();
