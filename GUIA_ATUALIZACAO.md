# 📦 Guia Completo: Como Subir Executável e Atualizar seu Programa

## 🎯 Processo Completo Passo a Passo

### **PASSO 1: Preparar o Executável**

1. **Compile seu projeto no Delphi**
   - Vá em: `Project` → `Build Project1`
   - Ou pressione `Shift + F9`
   - O executável será gerado em: `Win32\Debug\Project1.exe` (ou `Release`)

2. **Teste o executável localmente**
   - Certifique-se de que funciona corretamente
   - Teste todas as funcionalidades importantes

---

### **PASSO 2: Criar/Atualizar Release no GitHub**

#### **Opção A: Criar Nova Release (Primeira Vez)**

1. **Acesse seu repositório no GitHub**
   - Vá para: https://github.com/douglas19961/appatualizarteste

2. **Vá para Releases**
   - Clique na aba **"Releases"** (lado direito da página)
   - OU acesse: https://github.com/douglas19961/appatualizarteste/releases

3. **Criar Nova Release**
   - Clique em **"Create a new release"** ou **"Draft a new release"**

4. **Preencher os Campos:**

   **Tag de Versão:**
   - Escolha uma tag seguindo o padrão: `v1.0.0` ou `1.0.0`
   - Exemplos: `v1.0.0`, `v1.0.1`, `v1.1.0`, `v2.0.0`
   - ⚠️ **IMPORTANTE**: Use sempre o mesmo formato (com ou sem "v")

   **Título da Release:**
   - Exemplo: "Versão 1.0.0 - Primeira Release"
   - Ou: "v1.0.0"

   **Descrição (Opcional):**
   ```
   Versão 1.0.0
   
   Funcionalidades:
   - Sistema de atualização automática
   - Verificação de novas versões
   - Download automático
   ```

5. **Anexar o Executável:**
   - Na seção **"Attach binaries by dropping them here or selecting them"**
   - **Arraste o arquivo `Project1.exe`** para essa área
   - OU clique e selecione o arquivo
   - ⚠️ **IMPORTANTE**: O arquivo DEVE estar anexado aqui, não apenas como link!

6. **Publicar:**
   - Clique em **"Publish release"**
   - Pronto! A release está publicada

#### **Opção B: Atualizar Release Existente (Nova Versão)**

1. **Acesse a página de Releases**
   - https://github.com/douglas19961/appatualizarteste/releases

2. **Edite a Release Atual OU Crie Nova:**
   
   **Para Nova Versão (Recomendado):**
   - Clique em **"Create a new release"**
   - Use uma tag maior: `v1.0.1` (se a anterior era `v1.0.0`)
   - Anexe o novo executável
   - Publique

   **Para Editar Release Existente:**
   - Clique no ícone de **lápis (editar)** na release
   - Anexe o novo executável
   - Atualize a descrição se necessário
   - Salve

---

### **PASSO 3: Configurar Versão no Código**

No seu programa Delphi, configure a versão atual:

1. **No formulário (Unit1.pas)**, o campo "Versão Atual" deve corresponder à tag da release:
   - Se a release é `v1.0.0`, coloque `1.0.0` no campo
   - Se a release é `v1.0.1`, coloque `1.0.1` no campo

2. **Ou configure programaticamente:**
```pascal
// No FormCreate ou onde preferir
edtCurrentVersion.Text := '1.0.0'; // Atualize conforme a versão atual
```

---

### **PASSO 4: Testar a Atualização**

1. **Execute sua aplicação**
2. **Clique em "Verificar Atualizações"**
3. **O sistema deve:**
   - Conectar ao GitHub
   - Buscar a última release
   - Comparar versões
   - Mostrar se há atualização disponível

4. **Se houver atualização:**
   - Clique em "Baixar Atualização"
   - Escolha onde salvar
   - O download começará automaticamente

---

## 🔄 Fluxo de Trabalho Recomendado

### **Ciclo de Desenvolvimento:**

```
1. Desenvolver → 2. Compilar → 3. Testar → 4. Criar Release → 5. Usuários Atualizam
     ↓                ↓            ↓              ↓                    ↓
  Código novo    Project1.exe   Funciona?    GitHub Release    Download automático
```

### **Exemplo Prático:**

**Versão 1.0.0 (Primeira Release):**
- Compile: `Project1.exe`
- Crie release: Tag `v1.0.0`
- Anexe: `Project1.exe`
- Publique

