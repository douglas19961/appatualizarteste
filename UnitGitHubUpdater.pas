unit UnitGitHubUpdater;

interface

uses
  System.Classes, System.SysUtils, System.Math, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.NetConsts, System.Generics.Collections, System.IOUtils;

type
  TGitHubAsset = record
    Name: string;
    DownloadUrl: string;
    Size: Int64;
  end;

  TGitHubRelease = record
    TagName: string;
    Name: string;
    Body: string;
    PublishedAt: string;
    DownloadUrl: string;
    IsPrerelease: Boolean;
    Assets: TArray<TGitHubAsset>;
  end;

  TGitHubUpdater = class
  private
    FRepositoryOwner: string;
    FRepositoryName: string;
    FCurrentVersion: string;
    FHttpClient: THTTPClient;
    function GetReleasesURL: string;
    function GetLatestReleaseURL: string;
    function ParseRelease(const AJSON: TJSONObject): TGitHubRelease;
    function IsNumericVersion(const AVersion: string): Boolean;
  public
    constructor Create(const AOwner, ARepo, ACurrentVersion: string);
    destructor Destroy; override;
    
    function CheckForUpdates: Boolean;
    function GetLatestRelease: TGitHubRelease;
    function DownloadRelease(const ARelease: TGitHubRelease; const ADestinationPath: string): Boolean;
    function CompareVersions(const AVersion1, AVersion2: string): Integer;
    
    property RepositoryOwner: string read FRepositoryOwner write FRepositoryOwner;
    property RepositoryName: string read FRepositoryName write FRepositoryName;
    property CurrentVersion: string read FCurrentVersion write FCurrentVersion;
  end;

implementation

{ TGitHubUpdater }

constructor TGitHubUpdater.Create(const AOwner, ARepo, ACurrentVersion: string);
begin
  inherited Create;
  FRepositoryOwner := AOwner;
  FRepositoryName := ARepo;
  FCurrentVersion := ACurrentVersion;
  FHttpClient := THTTPClient.Create;
  FHttpClient.UserAgent := 'Delphi-GitHub-Updater/1.0';
  FHttpClient.ResponseTimeout := 10000; // 10 segundos
  FHttpClient.ConnectionTimeout := 5000; // 5 segundos
end;

destructor TGitHubUpdater.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function TGitHubUpdater.GetReleasesURL: string;
begin
  Result := Format('https://api.github.com/repos/%s/%s/releases', 
    [FRepositoryOwner, FRepositoryName]);
end;

function TGitHubUpdater.GetLatestReleaseURL: string;
begin
  Result := Format('https://api.github.com/repos/%s/%s/releases/latest', 
    [FRepositoryOwner, FRepositoryName]);
end;

function TGitHubUpdater.ParseRelease(const AJSON: TJSONObject): TGitHubRelease;
var
  Assets: TJSONArray;
  Asset: TJSONObject;
  I: Integer;
  AssetList: TList<TGitHubAsset>;
  GitHubAsset: TGitHubAsset;
begin
  Result.TagName := '';
  Result.Name := '';
  Result.Body := '';
  Result.PublishedAt := '';
  Result.DownloadUrl := '';
  Result.IsPrerelease := False;
  SetLength(Result.Assets, 0);
  
  if Assigned(AJSON) then
  begin
    Result.TagName := AJSON.GetValue('tag_name', '');
    Result.Name := AJSON.GetValue('name', '');
    Result.Body := AJSON.GetValue('body', '');
    Result.PublishedAt := AJSON.GetValue('published_at', '');
    Result.IsPrerelease := AJSON.GetValue('prerelease', False);
    
    // Buscar todos os assets (arquivos anexados)
    if AJSON.TryGetValue('assets', Assets) and (Assets.Count > 0) then
    begin
      AssetList := TList<TGitHubAsset>.Create;
      try
        for I := 0 to Assets.Count - 1 do
        begin
          Asset := Assets.Items[I] as TJSONObject;
          if Assigned(Asset) then
          begin
            GitHubAsset.Name := Asset.GetValue('name', '');
            GitHubAsset.DownloadUrl := Asset.GetValue('browser_download_url', '');
            GitHubAsset.Size := Asset.GetValue('size', 0);
            AssetList.Add(GitHubAsset);
          end;
        end;
        
        // Converter para array
        SetLength(Result.Assets, AssetList.Count);
        for I := 0 to AssetList.Count - 1 do
          Result.Assets[I] := AssetList[I];
        
        // Usar o primeiro asset como padrão para DownloadUrl (compatibilidade)
        if AssetList.Count > 0 then
          Result.DownloadUrl := AssetList[0].DownloadUrl;
      finally
        AssetList.Free;
      end;
    end;
  end;
end;

function TGitHubUpdater.GetLatestRelease: TGitHubRelease;
var
  Response: IHTTPResponse;
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
  ErrorMsg: string;
