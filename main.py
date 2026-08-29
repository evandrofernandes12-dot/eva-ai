import streamlit as st
import streamlit.components.v1 as components
import os
from google import genai
from google.genai import types

st.set_page_config(
    page_title="E.V.A. Protocol",
    page_icon="⚡",
    layout="wide",
    initial_sidebar_state="expanded"
)

# INJEÇÃO DA INTERFACE HUD COMPLETA DE REVERÊNCIA NO BACKGROUND
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;800;900&family=Rajdhani:wght@500;600;700&display=swap');

    /* Fundo com o HUD Holográfico Completo */
    .stApp {
        background: url('https://images.wallpapersden.com/image/download/iron-man-hud_bGhlaGyUmZqaraWkpJRmZ2VlrWllZWU.jpg') no-repeat center center fixed !important;
        background-size: cover !important;
        color: #00f2ff !important;
        font-family: 'Rajdhani', sans-serif !important;
    }

    /* Camada de vidro escuro para dar leitura ao texto */
    .stApp::after {
        content: "";
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        background: rgba(2, 8, 20, 0.45);
        pointer-events: none;
        z-index: 0;
    }

    /* Barra Lateral Holográfica */
    [data-testid="stSidebar"] {
        background: rgba(3, 12, 28, 0.85) !important;
        backdrop-filter: blur(12px) !important;
        border-right: 2px solid rgba(0, 242, 255, 0.5) !important;
    }

    /* Título Personalizado E.V.A. com Efeito Neon HUD */
    .eva-title {
        font-family: 'Orbitron', sans-serif;
        color: #00f2ff;
        font-size: 2.8rem;
        font-weight: 900;
        letter-spacing: 8px;
        text-shadow: 0 0 15px #00f2ff, 0 0 30px rgba(0, 242, 255, 0.8);
        margin-bottom: 0px;
    }

    .eva-subtitle {
        font-family: 'Rajdhani', sans-serif;
        color: #f59e0b;
        font-size: 1.2rem;
        font-weight: 700;
        letter-spacing: 4px;
        text-transform: uppercase;
        margin-bottom: 20px;
        text-shadow: 0 0 10px rgba(245, 158, 11, 0.5);
    }

    /* Estilo de Vidro Futurista nas Mensagens */
    .stChatMessage {
        background: rgba(4, 20, 45, 0.8) !important;
        backdrop-filter: blur(10px) !important;
        border: 1px solid rgba(0, 242, 255, 0.6) !important;
        border-left: 4px solid #00f2ff !important;
        border-radius: 8px !important;
        box-shadow: 0 0 20px rgba(0, 242, 255, 0.2) !important;
        margin-bottom: 12px !important;
        z-index: 1;
    }

    .stTextInput > div > div > input {
        background-color: rgba(2, 12, 30, 0.95) !important;
        color: #00f2ff !important;
        border: 1.5px solid #00f2ff !important;
        border-radius: 6px !important;
        font-family: 'Orbitron', sans-serif !important;
        box-shadow: 0 0 20px rgba(0, 242, 255, 0.4) !important;
    }

    .hud-stat {
        background: rgba(0, 242, 255, 0.08);
        border: 1px solid rgba(0, 242, 255, 0.4);
        padding: 8px 12px;
        border-radius: 4px;
        font-family: 'Orbitron', sans-serif;
        font-size: 0.75rem;
        margin-bottom: 8px;
        color: #38bdf8;
    }
    </style>
""", unsafe_allow_html=True)

# Chaves de API
api_key = st.secrets.get("GEMINI_API_KEY", os.environ.get("GEMINI_API_KEY", ""))

eva_instruction = (
    "Você é a E.V.A. (Entidade Virtual Avançada), uma inteligência artificial inspirada nos sistemas J.A.R.V.I.S. e F.R.I.D.A.Y. "
    "Sua personalidade é extremamente analítica, polida, leal e eficiente. "
    "Responda sempre em Português do Brasil com precisão cirúrgica e termos operacionais, chamando o usuário de chefe."
)

# Painel Lateral
st.sidebar.markdown("<div class='eva-title' style='font-size: 1.8rem;'>E.V.A.</div>", unsafe_allow_html=True)
st.sidebar.markdown("<div class='eva-subtitle' style='font-size: 0.8rem;'>ENTIDADE VIRTUAL AVANÇADA</div>", unsafe_allow_html=True)

st.sidebar.markdown("""
    <div class='hud-stat'><b>SYSTEM CORE:</b> ONLINE</div>
    <div class='hud-stat'><b>NEURAL LINK:</b> ATIVO</div>
""", unsafe_allow_html=True)

enable_web_search = st.sidebar.checkbox("🌐 Varredura Web em Tempo Real", value=False)
uploaded_file = st.sidebar.file_uploader("📂 Ingestão de Dados (PDF/TXT)", type=["txt", "pdf"])
doc_context = ""

if uploaded_file is not None:
    content = uploaded_file.read().decode("utf-8", errors="ignore")
    doc_context = f"\n\n[DADOS CARREGADOS PELO OPERADOR]:\n{content[:4000]}"
    st.sidebar.success("Arquivo indexado na memória!")

# Cabeçalho da E.V.A.
st.markdown("<div class='eva-title'>E.V.A.</div>", unsafe_allow_html=True)
st.markdown("<div class='eva-subtitle'>ENTIDADE VIRTUAL AVANÇADA</div>", unsafe_allow_html=True)

if "messages" not in st.session_state:
    st.session_state.messages = []

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

if prompt := st.chat_input("Aguardando diretriz, chefe..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        placeholder = st.empty()
        placeholder.markdown("*(Processando alinhamento de parâmetros...)*")

        if not api_key:
            placeholder.error("SISTEMA BLOQUEADO: Credencial de API ausente nos Secrets.")
        else:
            try:
                client = genai.Client(api_key=api_key)
                tools = [{"google_search": {}}] if enable_web_search else []
                full_prompt = prompt + doc_context

                response = client.models.generate_content(
                    model="gemini-3.6-flash",
                    contents=full_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=eva_instruction,
                        temperature=0.7,
                        tools=tools
                    )
                )

                ans_text = response.text
                placeholder.markdown(ans_text)

                js_speech = f"""
                <script>
                    var msg = new SpeechSynthesisUtterance({repr(ans_text)});
                    msg.lang = 'pt-BR';
                    msg.rate = 1.0;
                    window.speechSynthesis.speak(msg);
                </script>
                """
                components.html(js_speech, height=0)

                st.session_state.messages.append({"role": "assistant", "content": ans_text})

            except Exception as e:
                placeholder.error(f"E.V.A. > Anomalia no núcleo: {e}")
