class_name RacerStats
extends Resource
## Atributos de um piloto. Cada piloto é um arquivo .tres em res://resources/racers/.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Estilo procedural do kart: barrel, plank, trike, armored, pinkcar, crate, mail, teacup, vintage, broom
@export var kart_style: String = "barrel"
@export_group("Desempenho")
@export var max_speed: float = 28.0      # m/s
@export var acceleration: float = 16.0   # m/s²
@export var handling: float = 2.2        # rad/s de giro máximo
@export var drift_boost: float = 1.0     # multiplicador do mini-turbo
@export var weight: float = 1.0          # peso (colisões)
@export_group("Visual")
@export var body_color: Color = Color.WHITE
@export var accent_color: Color = Color.WHITE
@export_group("IA")
@export var ai_skill: float = 0.9        # fator de velocidade quando controlado pela IA
