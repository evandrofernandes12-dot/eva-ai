import streamlit as st
import streamlit.components.v1 as components
import os
from google import genai
from google.genai import types

# Configuração da página
st.set_page_config(
    page_title="E.V.A. Protocol",
    page_icon="⚡",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ESTILO VISUAL HUD HOLOGRÁFICO
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;800;900&family=Rajdhani:wght@500;600;700&display=swap');

    /* Fundo Tecnológico com Arc Reactor centralizado */
    .stApp {
        background: radial-gradient(circle at 50% 50%, rgba(0, 242, 255, 0.12) 0%, rgba(2, 8, 20, 0.98) 70%), #010409 !important;
        color: #00f2ff !important;
        font-family: 'Rajdhani', sans-serif !important;
    }

    /* Desenho do Reator no Fundo */
    .stApp::before {
        content: "";
        position: fixed;
        top: 50%;
        left: 55%;
        transform: translate(-50%, -50%);
        width: 480px;
        height: 480px;
        border: 2px solid rgba(0, 242, 255, 0.15);
        border-radius: 50%;
        box-shadow: 0 0 50px rgba(0, 242, 255, 0.1), inset 0 0 30px rgba(0, 242, 255, 0.1);
        pointer-events: none;
        z-index: 0;
    }

    /* Barra Lateral Tática */
    [data-testid="stSidebar"] {
        background: rgba(3, 12, 28, 0.9) !important;
        backdrop-filter: blur(15px) !important;
        border-right: 2px solid rgba(0, 242, 255, 0.4) !important;
        box-shadow: 5px 0 25px rgba(0, 242, 255, 0.15);
    }

    /* Cabeçalho Personalizado da E.V.A. */
    .eva-title {
        font-family: 'Orbitron', sans-serif;
        color: #00f2ff;
        font-size: 2.5rem;
        font-weight: 900;
        letter-spacing: 6px;
        text-shadow: 0 0 20px #00f2ff, 0 0 40px rgba(0, 242, 255, 0.5);
        margin-bottom: 0px;
    }

    .eva-subtitle {
        font-family: 'Rajdhani', sans-serif;
        color: #f59e0b;
        font-size: 1.1rem;
        font-weight: 700;
        letter-spacing: 3px;
        text-transform: uppercase;
        margin-bottom: 25px;
    }

    /* Mensagens Estilo Vidro Holográfico */
    .stChatMessage {
        background: rgba(4, 20, 45, 0.75) !important;
        backdrop-filter: blur(10px) !important;
        border: 1px solid rgba(0, 242, 255, 0.4) !important;
        border-left: 4px solid #00f2ff !important;
        border-radius: 6px !important;
        box-shadow: 0 0 20px rgba(0, 242, 255, 0.1) !important;
        margin-bottom: 12px !important;
    }

    /* Campo de Entrada de Texto */
    .stTextInput > div > div > input {
        background-color: rgba(2, 12, 30, 0.95) !important;
        color: #00f2ff !important;
        border: 1.5px solid #00f2ff !important;
        border-radius: 4px !important;
        font-family: 'Orbitron', sans-serif !important;
        box-shadow: 0 0 15px rgba(0, 242, 255, 0.3) !important;
    }

    /* Caixas Módulo Tático na Sidebar */
    .hud-stat {
        background: rgba(0, 242, 255, 0.05);
        border: 1px solid rgba(0, 242, 255, 0.3);
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

# Sidebar
st.sidebar.markdown("<div class='eva-title' style='font-size: 1.8rem;'>E.V.A.</div>", unsafe_allow_html=True)
st.sidebar.markdown("<div class='eva-subtitle' style='font-size: 0.8rem;'>ENTIDADE VIRTUAL AVANÇADA</div>", unsafe_allow_html=True)

st.sidebar.markdown("""
    <div class='hud-stat'><b>CORE SYSTEM:</b> ONLINE</div>
    <div class='hud-stat'><b>NEURAL LINK:</b> ATIVO</div>
""", unsafe_allow_html=True)

enable_web_search = st.sidebar.checkbox("🌐 Varredura Web em Tempo Real", value=False)
uploaded_file = st.sidebar.file_uploader("📂 Ingestão de Dados (PDF/TXT)", type=["txt", "pdf"])
doc_context = ""

if uploaded_file is not None:
    content = uploaded_file.read().decode("utf-8", errors="ignore")
    doc_context = f"\n\n[DADOS CARREGADOS PELO OPERADOR]:\n{content[:4000]}"
    st.sidebar.success("Arquivo indexado na memória!")

# Painel Central Superior
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

                # Fala em Áudio Nv. Navegador
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