begin
  Result.TagName := '';
  Result.Name := '';
  Result.Body := '';
  Result.PublishedAt := '';
  Result.DownloadUrl := '';
  Result.IsPrerelease := False;
  SetLength(Result.Assets, 0);
  
  try
    Response := FHttpClient.Get(GetLatestReleaseURL);
    
    case Response.StatusCode of
      200:
      begin
        JSONValue := TJSONObject.ParseJSONValue(Response.ContentAsString);
        try
          if Assigned(JSONValue) and (JSONValue is TJSONObject) then
          begin
            JSONObject := JSONValue as TJSONObject;
            Result := ParseRelease(JSONObject);
          end;
        finally
          JSONValue.Free;
        end;
      end;
      404:
      begin
        // Repositório não encontrado ou não possui releases - retorna vazio sem erroo
        // O erro será tratado na interface
        Result.TagName := '';
        Result.Name := '';
        Result.Body := '';
        Result.PublishedAt := '';
        Result.DownloadUrl := '';
        Result.IsPrerelease := False;
      end;
      403:
      begin
        ErrorMsg := 'Acesso negado. O repositório pode ser privado ou você excedeu o limite de requisições da API do GitHub.';
        raise Exception.Create(ErrorMsg);
      end;
    else
      begin
        ErrorMsg := Format('Erro HTTP %d: %s'#13#10'URL: %s', 
          [Response.StatusCode, Response.StatusText, GetLatestReleaseURL]);
        raise Exception.Create(ErrorMsg);
      end;
    end;
  except
    on E: Exception do
    begin
      // Verifica se é erro de conexão pela mensagem
      if (Pos('connection', LowerCase(E.Message)) > 0) or
         (Pos('timeout', LowerCase(E.Message)) > 0) or
         (Pos('network', LowerCase(E.Message)) > 0) or
         (Pos('resolve', LowerCase(E.Message)) > 0) then
      begin
        ErrorMsg := Format('Erro de conexão: %s'#13#10'Verifique sua conexão com a internet.'#13#10'URL: %s', 
          [E.Message, GetLatestReleaseURL]);
        raise Exception.Create(ErrorMsg);
      end
      else
      begin
        ErrorMsg := Format('Erro ao acessar GitHub: %s'#13#10'URL: %s', 
          [E.Message, GetLatestReleaseURL]);
        raise Exception.Create(ErrorMsg);
      end;
    end;
  end;
end;

function TGitHubUpdater.CheckForUpdates: Boolean;
var
  LatestRelease: TGitHubRelease;
  LatestVersion, CurrentVersion: string;
begin
  Result := False;
  try
    LatestRelease := GetLatestRelease;
    if LatestRelease.TagName <> '' then
    begin
      LatestVersion := StringReplace(LatestRelease.TagName, 'v', '', [rfReplaceAll, rfIgnoreCase]);
      CurrentVersion := StringReplace(FCurrentVersion, 'v', '', [rfReplaceAll, rfIgnoreCase]);
      
      // Se ambas as versões são numéricas, compara normalmente
      if IsNumericVersion(CurrentVersion) and IsNumericVersion(LatestVersion) then
      begin
        Result := CompareVersions(CurrentVersion, LatestVersion) > 0;
      end
      else
      begin
        // Se não são numéricas, considera como atualização se forem diferentes
        Result := (CurrentVersion <> LatestVersion);
      end;
    end;
  except
    Result := False;
  end;
end;

function TGitHubUpdater.IsNumericVersion(const AVersion: string): Boolean;
var
  Parts: TArray<string>;
  I: Integer;
  Val: Integer;
begin
  Result := False;
  if AVersion = '' then
    Exit;
  
  Parts := AVersion.Split(['.']);
  if Length(Parts) = 0 then
    Exit;
  
  // Verifica se todas as partes são numéricas
  Result := True;
  for I := 0 to Length(Parts) - 1 do
  begin
    if not TryStrToInt(Parts[I], Val) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

function TGitHubUpdater.CompareVersions(const AVersion1, AVersion2: string): Integer;
var
  Parts1, Parts2: TArray<string>;
  I, Val1, Val2: Integer;
  MaxLen: Integer;
begin
  // Remove 'v' prefix se existir
  Parts1 := StringReplace(AVersion1, 'v', '', [rfReplaceAll, rfIgnoreCase]).Split(['.']);
  Parts2 := StringReplace(AVersion2, 'v', '', [rfReplaceAll, rfIgnoreCase]).Split(['.']);
  
  MaxLen := Max(Length(Parts1), Length(Parts2));
  
  for I := 0 to MaxLen - 1 do
  begin
    Val1 := 0;
    Val2 := 0;
    
    if I < Length(Parts1) then
      TryStrToInt(Parts1[I], Val1);
    if I < Length(Parts2) then
      TryStrToInt(Parts2[I], Val2);
    
    if Val1 < Val2 then
      Exit(-1)
    else if Val1 > Val2 then
      Exit(1);
  end;
  
  Result := 0;
end;

function TGitHubUpdater.DownloadRelease(const ARelease: TGitHubRelease; 
  const ADestinationPath: string): Boolean;
var
  Response: IHTTPResponse;
  FileStream: TFileStream;
  DownloadURL: string;
begin
  Result := False;
  
  // Usar URL do primeiro asset se disponível, senão usar DownloadUrl
  if Length(ARelease.Assets) > 0 then
    DownloadURL := ARelease.Assets[0].DownloadUrl
  else
    DownloadURL := ARelease.DownloadUrl;
  
  if DownloadURL = '' then
    Exit;
  
  try
    FileStream := TFileStream.Create(ADestinationPath, fmCreate);
    try
      Response := FHttpClient.Get(DownloadURL, FileStream);
      Result := Response.StatusCode = 200;
    finally
      FileStream.Free;
    end;
    
    // Se falhar, tenta deletar o arquivo parcial
    if not Result then
    begin
      try
        if TFile.Exists(ADestinationPath) then
          TFile.Delete(ADestinationPath);
      except
        // Ignora erros ao deletar
      end;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      // Tenta deletar arquivo parcial em caso de erro
      try
        if TFile.Exists(ADestinationPath) then
          TFile.Delete(ADestinationPath);
      except
        // Ignora
      end;
      raise Exception.Create(Format('Erro ao baixar: %s'#13#10'URL: %s', [E.Message, DownloadURL]));
    end;
  end;
end;

end.
