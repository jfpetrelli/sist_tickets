from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import jwt, JWTError
from passlib.context import CryptContext
from datetime import datetime, timedelta
from settings import settings
from crud.user import get_user_by_email
from sqlalchemy.orm import Session
from database.database import get_db
import logging

# Configurar logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/jwt", tags=["jwt"])

ALGORITHM = settings.algorithm
ACCESS_TOKEN_DURATION_MINUTES = settings.access_token_duration_minutes

crypt = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2 = OAuth2PasswordBearer(tokenUrl="jwt/login")

def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=ALGORITHM)
    return encoded_jwt

@router.post("/login")
async def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    try:
        logger.debug(f"Intentando login para usuario: {form.username}")
        user = get_user_by_email(form.username, db)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El correo no es correcto"
            )
            
        logger.debug("Verificando contraseña...")
        # Verificar la contraseña
        if not crypt.verify(form.password, user.password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La contraseña no es correcta"
            )

        logger.debug("Contraseña verificada correctamente")
        # Generar el token JWT
        access_token = create_access_token(
            data={"sub": user.email},
            expires_delta=timedelta(minutes=ACCESS_TOKEN_DURATION_MINUTES)
        )

        return {
            "access_token": access_token,
            "token_type": "bearer"
        }
    except Exception as e:
        logger.error(f"Error en el proceso de login: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error en el proceso de login: {str(e)}"
        ) 