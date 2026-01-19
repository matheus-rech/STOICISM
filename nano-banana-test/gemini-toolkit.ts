/**
 * Gemini Toolkit - Comprehensive AI Generation for Next.js Apps
 *
 * Combines three powerful patterns:
 * 1. BringToLife: Image/Sketch → Interactive HTML App
 * 2. ImageGeneration: Text → Generated Image (Infographics)
 * 3. ImageAnalysis: Image → JSON annotations with regions
 *
 * All tested and working with standard Google API key.
 */

import { GoogleGenAI, GenerateContentResponse } from "@google/genai";

// ============================================================================
// CONFIGURATION
// ============================================================================

export const MODELS = {
  // For code generation (sketch-to-app, text-to-code)
  codeGen: 'gemini-3-pro-preview',

  // For image generation (infographics, art)
  imageGen: 'gemini-2.5-flash-image',

  // For image analysis and general tasks
  analysis: 'gemini-2.5-flash',

  // Alternative image generation (confirmed working)
  imageGenAlt: 'gemini-2.0-flash-exp-image-generation',
} as const;

// ============================================================================
// TYPES
// ============================================================================

export interface GeneratedImage {
  base64: string;
  mimeType: string;
  groundingUrls?: Array<{ title: string; uri: string }>;
}

export interface ImageSegment {
  label: string;
  description: string;
  icon: string;
  category?: 'concept' | 'data' | 'process' | 'structure';
  format?: 'compact' | 'stats' | 'detailed';
  stats?: Array<{ label: string; value: string }>;
  sourceUrl?: string;
  sourceName?: string;
  bounds: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

export interface AnalysisResult {
  segments: ImageSegment[];
}

export interface CodeGenerationResult {
  html: string;
  model: string;
  tokensUsed?: number;
}

export interface ToolkitConfig {
  apiKey?: string;
  defaultImageModel?: keyof typeof MODELS;
  defaultCodeModel?: keyof typeof MODELS;
}

// ============================================================================
// GEMINI TOOLKIT CLASS
// ============================================================================

export class GeminiToolkit {
  private ai: GoogleGenAI;
  private config: ToolkitConfig;

  constructor(config: ToolkitConfig = {}) {
    const apiKey = config.apiKey || process.env.GOOGLE_API_KEY || process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('API key required. Set GOOGLE_API_KEY or pass apiKey in config.');
    }
    this.ai = new GoogleGenAI({ apiKey });
    this.config = config;
  }

  // --------------------------------------------------------------------------
  // 1. IMAGE GENERATION (Text → Image)
  // --------------------------------------------------------------------------

  /**
   * Generate an infographic/visual from text
   */
  async generateImage(
    prompt: string,
    options: {
      aspectRatio?: '1:1' | '16:9' | '9:16' | '4:3' | '3:4';
      style?: 'infographic' | 'artistic' | 'diagram' | 'photo';
    } = {}
  ): Promise<GeneratedImage> {
    const { aspectRatio = '16:9', style = 'infographic' } = options;

    const stylePrompts = {
      infographic: 'Create a visually rich, sparse-text infographic with dramatic lighting and cinematic composition.',
      artistic: 'Create an atmospheric, artistic visualization with rich colors and compelling imagery.',
      diagram: 'Create a clear, educational diagram with visual representations of concepts.',
      photo: 'Create a photorealistic image capturing the essence of the topic.',
    };

    const fullPrompt = `${stylePrompts[style]}\n\nTopic: "${prompt}"\n\nIMPORTANT: Focus on imagery, not text. Make it visually stunning.`;

    const response = await this.ai.models.generateContent({
      model: MODELS.imageGen,
      contents: fullPrompt,
      config: {
        imageConfig: { aspectRatio },
      },
    });

    return this.extractImage(response);
  }

  /**
   * Generate an infographic with automatic region analysis
   */
  async generateInfographicWithAnalysis(
    topic: string,
    options?: { aspectRatio?: '1:1' | '16:9' | '9:16' }
  ): Promise<{ image: GeneratedImage; analysis: AnalysisResult }> {
    // Step 1: Generate the image
    const image = await this.generateImage(topic, options);

    // Step 2: Analyze the regions
    const analysis = await this.analyzeImage(image.base64, topic);

    return { image, analysis };
  }

  // --------------------------------------------------------------------------
  // 2. IMAGE ANALYSIS (Image → JSON)
  // --------------------------------------------------------------------------

  /**
   * Analyze an image and return annotated regions
   */
  async analyzeImage(
    imageBase64: string,
    context?: string,
    options: {
      mimeType?: string;
      segmentCount?: number;
      useGoogleSearch?: boolean;
    } = {}
  ): Promise<AnalysisResult> {
    const { mimeType = 'image/png', segmentCount = 4, useGoogleSearch = false } = options;

    const prompt = `
Analyze this image${context ? ` about "${context}"` : ''} and identify interesting regions to annotate.

Identify ${segmentCount} distinct visual areas. For each area, provide:
- "label": Name (1-4 words)
- "description": Rich explanation (20-40 words)
- "icon": A single relevant emoji
- "category": "concept" | "data" | "process" | "structure"
- "bounds": { "x": 0-100, "y": 0-100, "width": 0-100, "height": 0-100 }

Return ONLY valid JSON: { "segments": [ ... ] }`;

    const config: any = {};
    if (useGoogleSearch) {
      config.tools = [{ googleSearch: {} }];
    }

    const response = await this.ai.models.generateContent({
      model: MODELS.analysis,
      contents: [
        {
          role: 'user',
          parts: [
            { text: prompt },
            { inlineData: { mimeType, data: imageBase64 } },
          ],
        },
      ],
      config,
    });

    const text = response.text?.replace(/```json/g, '').replace(/```/g, '').trim() || '{}';
    return JSON.parse(text) as AnalysisResult;
  }

