from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "finance-dashboard-backend"
    env: str = "local"
    api_prefix: str = "/api"
    database_url: str = "sqlite:///./backend/data/app.db"
    static_dir: str = "."
    access_token: str = ""

    local_cors_origins: str = "http://localhost:8000,http://127.0.0.1:8000,http://localhost:5173,http://127.0.0.1:5173"
    deployed_cors_origins: str = ""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @property
    def is_local(self) -> bool:
        return self.env.lower() == "local"

    @property
    def sqlite_path(self) -> str:
        if self.database_url.startswith("sqlite:///"):
            return self.database_url.replace("sqlite:///", "", 1)
        return ""

    @property
    def cors_origins(self) -> list[str]:
        raw = f"{self.local_cors_origins},{self.deployed_cors_origins}".strip(",")
        return [o.strip() for o in raw.split(",") if o.strip()]

    def validate_access_boundary(self) -> None:
        if self.is_local:
            return
        if not self.deployed_cors_origins.strip() or not self.access_token.strip():
            raise RuntimeError("DEPLOYED_CORS_ORIGINS and ACCESS_TOKEN are required when ENV is not local")


settings = Settings()
settings.validate_access_boundary()
