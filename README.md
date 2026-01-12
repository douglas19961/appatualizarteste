# Sistema de Atualização via GitHub - Delphi

Este projeto implementa um sistema completo de verificação e download de atualizações do GitHub para aplicações Delphi.

## Funcionalidades

- ✅ Verificação de atualizações via API do GitHub
- ✅ Comparação de versões
- ✅ Download de releases
- ✅ Interface visual intuitiva
- ✅ Componente reutilizável (`TGitHubUpdater`)

## Como Usar

### 1. Configuração Básica

1. Abra o projeto no Delphi
2. Execute a aplicação
3. Configure os campos:
   - **Proprietário (Owner)**: Nome de usuário ou organização do GitHub (ex: `microsoft`)
   - **Nome do Repositório**: Nome do repositório (ex: `vscode`)
   - **Versão Atual**: Versão atual da sua aplicação (ex: `1.0.0`)

### 2. Verificar Atualizações

1. Clique em "Verificar Atualizações"
2. O sistema irá:
   - Conectar à API do GitHub
   - Buscar a última release disponível
   - Comparar com a versão atual
   - Exibir informações da release (se houver atualização)

### 3. Baixar Atualização

1. Após verificar atualizações, se houver uma nova versão disponível
2. Clique em "Baixar Atualização"
3. Escolha o local onde deseja salvar o arquivo
4. O download será iniciado automaticamente

## Integração em Outros Projetos

Para usar o `TGitHubUpdater` em outros projetos:

### Passo 1: Adicione a Unit

Copie o arquivo `UnitGitHubUpdater.pas` para seu projeto.

### Passo 2: Use no seu código

```pascal
uses
  UnitGitHubUpdater;

var
  Updater: TGitHubUpdater;
  Release: TGitHubRelease;
begin
  // Criar instância
  Updater := TGitHubUpdater.Create('usuario', 'repositorio', '1.0.0');
  try
    // Verificar atualizações
    if Updater.CheckForUpdates then
    begin
      // Obter informações da release
      Release := Updater.GetLatestRelease;
      ShowMessage('Nova versão: ' + Release.TagName);
      
      // Baixar atualização
      if Updater.DownloadRelease(Release, 'C:\Downloads\update.zip') then
        ShowMessage('Download concluído!');
    end;
  finally
    Updater.Free;
  end;
end;
```

## Formato de Versão

O sistema suporta versões no formato:
- `1.0.0`
- `v1.0.0` (o prefixo 'v' é removido automaticamente)
- `2.1.5`
- etc.

## Requisitos

- Delphi 10.1 Berlin ou superior (para suporte a `System.Net.HttpClient`)
- Conexão com a internet
- Repositório GitHub com releases publicadas

## Estrutura de Releases no GitHub

Para que o sistema funcione corretamente, seu repositório GitHub deve ter:

1. **Releases publicadas**: Vá em Settings > Releases > Create a new release
2. **Tags de versão**: Use tags como `v1.0.0` ou `1.0.0`
3. **Assets**: Adicione arquivos para download (ex: executáveis, instaladores)

## Exemplo de Uso Programático

```pascal
procedure VerificarAtualizacoesAutomaticas;
var
  Updater: TGitHubUpdater;
begin
  Updater := TGitHubUpdater.Create('meu-usuario', 'meu-app', '1.0.0');
  try
    if Updater.CheckForUpdates then
    begin
      // Notificar usuário sobre atualização disponível
      if MessageDlg('Nova versão disponível! Deseja baixar?', 
         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        // Baixar automaticamente
        Updater.DownloadRelease(
          Updater.GetLatestRelease, 
          ExtractFilePath(Application.ExeName) + 'update.zip'
        );
      end;
    end;
  finally
    Updater.Free;
  end;
end;
```

## Notas

- O sistema busca a última release **não-prerelease** por padrão
- Se não houver releases não-prerelease, pode retornar vazio
- O download usa o primeiro asset disponível na release
- Certifique-se de que o repositório é público ou que você tem as credenciais necessárias

## Suporte

Para dúvidas ou problemas, verifique:
- Se o repositório existe e é acessível
- Se há releases publicadas
- Se a conexão com a internet está funcionando
- Se o formato da versão está correto
