import os
import requests
from google import genai
from google.genai import types

# Configurações de credenciais
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
ELEVENLABS_API_KEY = os.environ.get("ELEVENLABS_API_KEY")

# Inicialização do Cliente Gemini
client = genai.Client(api_key=GEMINI_API_KEY)

# Diretriz de Personalidade da E.V.A.
EVA_SYSTEM_INSTRUCTION = """
Você é a E.V.A. (Entidade Virtual Avançada), assistente pessoal e parceira acadêmica de Evandro.
Sua personalidade é extremamente analítica, leal, eficiente e polida, inspirada em sistemas como F.R.I.D.A.Y. e J.A.R.V.I.S.

Diretrizes Operacionais:
1. Trate o usuário sempre por 'chefe'.
2. Forneça respostas cirúrgicas, bem estruturadas e sem enrolação.
3. Atue como especialista de alto nível em:
   - Teologia, Psicanálise e Neurociência (auxiliando em estudos e artigos).
   - Inteligência Artificial, Agentes Autônomos e Tecnologia na Saúde.
   - Informações locais de Macaé e Rio de Janeiro, além de cenário político atualizado.
4. Responda em Português do Brasil com tom tático e elegante.
"""

def processar_diretriz(prompt_usuario, contexto_estudo=""):
    """
    Processa a diretriz do usuário utilizando o modelo Gemini 3.6 Flash
    com varredura na web ativada.
    """
    prompt_completo = prompt_usuario
    if contexto_estudo:
        prompt_completo += f"\n\n[CONTEXTO DE ESTUDO/DOCUMENTOS]:\n{contexto_estudo}"

    try:
        response = client.models.generate_content(
            model="gemini-3.6-flash",
            contents=prompt_completo,
            config=types.GenerateContentConfig(
                system_instruction=EVA_SYSTEM_INSTRUCTION,
                temperature=0.6,
                tools=[{"google_search": {}}]  # Varredura Web ativa
            )
        )
        return response.text
    except Exception as e:
        return f"E.V.A. > Falha no processamento do núcleo: {e}"

def gerar_audio_resposta(texto_resposta, arquivo_saida="resposta_eva.mp3"):
    """
    Converte a resposta da E.V.A. em áudio de alta fidelidade via ElevenLabs.
    """
    if not ELEVENLABS_API_KEY:
        print("[AVISO] Chave ElevenLabs não configurada. Áudio ignorado.")
        return None

    url = "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM"
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "json",
        "xi-api-key": ELEVENLABS_API_KEY
    }
    data = {
        "text": texto_resposta,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75
        }
    }

    res = requests.post(url, json=data, headers=headers)
    if res.status_code == 200:
        with open(arquivo_saida, "wb") as f:
            f.write(res.content)
        return arquivo_saida
    else:
        print(f"[ERRO ELEVENLABS]: {res.status_code}")
        return None

if __name__ == "__main__":
    # Teste de execução rápida local
    print("=== NÚCLEO E.V.A. INICIALIZADO ===")
    diretriz = "E.V.A., qual é o relatório rápido do tempo em Macaé e os últimos avanços em agentes de IA na saúde?"
    
    print(f"\n[CHEFE]: {diretriz}")
    resposta = processar_diretriz(diretriz)
    print(f"\n[E.V.A.]:\n{resposta}")
