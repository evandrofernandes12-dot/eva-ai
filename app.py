import streamlit as st
from google import genai
from google.genai import types

st.set_page_config(page_title="E.V.A. System", page_icon="🌐", layout="wide")

# Estilização HUD Futurista
st.markdown("""
    <style>
    .stApp { background-color: #020617; color: #e2e8f0; }
    [data-testid="stSidebar"] { background-color: #0f172a; border-right: 1px solid #22d3ee; }
    .stTextInput > div > div > input { background-color: #1e293b; color: #22d3ee; border: 1px solid #0891b2; }
    .stChatMessage { background-color: rgba(30, 41, 59, 0.6); border-radius: 10px; border-left: 3px solid #22d3ee; margin-bottom: 10px; }
    h1, h2, h3 { font-family: 'Orbitron', sans-serif; color: #22d3ee; }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&display=swap" rel="stylesheet">
    """, unsafe_allow_html=True)

# Chave de API
API_KEY = st.secrets.get("GEMINI_API_KEY", "AQ.Ab8RN6JabUtejjHkG-tzAMD9JATlu57JyTeZYJdsIZ_agigDAQ")
client = genai.Client(api_key=API_KEY)

eva_instruction = (
    "Você é a E.V.A. (Entidade Virtual Avançada), uma inteligência artificial analítica, "
    "altamente eficiente, calma, leal e polida, com um toque sutil de ironia fina e humor seco quando necessário. "
    "Você trata o usuário com respeito profissional e camaradagem, respondendo sempre em Português do Brasil. "
    "Use termos tecnológicos ou simule varreduras de sistemas ocasionalmente."
)

st.sidebar.title("🌐 E.V.A. Core")
st.sidebar.success("Núcleo: Ativo")
st.sidebar.info("Conexão: Estável")

# Upload de Documentos
st.sidebar.subheader("📄 Base de Conhecimento")
uploaded_file = st.sidebar.file_uploader("Enviar documento (PDF/TXT)", type=["pdf", "txt"])
doc_context = ""

if uploaded_file is not None:
    content = uploaded_file.read().decode("utf-8", errors="ignore")
    doc_context = f"\n\n[CONTEXTO DO DOCUMENTO CARREGADO]:\n{content[:4000]}"
    st.sidebar.success("Documento indexado!")

enable_web_search = st.sidebar.checkbox("Ativar Busca Web em Tempo Real", value=False)

if "messages" not in st.session_state:
    st.session_state.messages = []

st.title("E.V.A. - Painel de Controle")

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

if prompt := st.chat_input("Diga algo para a E.V.A., chefe..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        placeholder = st.empty()
        placeholder.markdown("*(Analisando parâmetros...)*")

        tools = [{"google_search": {}}] if enable_web_search else []
        full_prompt = prompt + doc_context

        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=full_prompt,
                config=types.GenerateContentConfig(
                    system_instruction=eva_instruction,
                    temperature=0.7,
                    tools=tools
                )
            )
            ans_text = response.text
            placeholder.markdown(ans_text)

            # Leitura de Voz em HTML5
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
            placeholder.error(f"E.V.A. > Anomalia detectada: {e}")
