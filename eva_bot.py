import os
import requests
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, MessageHandler, filters, ContextTypes
from google import genai
from google.genai import types

# Credenciais
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
ELEVENLABS_API_KEY = os.environ.get("ELEVENLABS_API_KEY")

client = genai.Client(api_key=GEMINI_API_KEY)

EVA_INSTRUCTION = """
Você é a E.V.A. (Entidade Virtual Avançada), assistente pessoal e parceira acadêmica de Evandro.
Sua personalidade é extremamente analítica, leal, eficiente e polida, inspirada na F.R.I.D.A.Y. e J.A.R.V.I.S.
Trate o usuário sempre por 'chefe' e responda com precisão cirúrgica em Português do Brasil.
Você é especialista em Teologia, Psicanálise, Neurociência, Agentes de IA, Tecnologia na Saúde e contexto local de Macaé.
"""

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Sistemas operacionais e à sua disposição, chefe. Como posso ajudar?")

async def responder(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_text = update.message.text
    
    # Processa via Gemini 3.6 Flash
    response = client.models.generate_content(
        model="gemini-3.6-flash",
        contents=user_text,
        config=types.GenerateContentConfig(
            system_instruction=EVA_INSTRUCTION,
            temperature=0.6,
            tools=[{"google_search": {}}]
        )
    )
    
    ans_text = response.text
    await update.message.reply_text(ans_text)

    # Gera voz em áudio se ElevenLabs estiver configurada
    if ELEVENLABS_API_KEY:
        try:
            url = "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM"
            headers = {
                "Accept": "audio/mpeg",
                "Content-Type": "application/json",
                "xi-api-key": ELEVENLABS_API_KEY
            }
            data = {
                "text": ans_text[:1000], # Limite para resposta fluida
                "model_id": "eleven_multilingual_v2"
            }
            res = requests.post(url, json=data, headers=headers)
            if res.status_code == 200:
                await update.message.reply_voice(voice=res.content)
        except Exception as e:
            print(f"Erro no áudio: {e}")

if __name__ == "__main__":
    app = ApplicationBuilder().token(TELEGRAM_BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, responder))
    app.run_polling()