  // --------------------------------------------------------------------------
  // 3. CODE GENERATION (Image/Text → HTML)
  // --------------------------------------------------------------------------

  /**
   * Transform a sketch, wireframe, or description into a functional HTML app
   */
  async bringToLife(
    prompt: string,
    imageBase64?: string,
    mimeType?: string,
    options: {
      temperature?: number;
      preset?: 'default' | 'medical' | 'stoic' | 'dashboard' | 'game';
    } = {}
  ): Promise<CodeGenerationResult> {
    const { temperature = 0.5, preset = 'default' } = options;

    const systemInstructions: Record<string, string> = {
      default: `You are an expert UI developer. Generate interactive HTML/JS/CSS apps.
Rules: NO external images (use CSS/SVG/Emoji). Self-contained single HTML file. Make it interactive.
Return ONLY raw HTML starting with <!DOCTYPE html>.`,

      medical: `You are a medical UI specialist. Create clean, accessible healthcare interfaces.
High contrast, large touch targets, clear data visualization. Professional blue/green palette.
Return ONLY raw HTML starting with <!DOCTYPE html>.`,

      stoic: `You are a stoic philosophy app designer. Minimalist, meditative interfaces.
Calm aesthetics, serif typography, warm earth tones, generous whitespace.
Return ONLY raw HTML starting with <!DOCTYPE html>.`,

      dashboard: `You are a data dashboard specialist. Analytics interfaces with charts and metrics.
Dark mode support, interactive filters, responsive grids.
Return ONLY raw HTML starting with <!DOCTYPE html>.`,

      game: `You are a casual game designer. Fun, addictive mini-games.
Score tracking, particle effects, start/game over screens.
Return ONLY raw HTML starting with <!DOCTYPE html>.`,
    };

    const parts: any[] = [];

    const finalPrompt = imageBase64
      ? `Analyze this image and build an interactive web app. Use CSS/SVG/Emoji for visuals. ${prompt || ''}`
      : prompt;

    parts.push({ text: finalPrompt });

    if (imageBase64 && mimeType) {
      parts.push({ inlineData: { data: imageBase64, mimeType } });
    }

    const response = await this.ai.models.generateContent({
      model: MODELS.codeGen,
      contents: { parts },
      config: {
        systemInstruction: systemInstructions[preset],
        temperature,
      },
    });

    let html = response.text || '';
    html = html.replace(/^```html\s*/i, '').replace(/^```\s*/, '').replace(/```$/, '').trim();

    return {
      html,
      model: MODELS.codeGen,
      tokensUsed: response.usageMetadata?.totalTokenCount,
    };
  }

  // --------------------------------------------------------------------------
  // UTILITY METHODS
  // --------------------------------------------------------------------------

  private extractImage(response: GenerateContentResponse): GeneratedImage {
    const parts = response.candidates?.[0]?.content?.parts;

    if (parts) {
      for (const part of parts) {
        if (part.inlineData) {
          return {
            base64: part.inlineData.data!,
            mimeType: part.inlineData.mimeType || 'image/png',
          };
        }
      }
    }

    throw new Error('No image generated by the model');
  }

  /**
   * Quick text generation for simple tasks
   */
  async generate(prompt: string, model: string = MODELS.analysis): Promise<string> {
    const response = await this.ai.models.generateContent({
      model,
      contents: prompt,
    });
    return response.text || '';
  }
}

// ============================================================================
// CONVENIENCE FUNCTIONS (for use without class instantiation)
// ============================================================================

let _toolkit: GeminiToolkit | null = null;

function getToolkit(): GeminiToolkit {
  if (!_toolkit) {
    _toolkit = new GeminiToolkit();
  }
  return _toolkit;
}

export const generateImage = (prompt: string, options?: Parameters<GeminiToolkit['generateImage']>[1]) =>
  getToolkit().generateImage(prompt, options);

export const analyzeImage = (imageBase64: string, context?: string, options?: Parameters<GeminiToolkit['analyzeImage']>[2]) =>
  getToolkit().analyzeImage(imageBase64, context, options);

export const bringToLife = (prompt: string, imageBase64?: string, mimeType?: string, options?: Parameters<GeminiToolkit['bringToLife']>[3]) =>
  getToolkit().bringToLife(prompt, imageBase64, mimeType, options);

export const generateInfographicWithAnalysis = (topic: string, options?: Parameters<GeminiToolkit['generateInfographicWithAnalysis']>[1]) =>
  getToolkit().generateInfographicWithAnalysis(topic, options);

// ============================================================================
// PRESETS / QUICK GENERATORS
// ============================================================================

export const presets = {
  // Image generation presets
  neuronInfographic: () => generateImage('How neurons communicate in the brain'),
  galaxyArt: () => generateImage('A spiral galaxy with vibrant nebulae', { style: 'artistic' }),
  processDiagram: (topic: string) => generateImage(topic, { style: 'diagram' }),

  // Code generation presets
  counterApp: () => bringToLife('Create a modern counter app with increment, decrement, reset'),
  todoApp: () => bringToLife('Create a todo list with add, complete, delete, local storage'),
  timerApp: () => bringToLife('Create a Pomodoro timer with start, pause, reset, sound'),
  quoteApp: () => bringToLife('Create a stoic quote display with elegant typography', undefined, undefined, { preset: 'stoic' }),
  medicalForm: () => bringToLife('Create a patient intake form with validation', undefined, undefined, { preset: 'medical' }),

  // Combined presets
  interactiveInfographic: async (topic: string) => {
    const { image, analysis } = await generateInfographicWithAnalysis(topic);
    return { image, analysis };
  },
};

export default GeminiToolkit;