**Versão 1.0.1 (Correção de Bug):**
- Corrija o bug no código
- Compile: `Project1.exe` (novo)
- Crie release: Tag `v1.0.1`
- Anexe: `Project1.exe` (novo)
- Publique
- Usuários com v1.0.0 verão a atualização disponível!

**Versão 1.1.0 (Nova Funcionalidade):**
- Adicione nova funcionalidade
- Compile: `Project1.exe` (novo)
- Crie release: Tag `v1.1.0`
- Anexe: `Project1.exe` (novo)
- Publique
- Usuários com v1.0.x verão a atualização disponível!

---

## 📋 Checklist Antes de Publicar

- [ ] Executável compilado e testado
- [ ] Versão atualizada no código (se necessário)
- [ ] Tag de versão escolhida (ex: `v1.0.1`)
- [ ] Executável anexado como asset na release
- [ ] Descrição da release preenchida (opcional)
- [ ] Release publicada no GitHub
- [ ] Testado a verificação de atualização na aplicação

---

## 💡 Dicas Importantes

### **1. Nomenclatura de Versões (Semantic Versioning):**
- **MAIOR.MENOR.PATCH** (ex: 1.0.0)
- **MAIOR** (1.x.x): Mudanças incompatíveis
- **MENOR** (x.1.x): Novas funcionalidades compatíveis
- **PATCH** (x.x.1): Correções de bugs

### **2. Tags de Versão:**
- Use sempre o mesmo formato: **sempre com "v"** OU **sempre sem "v"**
- Exemplos consistentes:
  - ✅ `v1.0.0`, `v1.0.1`, `v1.1.0`
  - ✅ `1.0.0`, `1.0.1`, `1.1.0`
  - ❌ Não misture: `v1.0.0` e `1.0.1` (inconsistente)

### **3. Executável vs ZIP:**
- **Executável direto (.exe)**: Melhor para usuários finais
- **ZIP com executável**: Útil se precisar incluir outros arquivos
- Ambos funcionam! O sistema detecta ambos

### **4. Múltiplos Arquivos:**
- Você pode anexar múltiplos arquivos na mesma release
- O sistema prioriza executáveis e ZIPs sobre source code
- O primeiro arquivo de aplicação será usado para download

---

## 🚀 Exemplo de Uso no Código

Se quiser verificar atualizações automaticamente ao iniciar:

```pascal
procedure TForm1.FormShow(Sender: TObject);
begin
  // Verificar atualizações automaticamente ao abrir
  btnCheckUpdatesClick(Self);
end;
```

Ou criar uma função separada:

```pascal
procedure VerificarAtualizacoesAutomaticas;
var
  Updater: TGitHubUpdater;
begin
  Updater := TGitHubUpdater.Create('douglas19961', 'appatualizarteste', '1.0.0');
  try
    if Updater.CheckForUpdates then
    begin
      var Release := Updater.GetLatestRelease;
      if MessageDlg(
        Format('Nova versão disponível: %s'#13#10'Deseja baixar agora?', 
          [Release.TagName]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        // Baixar automaticamente
        var SavePath := ExtractFilePath(Application.ExeName) + Release.Assets[0].Name;
        if Updater.DownloadRelease(Release, SavePath) then
        begin
          ShowMessage('Download concluído! Reinicie o programa para aplicar.');
        end;
      end;
    end;
  finally
    Updater.Free;
  end;
end;
```

---

## ❓ Problemas Comuns e Soluções

### **Problema: "Nenhuma release encontrada"**
- ✅ Verifique se a release está publicada (não draft)
- ✅ Verifique se o repositório está correto
- ✅ Verifique se há conexão com internet

### **Problema: "Arquivo não encontrado"**
- ✅ Certifique-se de que o executável está anexado como asset
- ✅ Não apenas como link na descrição
- ✅ Verifique se o arquivo foi realmente enviado

### **Problema: "Versão não atualiza"**
- ✅ Verifique se a tag da release é maior que a versão atual
- ✅ Use formato numérico: `1.0.1` > `1.0.0`
- ✅ Verifique se está usando o mesmo formato (com/sem "v")

---

## 📞 Suporte

Se tiver dúvidas:
1. Verifique este guia
2. Teste com uma release de teste primeiro
3. Verifique os logs de erro na aplicação

**Boa sorte com suas atualizações! 🚀**
