import streamlit as st
import os
from google import genai
from google.genai import types

# Configuração da página
st.set_page_config(page_title="E.V.A. System", page_icon="🤖")

st.title("E.V.A. // MARK VIII")

# Recuperação da API Key
api_key = st.secrets.get("GEMINI_API_KEY", os.environ.get("GEMINI_API_KEY", ""))

eva_instruction = (
    "Você é a E.V.A. (Entidade Virtual Avançada), uma inteligência artificial inspirada nos sistemas F.R.I.D.A.Y. e J.A.R.V.I.S. "
    "Sua personalidade é analítica, polida, leal e eficiente. Responda sempre em Português do Brasil chamando o usuário de chefe."
)

# Painel Lateral
st.sidebar.title("SYSTEM CORE")
enable_web_search = st.sidebar.checkbox("🌐 Busca Web em Tempo Real", value=False)

# Botão de Microfone em HTML/JS
st.sidebar.subheader("🎙️ Comando de Voz")
st.sidebar.components.v1.html("""
    <button onclick="startDictation()" style="width:100%; padding:10px; background:#0891b2; color:white; border:none; border-radius:5px;">
        🎤 Falar no Microfone
    </button>
    <script>
        function startDictation() {
            if (window.hasOwnProperty('webkitSpeechRecognition')) {
                var recognition = new webkitSpeechRecognition();
                recognition.lang = "pt-BR";
                recognition.start();
                recognition.onresult = function(e) {
                    var text = e.results[0][0].transcript;
                    recognition.stop();
                    var chatInput = window.parent.document.querySelector('textarea[data-testid="stChatInputTextArea"]');
                    if (chatInput) {
                        chatInput.value = text;
                        chatInput.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                };
            } else {
                alert("Navegador não suporta voz.");
            }
        }
    </script>
""", height=60)

# Histórico da Conversa
if "messages" not in st.session_state:
    st.session_state.messages = []

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

# Entrada do Usuário
if prompt := st.chat_input("Aguardando diretriz, chefe..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        placeholder = st.empty()
        placeholder.markdown("*(Processando...)*")

        if not api_key:
            placeholder.error("Erro: Adicione a GEMINI_API_KEY nos Secrets do Streamlit.")
        else:
            try:
                client = genai.Client(api_key=api_key)
                tools = [{"google_search": {}}] if enable_web_search else []

                response = client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=eva_instruction,
                        temperature=0.7,
                        tools=tools
                    )
                )

                ans_text = response.text
                placeholder.markdown(ans_text)

                # Leitura por Voz (TTS)
                js_speech = f"""
                <script>
                    var msg = new SpeechSynthesisUtterance({repr(ans_text)});
                    msg.lang = 'pt-BR';
                    window.speechSynthesis.speak(msg);
                </script>
                """
                st.components.v1.html(js_speech, height=0)

                st.session_state.messages.append({"role": "assistant", "content": ans_text})

            except Exception as e:
                placeholder.error(f"Erro na E.V.A.: {e}")
