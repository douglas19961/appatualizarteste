unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  System.IOUtils, UnitGitHubUpdater;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    edtOwner: TEdit;
    Label2: TLabel;
    edtRepo: TEdit;
    Label3: TLabel;
    edtCurrentVersion: TEdit;
    btnCheckUpdates: TButton;
    btnDownload: TButton;
    Panel2: TPanel;
    Label4: TLabel;
    lblLatestVersion: TLabel;
    Label5: TLabel;
    lblReleaseName: TLabel;
    Label6: TLabel;
    lblPublishedDate: TLabel;
    memoReleaseNotes: TMemo;
    Label7: TLabel;
    ProgressBar1: TProgressBar;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCheckUpdatesClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
  private
    FUpdater: TGitHubUpdater;
    FLatestRelease: TGitHubRelease;
    procedure UpdateUI;
    procedure EnableControls(const AEnabled: Boolean);
    function FormatFileSize(const ASize: Int64): string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Configurações padrão - você pode alterar conforme necessário
  edtOwner.Text := 'douglas19961';
  edtRepo.Text := 'appatualizarteste';
  edtCurrentVersion.Text := '1.0.0';
  
  EnableControls(True);
  btnDownload.Enabled := False;
  lblStatus.Caption := 'Pronto para verificar atualizações';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(FUpdater) then
    FUpdater.Free;
end;

procedure TForm1.EnableControls(const AEnabled: Boolean);
begin
  edtOwner.Enabled := AEnabled;
  edtRepo.Enabled := AEnabled;
  edtCurrentVersion.Enabled := AEnabled;
  btnCheckUpdates.Enabled := AEnabled;
end;

procedure TForm1.UpdateUI;
var
  FileInfo: string;
  I: Integer;
begin
  if FLatestRelease.TagName <> '' then
  begin
    lblLatestVersion.Caption := FLatestRelease.TagName;
    lblReleaseName.Caption := FLatestRelease.Name;
    lblPublishedDate.Caption := FLatestRelease.PublishedAt;
    memoReleaseNotes.Text := FLatestRelease.Body;
    
    // Mostrar informações dos arquivos anexados
    if Length(FLatestRelease.Assets) > 0 then
    begin
      FileInfo := 'Arquivos disponíveis:'#13#10;
      for I := 0 to Length(FLatestRelease.Assets) - 1 do
      begin
        FileInfo := FileInfo + Format('  • %s (%s)', 
          [FLatestRelease.Assets[I].Name, FormatFileSize(FLatestRelease.Assets[I].Size)]);
        if FLatestRelease.Assets[I].SHA256 <> '' then
          FileInfo := FileInfo + Format(' - SHA256: %s', [FLatestRelease.Assets[I].SHA256]);
        FileInfo := FileInfo + #13#10;
      end;
      // Adicionar informações dos arquivos nas notas se não estiver vazio
      if memoReleaseNotes.Text <> '' then
        memoReleaseNotes.Text := memoReleaseNotes.Text + #13#10#13#10 + FileInfo
      else
        memoReleaseNotes.Text := FileInfo;
    end;
    
    btnDownload.Enabled := (FLatestRelease.DownloadUrl <> '');
  end
  else
  begin
    lblLatestVersion.Caption := 'N/A';
    lblReleaseName.Caption := 'N/A';
    lblPublishedDate.Caption := 'N/A';
    memoReleaseNotes.Text := '';
    btnDownload.Enabled := False;
  end;
end;

