'use server'

/**
 * Server Action for BringToLife in Next.js App Router
 *
 * Usage in client component:
 *   const result = await generateApp(prompt, imageBase64, mimeType)
 *   setHtml(result.html)
 */
import { GoogleGenAI } from "@google/genai";

const GEMINI_MODEL = 'gemini-3-pro-preview';

const SYSTEM_INSTRUCTION = `You are an expert AI Engineer and Product Designer.
Generate a fully functional, interactive, single-page HTML/JS/CSS application.

RULES:
1. NO external images. Use CSS shapes, SVGs, or Emojis instead.
2. Make it interactive with buttons, animations, or dynamic elements.
3. Self-contained: single HTML with embedded <style> and <script>.
4. Modern design with good typography and spacing.

Return ONLY raw HTML starting with <!DOCTYPE html>. No markdown fences.`;

export interface GenerateAppResult {
  html: string;
  success: boolean;
  error?: string;
}

export async function generateApp(
  prompt: string,
  imageBase64?: string,
  mimeType?: string
): Promise<GenerateAppResult> {
  const apiKey = process.env.GOOGLE_API_KEY;

  if (!apiKey) {
    return { html: '', success: false, error: 'API key not configured' };
  }

  const ai = new GoogleGenAI({ apiKey });

  try {
    const parts: any[] = [];

    const finalPrompt = imageBase64
      ? `Analyze this image and build an interactive web app. ${prompt || ''}`
      : prompt;

    parts.push({ text: finalPrompt });

    if (imageBase64 && mimeType) {
      parts.push({
        inlineData: { data: imageBase64, mimeType }
      });
    }

    const response = await ai.models.generateContent({
      model: GEMINI_MODEL,
      contents: { parts },
      config: {
        systemInstruction: SYSTEM_INSTRUCTION,
        temperature: 0.5,
      },
    });

    let html = response.text || '';
    html = html.replace(/^```html\s*/i, '').replace(/^```\s*/, '').replace(/```$/, '').trim();

    return { html, success: true };

  } catch (error: any) {
    console.error('BringToLife error:', error);
    return { html: '', success: false, error: error.message };
  }
}

/**
 * Quick presets for common app types
 */
export async function generateCounterApp() {
  return generateApp('Create a modern counter app with increment, decrement, and reset buttons.');
}

export async function generateTodoApp() {
  return generateApp('Create a todo list app with add, complete, delete. Use local storage.');
}

export async function generateTimerApp() {
  return generateApp('Create a Pomodoro timer with start, pause, reset, and sound notifications.');
}

export async function generateFromSketch(imageBase64: string, mimeType: string) {
  return generateApp('Turn this sketch into a polished, modern UI.', imageBase64, mimeType);
}
