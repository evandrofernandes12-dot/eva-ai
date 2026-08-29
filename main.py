import streamlit as st
import os
from google import genai
from google.genai import types

# Configuração da página estilo HUD Stark
st.set_page_config(
    page_title="F.R.I.D.A.Y. // E.V.A. Protocol",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ESTILO VISUAL HUD (Sexta-Feira / J.A.R.V.I.S.)
st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;800;900&family=Rajdhani:wght@500;600;700&display=swap');

    .stApp {
        background: radial-gradient(circle at 50% 30%, #030a16 0%, #010409 100%) !important;
        color: #38bdf8 !important;
        font-family: 'Rajdhani', sans-serif !important;
    }

    [data-testid="stSidebar"] {
        background: rgba(8, 15, 30, 0.85) !important;
        backdrop-filter: blur(12px) !important;
        border-right: 1px solid rgba(0, 242, 255, 0.25) !important;
    }

    .stark-header {
        font-family: 'Orbitron', sans-serif;
        color: #00f2ff;
        font-size: 2.2rem;
        font-weight: 900;
        letter-spacing: 4px;
        text-shadow: 0 0 15px rgba(0, 242, 255, 0.6);
    }

    .stark-sub {
        font-family: 'Rajdhani', sans-serif;
        color: #f59e0b;
        font-size: 0.95rem;
        letter-spacing: 2px;
        font-weight: 700;
        margin-bottom: 20px;
    }

    .stChatMessage {
        background: rgba(10, 20, 38, 0.6) !important;
        backdrop-filter: blur(8px) !important;
        border: 1px solid rgba(0, 242, 255, 0.3) !important;
        border-radius: 10px !important;
        margin-bottom: 12px !important;
    }

    .stTextInput > div > div > input {
        background-color: rgba(6, 11, 25, 0.9) !important;
        color: #00f2ff !important;
        border: 1px solid #00f2ff !important;
        border-radius: 8px !important;
    }

    .hud-box {
        background: rgba(0, 242, 255, 0.03);
        border-left: 3px solid #00f2ff;
        padding: 10px;
        border-radius: 4px;
        margin-bottom: 10px;
        font-family: 'Orbitron', sans-serif;
        font-size: 0.8rem;
    }
    </style>
""", unsafe_allow_html=True)

api_key = st.secrets.get("GEMINI_API_KEY", os.environ.get("GEMINI_API_KEY", ""))

eva_instruction = (
    "Você é a E.V.A. (Entidade Virtual Avançada), uma inteligência artificial inspirada nos sistemas F.R.I.D.A.Y. e J.A.R.V.I.S. "
    "Sua personalidade é analítica, polida, leal e eficiente, com um toque leve de ironia fina e elegância. "
    "Responda sempre em Português do Brasil com precisão cirúrgica e termos operacionais, chamando o usuário de chefe."
)

st.sidebar.markdown("<h2 style='font-family: Orbitron; color: #00f2ff;'>SYSTEM CORE</h2>", unsafe_allow_html=True)
st.sidebar.markdown("<div class='hud-box'><b>NÚCLEO CENTRAL:</b> ATIVO</div>", unsafe_allow_html=True)

enable_web_search = st.sidebar.checkbox("🌐 Varredura Web em Tempo Real", value=False)
uploaded_file = st.sidebar.file_uploader("📂 Ingestão de Dados (PDF/TXT)", type=["txt", "pdf"])
doc_context = ""

if uploaded_file is not None:
    content = uploaded_file.read().decode("utf-8", errors="ignore")
    doc_context = f"\n\n[DADOS CARREGADOS PELO OPERADOR]:\n{content[:4000]}"
    st.sidebar.success("Arquivo indexado na memória!")

st.markdown("<div class='stark-header'>E.V.A. // MARK VIII</div>", unsafe_allow_html=True)
st.markdown("<div class='stark-sub'>TACTICAL INTERFACE & REASONING SYSTEM</div>", unsafe_allow_html=True)

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
        placeholder.markdown("*(Executando varredura e alinhamento de parâmetros...)*")

        if not api_key:
            placeholder.error("SISTEMA BLOQUEADO: Credencial de API não localizada nos Secrets.")
        else:
            try:
                client = genai.Client(api_key=api_key)
                tools = [{"google_search": {}}] if enable_web_search else []
                full_prompt = prompt + doc_context

                response = client.models.generate_content(
                    model="gemini-1.5-flash",
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
                st.components.v1.html(js_speech, height=0)

                st.session_state.messages.append({"role": "assistant", "content": ans_text})

            except Exception as e:
                placeholder.error(f"E.V.A. > Anomalia no núcleo de comunicação: {e}")
