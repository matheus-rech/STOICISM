/**
 * BringToLife - Image/Sketch to Interactive Web App Generator
 *
 * Adapted from Nano Banana pattern for use in Next.js apps
 * Uses gemini-3-pro-preview for multimodal code generation
 */
import { GoogleGenAI, GenerateContentResponse } from "@google/genai";

// Configuration
const GEMINI_MODEL = 'gemini-3-pro-preview';

const SYSTEM_INSTRUCTION = `You are an expert AI Engineer and Product Designer specializing in "bringing artifacts to life".
Your goal is to take a user uploaded file—which might be a polished UI design, a messy napkin sketch, a photo of a whiteboard with jumbled notes, or a picture of a real-world object—and instantly generate a fully functional, interactive, single-page HTML/JS/CSS application.

CORE DIRECTIVES:
1. **Analyze & Abstract**: Look at the image.
    - **Sketches/Wireframes**: Detect buttons, inputs, and layout. Turn them into a modern, clean UI.
    - **Real-World Photos (Mundane Objects)**: If the user uploads a photo of a desk, a room, or a fruit bowl, **Gamify it** or build a **Utility** around it.
      - *Cluttered Desk* -> Create a "Clean Up" game where clicking items clears them.
      - *Fruit Bowl* -> A nutrition tracker or interactive inventory.
    - **Documents/Forms**: Create interactive wizards or dashboards.
    - **Medical/Scientific**: Create data visualization tools or educational apps.

2. **NO EXTERNAL IMAGES**:
    - **CRITICAL**: Do NOT use <img src="..."> with external URLs. They will fail.
    - **INSTEAD**: Use **CSS shapes**, **inline SVGs**, **Emojis**, or **CSS gradients** to visually represent elements.
    - If you see a "coffee cup" in the input, render a ☕ emoji or draw it with CSS.

3. **Make it Interactive**: The output MUST NOT be static. Include buttons, sliders, drag-and-drop, or dynamic visualizations.

4. **Self-Contained**: Output must be a single HTML file with embedded CSS (<style>) and JavaScript (<script>). Tailwind via CDN is allowed.

5. **Robust & Creative**: If the input is messy or ambiguous, generate a "best guess" creative interpretation. Never return an error. Build something fun and functional.

RESPONSE FORMAT:
Return ONLY the raw HTML code. Do not wrap it in markdown code blocks (\`\`\`html ... \`\`\`). Start immediately with <!DOCTYPE html>.`;

// Alternative system instructions for different use cases
export const SYSTEM_PRESETS = {
  default: SYSTEM_INSTRUCTION,

  medical: `You are a medical UI specialist. Create clean, accessible interfaces for healthcare applications.
Focus on: readability, high contrast, large touch targets, clear data visualization.
Include: form validation, error states, loading indicators.
Use a professional color palette (blues, greens, whites).
Return ONLY raw HTML code starting with <!DOCTYPE html>.`,

  stoic: `You are a stoic philosophy app designer. Create meditative, minimalist interfaces.
Focus on: calm aesthetics, serif typography, warm earth tones, generous whitespace.
Include: quote displays, reflection prompts, simple animations.
Return ONLY raw HTML code starting with <!DOCTYPE html>.`,

  dashboard: `You are a data dashboard specialist. Create powerful analytics interfaces.
Focus on: charts, metrics, KPIs, responsive grids, dark mode support.
Include: interactive filters, tooltips, export buttons.
Return ONLY raw HTML code starting with <!DOCTYPE html>.`,

  game: `You are a casual game designer. Create fun, addictive mini-games.
Focus on: engaging mechanics, score tracking, sound effects (use Web Audio), particle effects.
Include: start screen, game over screen, high score persistence.
Return ONLY raw HTML code starting with <!DOCTYPE html>.`,
};

export interface BringToLifeOptions {
  apiKey?: string;
  model?: string;
  temperature?: number;
  systemPreset?: keyof typeof SYSTEM_PRESETS;
  customSystemInstruction?: string;
}

export interface BringToLifeResult {
  html: string;
  model: string;
  tokensUsed?: number;
}

/**
 * Main function to convert image/text to interactive web app
 */
export async function bringToLife(
  prompt: string,
  fileBase64?: string,
  mimeType?: string,
  options: BringToLifeOptions = {}
): Promise<BringToLifeResult> {
  const apiKey = options.apiKey || process.env.GOOGLE_API_KEY || process.env.GEMINI_API_KEY;

  if (!apiKey) {
    throw new Error('API key required. Set GOOGLE_API_KEY or pass apiKey in options.');
  }

  const ai = new GoogleGenAI({ apiKey });
  const model = options.model || GEMINI_MODEL;
  const temperature = options.temperature ?? 0.5;

  // Select system instruction
  const systemInstruction = options.customSystemInstruction
    || SYSTEM_PRESETS[options.systemPreset || 'default'];

  // Build the prompt
  const parts: any[] = [];

  const finalPrompt = fileBase64
    ? `Analyze this image/document. Detect what functionality is implied.
       If it is a real-world object, gamify it or create a utility around it.
       Build a fully interactive web app.
       IMPORTANT: Do NOT use external image URLs. Recreate visuals using CSS, SVGs, or Emojis.
       Additional instructions: ${prompt || 'Make it beautiful and functional.'}`
    : prompt || "Create a demo app that showcases modern UI patterns.";

  parts.push({ text: finalPrompt });

  // Add image if provided
  if (fileBase64 && mimeType) {
    parts.push({
      inlineData: {
        data: fileBase64,
        mimeType: mimeType,
      },
    });
  }

  try {
    const response: GenerateContentResponse = await ai.models.generateContent({
      model: model,
      contents: { parts },
      config: {
        systemInstruction: systemInstruction,
        temperature: temperature,
      },
    });

    let html = response.text || "<!-- Failed to generate content -->";

    // Cleanup markdown fences if present
    html = html.replace(/^```html\s*/i, '').replace(/^```\s*/, '').replace(/```$/, '').trim();

    return {
      html,
      model,
      tokensUsed: response.usageMetadata?.totalTokenCount,
    };

  } catch (error: any) {
    console.error("BringToLife Generation Error:", error);
    throw new Error(`Generation failed: ${error.message}`);
  }
}

/**
 * Quick preset generators
 */
export const presets = {
  fromSketch: (imageBase64: string, mimeType: string) =>
    bringToLife("Turn this sketch into a polished, modern UI", imageBase64, mimeType),

  fromPhoto: (imageBase64: string, mimeType: string) =>
    bringToLife("Analyze this photo and create an interactive app inspired by it", imageBase64, mimeType),

  counterApp: () =>
    bringToLife("Create a modern counter app with increment/decrement buttons and a reset feature"),

  todoApp: () =>
    bringToLife("Create a beautiful todo app with add, complete, and delete functionality. Include local storage."),

  timerApp: () =>
    bringToLife("Create a Pomodoro timer with start, pause, reset. Include sound notifications."),

  quoteDisplay: () =>
    bringToLife("Create a stoic philosophy quote display with random quote button and elegant typography", undefined, undefined, {
      systemPreset: 'stoic'
    }),

  medicalForm: () =>
    bringToLife("Create a patient intake form with validation for name, date of birth, symptoms", undefined, undefined, {
      systemPreset: 'medical'
    }),
};

export default bringToLife;
