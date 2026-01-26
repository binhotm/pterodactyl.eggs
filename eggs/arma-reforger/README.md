# Arma Reforger - Pterodactyl Egg

Egg otimizado para Arma Reforger Dedicated Server no Pterodactyl Panel.

## 🎯 Fluxo de Instalação e Execução

### **Fase 1: Instalação** (Container: `pterodactyl-arma-reforger:latest` ou `cm2network/steamcmd:root`)

1. ✅ **Verificar dependências** - jq para validação JSON (instalado no Docker customizado)
2. ✅ **Configurar credenciais Steam** - Anonymous ou autenticado
3. ✅ **Criar diretórios** - profile/, tmp/
4. ✅ **Download via SteamCMD** - App ID 1874900 (Arma Reforger)
5. ✅ **Gerar config.json** - Template com placeholders
6. ✅ **Substituir variáveis** - sed replacement de todos os placeholders
7. ✅ **Validar JSON** - jq valida a configuração antes de prosseguir
8. ✅ **Fix permissions** - chown para usuário steam

**Resultado**: Server instalado + config.json validado e pronto

### **Fase 2: Execução** (Container: `cm2network/steamcmd:latest`)

1. ✅ **Converter booleans** - sed converte `"true"` → `true` no JSON
2. ✅ **Iniciar servidor** - `./ArmaReforgerServer -config config.json -profile profile ...`

**Startup command**:
```bash
sed -i 's/"true"/true/g; s/"false"/false/g' config.json; ./ArmaReforgerServer -config ./config.json -profile ./profile -listScenarios -logStats $(({{LOG_INTERVAL}}*1000)) -maxFPS {{MAX_FPS}} -rpl-timeout-ms 30000
```

## 📦 Docker Image Customizada

**Arquivo**: `../docker/arma-reforger/Dockerfile`

**Benefícios**:
- jq pré-instalado (validação JSON)
- curl, ca-certificates (download de mods)
- lib32gcc-s1, lib32stdc++6 (compatibilidade 32-bit)
- iputils-ping (diagnóstico de rede)

**Build**:
```bash
cd docker/arma-reforger
docker build -t pterodactyl-arma-reforger:latest .
```

## 🔧 Desenvolvimento

### Modificar Installation Script

1. Editar `installation-script.sh` (formato legível)
2. Sincronizar com o JSON:
   ```bash
   python sync-script-to-json.py
   ```
3. Validar:
   ```bash
   python -c "import json; json.load(open('egg-pterodactyl-arma-reforger.json'))"
   ```

### Adicionar Novas Variáveis

Ver instruções em `.github/copilot-instructions.md`

## ❌ Arquivos NÃO Utilizados

- **`docker/arma-reforger/entrypoint.sh`**: Não é usado pelo Pterodactyl (o egg JSON controla o entrypoint)

## 📝 Notas Importantes

- ✅ Pterodactyl Panel é a **única fonte de verdade** para configurações
- ✅ config.json é **regenerado** a cada instalação (idempotência)
- ✅ Validação jq **previne crash loops** por JSON inválido
- ✅ Booleans são strings nas env vars, convertidos no startup