function TForm1.FormatFileSize(const ASize: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
begin
  if ASize < KB then
    Result := Format('%d bytes', [ASize])
  else if ASize < MB then
    Result := Format('%.2f KB', [ASize / KB])
  else if ASize < GB then
    Result := Format('%.2f MB', [ASize / MB])
  else
    Result := Format('%.2f GB', [ASize / GB]);
end;

procedure TForm1.btnCheckUpdatesClick(Sender: TObject);
var
  HasUpdate: Boolean;
begin
  if Assigned(FUpdater) then
    FUpdater.Free;
  
  EnableControls(False);
  btnDownload.Enabled := False;
  ProgressBar1.Style := pbstMarquee;
  lblStatus.Caption := 'Verificando atualizações...';
  Application.ProcessMessages;
  
  try
    FUpdater := TGitHubUpdater.Create(
      edtOwner.Text,
      edtRepo.Text,
      edtCurrentVersion.Text
    );
    
    try
      FLatestRelease := FUpdater.GetLatestRelease;
    except
      on E: Exception do
      begin
        lblStatus.Caption := 'Erro ao buscar release';
        ShowMessage(Format('❌ ERRO AO BUSCAR RELEASE'#13#10#13#10'%s'#13#10#13#10 +
          'Possíveis causas:'#13#10 +
          '1. Repositório não existe ou está privado'#13#10 +
          '2. Não há releases publicadas (apenas drafts)'#13#10 +
          '3. Problema de conexão com a internet'#13#10 +
          '4. Limite de requisições da API do GitHub excedido'#13#10#13#10 +
          'Verifique: https://github.com/%s/%s/releases',
          [E.Message, edtOwner.Text, edtRepo.Text]));
        FLatestRelease.TagName := '';
        UpdateUI;
        Exit;
      end;
    end;
    
    if FLatestRelease.TagName <> '' then
    begin
      HasUpdate := FUpdater.CheckForUpdates;
      
      if HasUpdate then
      begin
        lblStatus.Caption := Format('Nova versão disponível: %s', [FLatestRelease.TagName]);
        ShowMessage(Format('✅ NOVA VERSÃO DISPONÍVEL!'#13#10#13#10 +
          'Versão atual: %s'#13#10 +
          'Versão mais recente: %s'#13#10#13#10 +
          'Clique em "Baixar Atualização" para baixar.',
          [edtCurrentVersion.Text, FLatestRelease.TagName]));
      end
      else
      begin
        lblStatus.Caption := Format('Release encontrada: %s', [FLatestRelease.TagName]);
        ShowMessage(Format('Release encontrada: %s'#13#10#13#10 +
          'Versão atual: %s'#13#10 +
          'Release disponível: %s'#13#10#13#10 +
          'Você pode baixar mesmo assim se desejar.',
          [FLatestRelease.TagName, edtCurrentVersion.Text, FLatestRelease.TagName]));
      end;
    end
    else
    begin
      lblStatus.Caption := 'Nenhuma release encontrada';
      ShowMessage(Format('⚠️ NENHUMA RELEASE ENCONTRADA'#13#10#13#10 +
        'O repositório "%s/%s" não possui releases publicadas ainda.'#13#10#13#10 +
        '📋 COMO CRIAR UMA RELEASE:'#13#10 +
        '1. Acesse: https://github.com/%s/%s/releases'#13#10 +
        '2. Clique em "Create a new release"'#13#10 +
        '3. Escolha uma tag (ex: v1.0.0 ou 1.0.0)'#13#10 +
        '4. Adicione um título e descrição'#13#10 +
        '5. (Opcional) Anexe arquivos para download'#13#10 +
        '6. Clique em "Publish release"'#13#10#13#10 +
        'Depois disso, tente verificar atualizações novamente!',
        [edtOwner.Text, edtRepo.Text, edtOwner.Text, edtRepo.Text]));
    end;
    
    UpdateUI;
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Erro: ' + E.Message;
      ShowMessage('Erro ao verificar atualizações: ' + E.Message);
      FLatestRelease.TagName := '';
      UpdateUI;
    end;
  end;
  
  ProgressBar1.Style := pbstNormal;
  ProgressBar1.Position := 0;
  EnableControls(True);
end;

procedure TForm1.btnDownloadClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  DownloadPath: string;
  FileName: string;
  I: Integer;
  CalculatedHash: string;
  HashInfo: string;
  ExpectedHash: string;
begin
  // Verificar se há arquivos disponíveis
  if Length(FLatestRelease.Assets) = 0 then
  begin
    if FLatestRelease.DownloadUrl = '' then
    begin
      ShowMessage('Nenhum arquivo disponível para download.');
      Exit;
    end;
    // Usar URL antiga se não houver assets
    FileName := ExtractFileName(FLatestRelease.DownloadUrl);
    if FileName = '' then
      FileName := 'download.zip';
  end
  else
  begin
    // Usar o primeiro arquivo ou permitir escolher se houver múltiplos
    if Length(FLatestRelease.Assets) = 1 then
      FileName := FLatestRelease.Assets[0].Name
    else
    begin
      // Se houver múltiplos arquivos, usar o primeiro por padrão
      // (você pode melhorar isso depois para permitir escolher)
      FileName := FLatestRelease.Assets[0].Name;
    end;
  end;
  
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.FileName := FileName;
    SaveDialog.Filter := 'Todos os arquivos|*.*';
    SaveDialog.DefaultExt := ExtractFileExt(FileName);
    
    if SaveDialog.Execute then
    begin
      DownloadPath := SaveDialog.FileName;
      EnableControls(False);
      btnDownload.Enabled := False;
      ProgressBar1.Style := pbstMarquee;
      
      // Usar URL do primeiro asset se disponível, senão usar DownloadUrl antigo
      if Length(FLatestRelease.Assets) > 0 then
      begin
        lblStatus.Caption := Format('Baixando %s...', [FLatestRelease.Assets[0].Name]);
        FLatestRelease.DownloadUrl := FLatestRelease.Assets[0].DownloadUrl;
      end
      else
        lblStatus.Caption := Format('Baixando %s...', [FileName]);
      
      Application.ProcessMessages;
      
      try
        if Assigned(FUpdater) and FUpdater.DownloadRelease(FLatestRelease, DownloadPath) then
        begin
          // Calcular hash SHA256 do arquivo baixado
          CalculatedHash := FUpdater.CalculateFileSHA256(DownloadPath);
          
          // Verificar hash se disponível
          ExpectedHash := '';
          if Length(FLatestRelease.Assets) > 0 then
            ExpectedHash := FLatestRelease.Assets[0].SHA256;
          
          HashInfo := '';
          if CalculatedHash <> '' then
          begin
            HashInfo := Format(#13#10'SHA256: %s', [CalculatedHash]);
            
            // Verificar se corresponde ao hash esperado
            if (ExpectedHash <> '') and FUpdater.VerifyFileSHA256(DownloadPath, ExpectedHash) then
              HashInfo := HashInfo + ' ✅ (Verificado)'
            else if ExpectedHash <> '' then
              HashInfo := HashInfo + Format(' ⚠️ (Esperado: %s)', [ExpectedHash]);
          end;
          
          lblStatus.Caption := Format('Download concluído: %s', [FileName]);
          ShowMessage(Format('✅ DOWNLOAD CONCLUÍDO!'#13#10#13#10 +
            'Arquivo: %s'#13#10 +
            'Salvo em: %s'#13#10 +
            'Tamanho: %s%s',
            [FileName, DownloadPath, 
             FormatFileSize(TFile.GetSize(DownloadPath)), HashInfo]));
        end
        else
        begin
          lblStatus.Caption := 'Erro ao baixar atualização';
          ShowMessage(Format('❌ Erro ao baixar a atualização.'#13#10#13#10 +
            'Verifique:'#13#10 +
            '1. Sua conexão com a internet'#13#10 +
            '2. Se a URL está acessível'#13#10 +
            '3. Se há espaço em disco'#13#10#13#10 +
            'URL: %s', [FLatestRelease.DownloadUrl]));
        end;
      except
        on E: Exception do
        begin
          lblStatus.Caption := 'Erro: ' + E.Message;
          ShowMessage(Format('❌ Erro ao baixar atualização:'#13#10'%s'#13#10#13#10'URL: %s',
            [E.Message, FLatestRelease.DownloadUrl]));
        end;
      end;
      
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Position := 0;
      EnableControls(True);
      if FLatestRelease.TagName <> '' then
        btnDownload.Enabled := True;
    end;
  finally
    SaveDialog.Free;
  end;
end;

end.
