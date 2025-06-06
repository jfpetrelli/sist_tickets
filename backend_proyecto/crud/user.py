from sqlalchemy.orm import Session
from models.user import Usuario
from schemas.user import UsuarioCreate
from passlib.context import CryptContext

crypt = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_user(db: Session, user_id: int):
    return db.query(Usuario).filter(Usuario.id_personal == user_id).first()

def get_user_by_email(email: str, db: Session):
    return db.query(Usuario).filter(Usuario.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Usuario).offset(skip).limit(limit).all()

def create_user(db: Session, user: UsuarioCreate):
    hashed_password = crypt.hash(user.password)
    db_user = Usuario(
        id_sucursal=user.id_sucursal,
        id_tipo=user.id_tipo,
        nombre=user.nombre,
        telefono_movil=user.telefono_movil,
        email=user.email,
        fecha_ingreso=user.fecha_ingreso,
        fecha_egreso=user.fecha_egreso,
        password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user 