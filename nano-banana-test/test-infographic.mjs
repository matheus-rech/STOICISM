/**
 * Test the infographic generation pattern with gemini-2.5-flash-image
 */
import { GoogleGenAI } from "@google/genai";
import * as fs from 'fs';

const apiKey = process.env.GOOGLE_API_KEY;
console.log('Testing Infographic Generation Pattern...\n');

const ai = new GoogleGenAI({ apiKey });

async function testInfographicGeneration() {
  const query = "How neurons communicate in the brain";

  const prompt = `
Create an explanation-driven, sparse-text, rich image about: "${query}"

IMPORTANT STYLE GUIDELINES:
- Create a diagram or infographic but with minimal text - keep it visually focused
- Focus on compelling imagery, scenes, objects, or artistic representations
- Use dramatic lighting, rich colors, and cinematic composition
- The image should be atmospheric and immersive

Generate a stunning visual that captures the essence of the topic through imagery, not words.`;

  try {
    console.log('1️⃣ Generating infographic with gemini-2.5-flash-image...');
    console.log('   Topic: "' + query + '"');

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash-image',
      contents: prompt,
      config: {
        imageConfig: {
          aspectRatio: '16:9',
        },
      },
    });

    // Extract image
    let imageBase64;
    let mimeType = 'image/png';

    const parts = response.candidates?.[0]?.content?.parts;

    if (parts) {
      for (const part of parts) {
        if (part.inlineData) {
          imageBase64 = part.inlineData.data;
          mimeType = part.inlineData.mimeType || 'image/png';
          break;
        }
      }
    }

    if (!imageBase64) {
      throw new Error("No image generated");
    }

    console.log('   ✅ Image generated!');
    console.log('   📷 Type:', mimeType);
    console.log('   📏 Size:', Math.round(imageBase64.length / 1024), 'KB (base64)');

    // Save the image
    const buffer = Buffer.from(imageBase64, 'base64');
    fs.writeFileSync('generated-infographic.png', buffer);
    console.log('   💾 Saved to generated-infographic.png');

    // Step 2: Analyze the image
    console.log('\n2️⃣ Analyzing image regions with gemini-2.5-flash...');

    const analysisPrompt = `
Analyze this infographic about "${query}" and identify interesting regions.

Identify 3-4 distinct visual areas. For each area, provide:
- "label": Name (1-4 words)
- "description": Brief explanation (15-25 words)
- "icon": A single relevant emoji
- "bounds": { "x": number (0-100), "y": number (0-100), "width": number, "height": number }

Return ONLY valid JSON:
{ "segments": [ { "label", "description", "icon", "bounds" } ] }`;

    const analysisResponse = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        {
          role: 'user',
          parts: [
            { text: analysisPrompt },
            { inlineData: { mimeType, data: imageBase64 } }
          ]
        }
      ]
    });

    let analysisText = analysisResponse.text || '';
    analysisText = analysisText.replace(/```json/g, '').replace(/```/g, '').trim();

    try {
      const analysis = JSON.parse(analysisText);
      console.log('   ✅ Analysis complete!');
      console.log('   Found', analysis.segments.length, 'regions:');
      analysis.segments.forEach(function(seg, i) {
        console.log('   ' + (i + 1) + '. ' + seg.icon + ' ' + seg.label + ': ' + seg.description.substring(0, 50) + '...');
      });

      // Save analysis
      fs.writeFileSync('infographic-analysis.json', JSON.stringify(analysis, null, 2));
      console.log('   💾 Saved to infographic-analysis.json');
    } catch (e) {
      console.log('   ⚠️ Could not parse analysis JSON');
      console.log('   Raw response:', analysisText.substring(0, 200));
    }

    console.log('\n✅ Infographic pipeline test complete!');

  } catch (error) {
    console.error('❌ Error:', error.message);

    if (error.message.includes('not found') || error.message.includes('404')) {
      console.log('\n💡 gemini-2.5-flash-image might need different access. Testing alternatives...');
      await testAlternativeImageModels();
    }
  }
}

async function testAlternativeImageModels() {
  const imageModels = [
    'gemini-2.0-flash-exp-image-generation',
    'imagegeneration@002',
  ];

  for (const model of imageModels) {
    try {
      console.log('\n   Trying ' + model + '...');
      const response = await ai.models.generateContent({
        model: model,
        contents: 'Generate a simple blue circle',
        config: { imageConfig: { aspectRatio: '1:1' } }
      });
      const parts = response.candidates?.[0]?.content?.parts;
      const hasImage = parts?.some(function(p) { return p.inlineData; });
      if (hasImage) {
        console.log('   ✅ ' + model + ' works for image generation!');
      }
    } catch (e) {
      console.log('   ❌ ' + model + ':', e.message.substring(0, 60));
    }
  }
}

testInfographicGeneration();
