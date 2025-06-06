from pydantic_settings import BaseSettings
from datetime import datetime
from typing import Optional

class Settings(BaseSettings):
    sqlite_url: str = "sqlite:///database.db"
    secret_key: str = "f25c25a441c2c51d7c1b6c85d1b7c3f5a0f2b3e4d5c6b7a8"  # Clave secreta para JWT
    algorithm: str = "HS256"  # Algoritmo para JWT
    access_token_duration_minutes: int = 1440  # Duración del token en minutos (24 horas)

settings = Settings() 